-- =========================================================
-- HELPER SCRIPT (PNB + DROP CMD + FEATURE SCRIPT UI)
-- =========================================================

-- ================== CONFIG DEFAULT ==================
local itemid = 5640
local delayPerBlock = 2
local delayAuto = 50
local xmag = 11
local ymag = 110
-- ================================================

-- ================== STATE ==================
local pnbEnabled = false
local paused = false
local localNetID = GetLocal().netID
-- ===========================================

-- ================== UTIL ==================
function ontext(txt)
    SendVariant({v1 = "OnTextOverlay", v2 = txt})
end
-- ===========================================

-- ================== INIT PNB ==================
function initPNB()
    SendPacket(2,
        "action|dialog_return\n" ..
        "dialog_name|itemsucker_block\n" ..
        "tilex|"..xmag.."|\n" ..
        "tiley|"..ymag.."|\n" ..
        "buttonClicked|getplantationdevice\n"
    )

    Sleep(400)

    SendPacket(2,
        "action|dialog_return\n" ..
        "dialog_name|cheats\n" ..
        "itemid|"..itemid.."\n" ..
        "slot|6\n" ..
        "checkbox_cheat_autofish|1\n" ..
        "checkbox_cheat_antibounce|1\n" ..
        "checkbox_cheat_speed|0\n" ..
        "checkbox_cheat_double_jump|1\n" ..
        "checkbox_cheat_jump|0\n" ..
        "checkbox_cheat_heat_resist|1\n" ..
        "checkbox_cheat_strong_punch|0\n" ..
        "checkbox_cheat_long_punch|1\n" ..
        "checkbox_cheat_long_build|0\n" ..
        "checkbox_cheat_autocollect|1\n" ..
        "checkbox_cheat_fastpull|0\n" ..
        "checkbox_cheat_fastdrop|0\n" ..
        "checkbox_cheat_fasttrash|0\n" ..
        "chat|\n"
    )

    EditToggle("Antilag", true)
    EditToggle("No Particle", true)
    EditToggle("Player", true)
end
-- =================================================

-- ================== BASIC PNB ==================
function place(x, y)
    SendPacketRaw(false, {
        type = 3,
        value = itemid,
        x = x * 32,
        y = y * 32,
        px = x,
        py = y
    })
end

function PlayerDetected()
    for _, p in pairs(getPlayerList()) do
        if p.netID ~= localNetID then
            return true
        end
    end
    return false
end
-- =================================================

-- ================== PNB THREAD ==================
runThread(function()
    while true do
        if not pnbEnabled then
            Sleep(200)
        else
            if PlayerDetected() then
                if not paused then
                    paused = true
                    LogToConsole("`4[PAUSE] Player detected, PNB paused")
                end
                Sleep(500)
            else
                if paused then
                    paused = false
                    LogToConsole("`2[RESUME] World empty, PNB resumed")
                    Sleep(1500)
                end

                Sleep(delayPerBlock)
                place(84,4)
                Sleep(delayPerBlock)
                place(85,4)
                Sleep(delayPerBlock)
                place(86,4)
                Sleep(delayPerBlock)
                place(87,4)
                Sleep(delayPerBlock)
                place(88,4)
                Sleep(delayPerBlock)
                place(89,4)

                Sleep(delayAuto)
            end
        end
    end
end)
-- =================================================

-- ================== DROP FUNCTIONS ==================
function drops(id, amount)
    SendPacket(2,
        "action|dialog_return\n" ..
        "dialog_name|drop_item\n" ..
        "itemID|"..id.."|\n" ..
        "count|"..amount.."\n"
    )
end

function clock(idNeed, idConvert, amount)
    for _, inv in pairs(GetInventory()) do
        if inv.id == idNeed and inv.amount < amount then
            SendPacketRaw(false, {type = 10, value = idConvert})
        end
    end
end
-- ====================================================

-- ================== UI : HELPER MENU ==================
function openHelperMenu()
    local status = pnbEnabled and "`2ENABLED" or "`4DISABLED"
    local dialog = [[
add_label_with_icon|big|`7Helper Menu|left|9472|
add_spacer|small|
add_label_with_icon|small|`0Hai! ]]..localPlayer().name..[[|right|14016|
add_label_with_icon|small|`0UserID : `3]]..GetLocal().userID..[[|left|12436|
add_label_with_icon|small|`0Current World `9]]..GetWorldName()..[[|left|3802|
add_label_with_icon|small|`0You're in Pos : `6[]]..(GetLocal().posX//32)..[[,]]..(GetLocal().posY//32)..[[]|left|12854|
add_spacer|small|
add_smalltext|PNB Status : ]]..status..[[|
add_spacer|small|
text_scaling_string|helperui|
add_button_with_icon|togglepnb|`7PNB Helper|staticGreyFrame|9472||
add_button_with_icon|featurescript|`7Feature Script|staticGreyFrame|9472||
add_button_with_icon|configpnb|`7PNB Config|staticGreyFrame|32||
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|
end_dialog|helpermenu|Close||
]]
    SendVariant({v1="OnDialogRequest", v2=dialog})
end
-- ====================================================

-- ================== UI : FEATURE SCRIPT ==================
function openFeatureScript()
    local dialog = [[
add_label_with_icon|big|`7Feature Script|left|9472|
add_spacer|small|
add_smalltext|`8Daftar command dan fungsi script:|

add_spacer|small|
add_label_with_icon|small|`cPNB Command|left|18|
add_smalltext|`9/startpnb      `7Start Auto PNB|
add_smalltext|`9/stoppnb      `7Stop Auto PNB|
add_smalltext|`9/config      `7Stop Auto PNB|

add_spacer|small|
add_label_with_icon|small|`9World Lock|left|242|
add_smalltext|`9/w [amount]      `7Drop World Lock|
add_smalltext|`9/wx2 [amount]   `7Drop World Lock x2|
add_smalltext|`9/wx3 [amount]   `7Drop World Lock x3|
add_smalltext|`9/wall            `7Drop All World Lock|

add_spacer|small|
add_label_with_icon|small|`3Diamond Lock|left|1796|
add_smalltext|`3/d [amount]      `7Drop Diamond Lock|
add_smalltext|`3/dx2 [amount]   `7Drop Diamond Lock x2|
add_smalltext|`3/dx3 [amount]   `7Drop Diamond Lock x3|
add_smalltext|`3/dall            `7Drop All Diamond Lock|

add_spacer|small|
add_label_with_icon|small|`1Blue Gem Lock|left|7188|
add_smalltext|`1/b [amount]      `7Drop Blue Gem Lock|
add_smalltext|`1/bx2 [amount]   `7Drop Blue Gem Lock x2|
add_smalltext|`1/bx3 [amount]   `7Drop Blue Gem Lock x3|
add_smalltext|`1/ball            `7Drop All Blue Gem Lock|

add_spacer|small|
add_smalltext|`8Contoh: `9/w 10 `7→ Drop 10 World Lock|
end_dialog|featurescript|Close||
]]
    SendVariant({v1="OnDialogRequest", v2=dialog})
end
-- ====================================================

-- ================== UI : CONFIG PNB ==================
function openPNBConfig()
    local dialog = [[
add_label_with_icon|big|`7PNB Configuration|left|9472|
add_spacer|small|
add_text_input|itemid|Item ID|]]..itemid..[[|5|
add_text_input|delaypb|Delay Per Block|]]..delayPerBlock..[[|5|
add_text_input|delayauto|Delay Auto|]]..delayAuto..[[|5|
add_text_input|xmag|Mag X|]]..xmag..[[|5|
add_text_input|ymag|Mag Y|]]..ymag..[[|5|
add_spacer|small|
add_button|savepnb|Save Config|
end_dialog|pnbconfig|Cancel||
]]
    SendVariant({v1="OnDialogRequest", v2=dialog})
end
-- ====================================================

-- ================== HOOK ==================
function hook(type, str)

    -- open helper
    if str:find("/helper") then
        openHelperMenu()
        return true
    end

    -- toggle pnb
    if str:find("buttonClicked|togglepnb") then
        pnbEnabled = not pnbEnabled
        paused = false
        if pnbEnabled then
            initPNB()
            ontext("`2PNB Enabled")
        else
            ontext("`4PNB Disabled")
        end
        openHelperMenu()
        return true
    end

    -- open feature script
    if str:find("buttonClicked|featurescript") then
        openFeatureScript()
        return true
    end

    -- open config
    if str:find("buttonClicked|configpnb") then
        openPNBConfig()
        return true
    end

    -- save config
    if str:find("buttonClicked|savepnb") then
        itemid = tonumber(str:match("itemid|(%d+)")) or itemid
        delayPerBlock = tonumber(str:match("delaypb|(%d+)")) or delayPerBlock
        delayAuto = tonumber(str:match("delayauto|(%d+)")) or delayAuto
        xmag = tonumber(str:match("xmag|(%d+)")) or xmag
        ymag = tonumber(str:match("ymag|(%d+)")) or ymag
        ontext("`2PNB Config Saved")
        openHelperMenu()
        return true
    end
	
	-- command start/stop 
	if str:find("/startpnb") then 
		if not pnbEnabled then 
			pnbEnabled = true 
				paused = false 
					initPNB() 
				ontext("2PNB Started") 
			end 
		return true 
	end 
	
	if str:find("/stoppnb") then 
		pnbEnabled = false 
			ontext("4PNB Stopped") 
		return true 
	end
	
	if str:find("/config") then
		openPNBConfig()
		return true
	end
	
    -- ================= DROP COMMANDS =================
    if str:find("/w (%d+)") then
        local a = tonumber(str:match("/w (%d+)"))
        clock(242,1796,a); drops(242,a); return true
    end
    if str:find("/wx2 (%d+)") then
        local a = tonumber(str:match("/wx2 (%d+)"))*2
        clock(242,1796,a); drops(242,a); return true
    end
    if str:find("/wx3 (%d+)") then
        local a = tonumber(str:match("/wx3 (%d+)"))*3
        clock(242,1796,a); drops(242,a); return true
    end
    if str:find("/wall") then
        for _,i in pairs(GetInventory()) do if i.id==242 then drops(242,i.amount) end end
        return true
    end

    if str:find("/d (%d+)") then
        local a = tonumber(str:match("/d (%d+)"))
        clock(1796,242,a); clock(1796,7188,a); drops(1796,a); return true
    end
    if str:find("/dx2 (%d+)") then
        local a = tonumber(str:match("/dx2 (%d+)"))*2
        clock(1796,242,a); clock(1796,7188,a); drops(1796,a); return true
    end
    if str:find("/dx3 (%d+)") then
        local a = tonumber(str:match("/dx3 (%d+)"))*3
        clock(1796,242,a); clock(1796,7188,a); drops(1796,a); return true
    end
    if str:find("/dall") then
        for _,i in pairs(GetInventory()) do if i.id==1796 then drops(1796,i.amount) end end
        return true
    end

    if str:find("/b (%d+)") then
        local a = tonumber(str:match("/b (%d+)"))
        drops(7188,a); return true
    end
    if str:find("/bx2 (%d+)") then
        local a = tonumber(str:match("/bx2 (%d+)"))*2
        drops(7188,a); return true
    end
    if str:find("/bx3 (%d+)") then
        local a = tonumber(str:match("/bx3 (%d+)"))*3
        drops(7188,a); return true
    end
    if str:find("/ball") then
        for _,i in pairs(GetInventory()) do if i.id==7188 then drops(7188,i.amount) end end
        return true
    end
    -- =================================================

    return false
end

AddHook(hook,"OnSendPacket")
-- =========================================================
