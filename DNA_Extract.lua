-- BOTHAX: DNAGET 3942 + AUTO TAKE 100 + PAUSE WHEN OTHER PLAYERS JOIN
-- GetPlayerList() excludes the local player (per Bothax documentation).
-- No outgoing DNAGET / backpack actions while other players are in the world.

local CFG = {
    itemID = 3942,
    threshold = 100,
    takeCount = 100,
    dnagetX = 44,
    dnagetY = 45,
    dnagetDelayMs = 20,
    selectWaitMs = 200,
    backpackWaitMs = 300,
    takeVerifyMs = 200,
    retryCooldownMs = 200,
    successCooldownMs = 200,
    hideBackpackDialog = true,
    pausePollMs = 100
}

local takeBusy = false
local waitingForBackpack = false
local slotVersion = 0
local selectedSlot = nil
local lastPresenceState = nil

local function log(msg)
    LogToConsole('[DNAGET 3942] ' .. tostring(msg))
end

local function showPresenceState(state, info)
    if lastPresenceState == state then return end
    lastPresenceState = state
    if state == 'RUNNING' then
        log('RESUME: world kosong, DNAGET + Auto Take aktif kembali')
    elseif state == 'PLAYERS' then
        log('PAUSE: ada ' .. tostring(info) .. ' player lain di world')
    else
        log('PAUSE: data world/player belum siap, menunggu')
    end
end

-- Called every time before an automated action; fail closed if data is unavailable.
-- Also catches players who were already in the world before the script started.
local function worldIsEmpty()
    local okWorld, world = pcall(GetWorld)
    local okLocal, selfPlayer = pcall(GetLocal)
    local okList, players = pcall(GetPlayerList)
    if not okWorld or not world or not world.name or
       not okLocal or not selfPlayer or
       not okList or not players then
        showPresenceState('UNKNOWN')
        return false
    end

    local otherCount = 0
    local okScan = pcall(function()
        for _, player in pairs(players) do
            -- GetPlayerList normally excludes yourself; the check below is defensive.
            if not player or player.netid == nil or
               selfPlayer.netid == nil or
               player.netid ~= selfPlayer.netid then
                otherCount = otherCount + 1
            end
        end
    end)
    if not okScan then
        showPresenceState('UNKNOWN')
        return false
    end
    if otherCount > 0 then
        showPresenceState('PLAYERS', otherCount)
        return false
    end
    showPresenceState('RUNNING')
    return true
end

local function sendOnlyWhenAlone(packet)
    if not worldIsEmpty() then return false end
    SendPacket(2, packet)
    return true
end

-- Delay that aborts when someone enters, avoiding continued backpack actions.
local function sleepWhileAlone(milliseconds)
    local elapsed = 0
    while elapsed < milliseconds do
        if not worldIsEmpty() then return false end
        local step = math.min(100, milliseconds - elapsed)
        Sleep(step)
        elapsed = elapsed + step
    end
    return worldIsEmpty()
end

local function inventoryCount()
    local ok, inv = pcall(GetInventory)
    if not ok or not inv then return nil end
    local count = 0
    local iterOK = pcall(function()
        for _, item in pairs(inv) do
            if tonumber(item.id) == CFG.itemID then
                count = count + (tonumber(item.amount) or 0)
            end
        end
    end)
    return iterOK and count or nil
end

-- Parse backpack slot list (preserving the spelling bpSl / bpSL).
local function parseBackpack(dialog)
    if type(dialog) ~= 'string' then return false, nil end
    local sawSlot, best = false, nil
    for line in dialog:gmatch('[^\r\n]+') do
        local button, id, amount = line:match(
            'add_button_with_icon|([^|]+)|.-|frame|(%d+)|(%d+)|'
        )
        local slot = button and button:match('^bpS[lL]_(%d+)$')
        if slot then
            sawSlot = true
            id, amount = tonumber(id), tonumber(amount)
            if id == CFG.itemID and amount >= CFG.takeCount then
                if not best or tonumber(slot) < best.index then
                    best = { index = tonumber(slot), button = button, amount = amount }
                end
            end
        end
    end
    return sawSlot, best
end

pcall(function() RemoveHook('DNAGET3942_Backpack') end)
AddHook('OnVariant', 'DNAGET3942_Backpack', function(var)
    -- Do not automatically process or hide backpack dialogs while paused.
    if not worldIsEmpty() then return false end
    if not var or var[0] ~= 'OnDialogRequest' then return false end
    local dialog = var[1]
    if type(dialog) ~= 'string' then return false end

    local isList, slot = parseBackpack(dialog)
    if waitingForBackpack and isList then
        selectedSlot = slot
        slotVersion = slotVersion + 1
    end

    if CFG.hideBackpackDialog and (
        isList or dialog:find('end_dialog|manoProfile', 1, true)
        or dialog:find('dialog_name|manoProfile', 1, true)
        or dialog:find('storeItemid|', 1, true)
    ) then
        return true
    end
    return false
end)

local function takeFromBackpack()
    if not worldIsEmpty() then return false end
    local player = GetLocal()
    if not player or player.netid == nil then
        log('Tidak bisa buka backpack: netID tidak tersedia')
        return false
    end
    local before = inventoryCount()
    if before == nil or before >= CFG.threshold then return false end

    -- 1. Open Backpack.
    selectedSlot = nil
    waitingForBackpack = true
    local oldVersion = slotVersion
    if not sendOnlyWhenAlone(
        'action|dialog_return\n' ..
        'dialog_name|playerProfile\n' ..
        'netID|' .. tostring(player.netid) .. '|\n' ..
        'flags|9|\n' ..
        'buttonClicked|backpack'
    ) then
        waitingForBackpack = false
        return false
    end

    local elapsed = 0
    while slotVersion == oldVersion and elapsed < CFG.backpackWaitMs do
        if not worldIsEmpty() then
            waitingForBackpack = false
            selectedSlot = nil
            return false
        end
        Sleep(CFG.pausePollMs)
        elapsed = elapsed + CFG.pausePollMs
    end
    waitingForBackpack = false

    local slot = selectedSlot
    if not worldIsEmpty() then return false end
    if slotVersion == oldVersion then
        log('Daftar backpack belum diterima; coba lagi nanti')
        return false
    end
    if not slot then
        log('ID 3942 tidak ditemukan di backpack dengan stok >= 100')
        return false
    end

    -- 2. Select slot.
    if not sendOnlyWhenAlone(
        'action|dialog_return\n' ..
        'dialog_name|manoProfile\n' ..
        'netID|' .. tostring(player.netid) .. '|\n' ..
        'buttonClicked|' .. slot.button
    ) then return false end
    if not sleepWhileAlone(CFG.selectWaitMs) then return false end

    -- 3. Take exactly 100 only if still alone and inventory still low.
    before = inventoryCount()
    if before == nil or before >= CFG.threshold then return false end
    if not sendOnlyWhenAlone(
        'action|dialog_return\n' ..
        'dialog_name|manoProfile\n' ..
        'storeItemid|' .. slot.index .. '|\n' ..
        'remove|1|\n' ..
        'count|' .. CFG.takeCount
    ) then return false end
    log('TAKE 100 dikirim dari ' .. slot.button .. ' (inventory awal=' .. before .. ')')

    elapsed = 0
    while elapsed < CFG.takeVerifyMs do
        if not worldIsEmpty() then return false end
        Sleep(CFG.pausePollMs)
        elapsed = elapsed + CFG.pausePollMs
        local count = inventoryCount()
        if count and count > before then
            log('TAKE berhasil, inventory=' .. count)
            return true
        end
    end
    log('TAKE belum terverifikasi; tunggu cooldown')
    return false
end

-- Auto Take thread: pauses automatically when another player is present.
RunThread(function()
    while true do
        if not worldIsEmpty() then
            Sleep(CFG.pausePollMs)
        else
            local count = inventoryCount()
            if count ~= nil and count < CFG.threshold then
                takeBusy = true
                local ok, result = pcall(takeFromBackpack)
                takeBusy = false
                if not ok then log('TAKE error: ' .. tostring(result)) end
                -- A new player interrupts cooldown; no new packets until empty.
                sleepWhileAlone((ok and result) and CFG.successCooldownMs or CFG.retryCooldownMs)
            else
                Sleep(250)
            end
        end
    end
end)

log('Aktif. Auto-pause jika ada player lain (termasuk yang sudah ada sejak awal).')

-- Original DNAGET loop, kept at 100ms whenever alone and not taking.
while true do
    if not takeBusy then
        sendOnlyWhenAlone('action|dialog_return\n' ..
            'dialog_name|dnaget\n' ..
            'tilex|' .. CFG.dnagetX .. '|\n' ..
            'tiley|' .. CFG.dnagetY .. '|\n' ..
            'item|' .. CFG.itemID .. '|\n\n')
    else
        -- Refresh player presence even while Auto Take is running.
        worldIsEmpty()
    end
    Sleep(CFG.dnagetDelayMs)
end
