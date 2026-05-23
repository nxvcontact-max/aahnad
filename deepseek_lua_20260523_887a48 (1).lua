MachoMenuNotification("S1Dev", "S1Dev Menu\n\nCapsLock to open menu")

local function isResourceRunning(resourceName)
    return GetResourceState(resourceName) == "started"
end

local bp = setmetatable({}, {
    __index = function(_, k)
        local v = _G[k]
        return type(v) == "function" and function(...) return v(...) end or v
    end
})

-- ============================================================
--   FEATURES
-- ============================================================
local noclipActive = false
local noclipSpeed = 7.0
local noclipThread = nil

local godmodeActive = false
local superJumpActive = false
local fastRunActive = false
local invisibleActive = false

-- ============================================================
--   NOCLIP FUNCTION
-- ============================================================
local function StartNoclip()
    if noclipThread then return end
    noclipThread = Citizen.CreateThread(function()
        while noclipActive do
            Citizen.Wait(0)
            local ped = PlayerPedId()
            local inVeh = IsPedInAnyVehicle(ped, false)
            local entity = inVeh and GetVehiclePedIsIn(ped, false) or ped
            
            local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(ped)
            local pitch = GetGameplayCamRelativePitch()
            local rh = heading * 0.01745329
            local rp = pitch * 0.01745329
            local dx = -math.sin(rh) * math.cos(rp)
            local dy = math.cos(rh) * math.cos(rp)
            local dz = math.sin(rp)
            
            local spd = noclipSpeed * 0.05
            if IsControlPressed(0, 21) then spd = spd * 3.0 end
            
            local c = GetEntityCoords(entity)
            local nx, ny, nz = c.x, c.y, c.z
            
            if IsControlPressed(0, 32) then
                nx = nx + dx * spd
                ny = ny + dy * spd
                nz = nz + dz * spd
            end
            if IsControlPressed(0, 33) then
                nx = nx - dx * spd
                ny = ny - dy * spd
                nz = nz - dz * spd
            end
            if IsControlPressed(0, 22) then
                nz = nz + spd
            end
            if IsControlPressed(0, 36) then
                nz = nz - spd
            end
            
            SetEntityCoordsNoOffset(entity, nx, ny, nz, true, true, true)
            SetEntityVelocity(entity, 0.0, 0.0, 0.0)
            SetEntityVisible(entity, false, false)
            SetLocalPlayerVisibleLocally(false)
        end
        noclipThread = nil
    end)
end

local function ToggleNoclip()
    noclipActive = not noclipActive
    
    if noclipActive then
        StartNoclip()
        MachoMenuNotification("S1Dev", "Noclip ~g~ENABLED~w~ (WASD + Space/Ctrl)")
        print("^2[S1Dev]^7 Noclip ENABLED")
    else
        SetEntityVisible(PlayerPedId(), true, false)
        SetLocalPlayerVisibleLocally(true)
        MachoMenuNotification("S1Dev", "Noclip ~r~DISABLED")
        print("^2[S1Dev]^7 Noclip DISABLED")
    end
end

-- ============================================================
--   GODMODE
-- ============================================================
local function ToggleGodmode()
    godmodeActive = not godmodeActive
    local ped = PlayerPedId()
    SetEntityInvincible(ped, godmodeActive)
    SetPlayerInvincible(PlayerId(), godmodeActive)
    
    if godmodeActive then
        MachoMenuNotification("S1Dev", "Godmode ~g~ENABLED")
        print("^2[S1Dev]^7 Godmode ENABLED")
    else
        MachoMenuNotification("S1Dev", "Godmode ~r~DISABLED")
        print("^2[S1Dev]^7 Godmode DISABLED")
    end
end

-- Godmode health thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if godmodeActive then
            SetEntityHealth(PlayerPedId(), 200)
        end
    end
end)

-- ============================================================
--   SUPER JUMP
-- ============================================================
local function ToggleSuperJump()
    superJumpActive = not superJumpActive
    if superJumpActive then
        MachoMenuNotification("S1Dev", "Super Jump ~g~ENABLED")
        print("^2[S1Dev]^7 Super Jump ENABLED")
    else
        MachoMenuNotification("S1Dev", "Super Jump ~r~DISABLED")
        print("^2[S1Dev]^7 Super Jump DISABLED")
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if superJumpActive then
            SetSuperJumpThisFrame(PlayerId())
        end
    end
end)

-- ============================================================
--   FAST RUN
-- ============================================================
local function ToggleFastRun()
    fastRunActive = not fastRunActive
    if fastRunActive then
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
        MachoMenuNotification("S1Dev", "Fast Run ~g~ENABLED")
        print("^2[S1Dev]^7 Fast Run ENABLED")
    else
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        MachoMenuNotification("S1Dev", "Fast Run ~r~DISABLED")
        print("^2[S1Dev]^7 Fast Run DISABLED")
    end
end

-- ============================================================
--   INVISIBLE
-- ============================================================
local function ToggleInvisible()
    invisibleActive = not invisibleActive
    local ped = PlayerPedId()
    SetEntityVisible(ped, not invisibleActive, false)
    SetLocalPlayerVisibleLocally(not invisibleActive)
    
    if invisibleActive then
        MachoMenuNotification("S1Dev", "Invisible ~g~ENABLED")
        print("^2[S1Dev]^7 Invisible ENABLED")
    else
        MachoMenuNotification("S1Dev", "Invisible ~r~DISABLED")
        print("^2[S1Dev]^7 Invisible DISABLED")
    end
end

-- ============================================================
--   REVIVE & HEAL
-- ============================================================
local function ReviveSelf()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, 0.0, true, false)
    Citizen.SetTimeout(200, function()
        SetEntityHealth(PlayerPedId(), 200)
        SetPedArmour(PlayerPedId(), 100)
        ClearPedBloodDamage(PlayerPedId())
        ClearPedTasksImmediately(PlayerPedId())
    end)
    MachoMenuNotification("S1Dev", "~g~Revived!")
    print("^2[S1Dev]^7 Revived")
end

local function HealSelf()
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 100)
    MachoMenuNotification("S1Dev", "~g~Healed!")
    print("^2[S1Dev]^7 Healed")
end

-- ============================================================
--   CRASH NEARBY PLAYER
-- ============================================================
local function CrashNearbyPlayers()
    print("^2[S1Dev]^7 Searching for nearby players...")
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetPlayer = nil
    local targetName = nil
    local closestDist = 150.0
    
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            if DoesEntityExist(ep) then
                local ec = GetEntityCoords(ep)
                local dist = #(myCoords - ec)
                if dist < closestDist then
                    closestDist = dist
                    targetPlayer = player
                    targetName = GetPlayerName(player)
                end
            end
        end
    end
    
    if not targetPlayer then
        MachoMenuNotification("S1Dev", "~r~No players nearby!")
        print("^2[S1Dev]^7 No players nearby")
        return false
    end
    
    MachoMenuNotification("S1Dev", "~r~Crashing~w~ " .. targetName)
    print("^2[S1Dev]^7 Crashing " .. targetName)
    
    local targetPed = GetPlayerPed(targetPlayer)
    local targetCoords = GetEntityCoords(targetPed)
    local modelHash = GetHashKey("player_one")
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end
    
    if HasModelLoaded(modelHash) then
        local myPed = PlayerPedId()
        for i = 1, 250 do
            local angle = math.random() * 2 * math.pi
            local distance = math.random() * 8
            local x = targetCoords.x + (distance * math.cos(angle))
            local y = targetCoords.y + (distance * math.sin(angle))
            local z = targetCoords.z
            
            local hasGround, groundZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
            if hasGround then z = groundZ end
            
            local ped = CreatePed(28, modelHash, x, y, z, math.random(0, 359), true, false)
            if DoesEntityExist(ped) then
                SetEntityAlpha(ped, 0, false)
                SetEntityVisible(ped, false, false)
                FreezeEntityPosition(ped, true)
                SetEntityCollision(ped, false, false)
                SetEntityNoCollisionEntity(ped, myPed, true)
                SetEntityCanBeDamaged(ped, false)
                SetEntityInvincible(ped, true)
            end
            if i % 20 == 0 then Citizen.Wait(50) end
        end
        SetModelAsNoLongerNeeded(modelHash)
        MachoMenuNotification("S1Dev", "~r~Crash executed~w~ on " .. targetName)
        print("^2[S1Dev]^7 Crash executed on " .. targetName)
        return true
    end
    
    return false
end

-- ============================================================
--   UNIVERSAL AC BYPASS
-- ============================================================
local function UniversalACBypass()
    MachoMenuNotification("S1Dev", "Running Universal AC Bypass...")
    print("^2[S1Dev]^7 Starting Universal AC Bypass")
    
    local _origGCRN = GetCurrentResourceName
    rawset(_G, 'GetCurrentResourceName', function() return "monitor" end)
    Citizen.SetTimeout(5000, function()
        rawset(_G, 'GetCurrentResourceName', _origGCRN)
    end)
    
    local allEvents = {
        "fg:kickPlayer", "fg:BanPlayer", "fg:screenshot", "fg:checkClient",
        "fiveguard:ban", "fiveguard:kick", "FiveGuard:Ban", "FiveGuard:Kick",
        "ElectronAC:playerBanned", "ElectronAC:playerWarned", "ElectronAC:playerKicked",
        "electron:playerBanned", "electron:playerKicked", "electronAC:ban",
        "waveshield:ban", "waveshield:kick", "waveshield:warn", "waveshield:detect",
        "txAdmin:events:playerKicked", "txAdmin:events:announcement"
    }
    for _, ev in ipairs(allEvents) do
        AddEventHandler(ev, function() CancelEvent() end)
    end
    
    AddEventHandler("__cfx_nui:fg_screenshot", function() return end)
    AddEventHandler("__cfx_nui:screenshot", function() return end)
    AddEventHandler("__cfx_internal:Screenshot", function() CancelEvent() end)
    AddEventHandler("onClientResourceStop", function(res)
        if res == GetCurrentResourceName() then CancelEvent() end
    end)
    
    MachoMenuNotification("S1Dev", "~g~Universal AC Bypass Applied!")
    print("^2[S1Dev]^7 Universal AC Bypass completed")
end

-- ============================================================
--   MENU SYSTEM (Based on working Storm template)
-- ============================================================
local MenuSize = vec2(480, 360) 
local screenW, screenH = GetActiveScreenResolution()
local MenuStartCoords = vec2(screenW / 2 - MenuSize.x / 2, screenH / 2 - MenuSize.y / 2)
local TabsBarWidth = 120.0
local SectionsPadding = 8  
local MachoPaneGap = 6  
local SectionChildWidth = MenuSize.x - TabsBarWidth
local SectionColumns = 2
local SectionRows = 2
local TwoByTwoSectionWidth = (SectionChildWidth - (SectionsPadding * (SectionColumns + 1))) / SectionColumns
local TwoByTwoSectionHeight = (MenuSize.y - (SectionsPadding * (SectionRows + 1))) / SectionRows

local function GetSectionCoords(col, row, colspan, rowspan)
    colspan = colspan or 1
    rowspan = rowspan or 1
    local startX = TabsBarWidth + (SectionsPadding * col) + (TwoByTwoSectionWidth * (col - 1))
    local startY = (SectionsPadding * row) + (TwoByTwoSectionHeight * (row - 1)) + MachoPaneGap
    local endX = startX + (TwoByTwoSectionWidth * colspan) + (SectionsPadding * (colspan - 1))
    local endY = startY + (TwoByTwoSectionHeight * rowspan) + (SectionsPadding * (rowspan - 1))
    return startX, startY, endX, endY
end

-- Create window
MenuWindow = MachoMenuTabbedWindow('S1Dev', MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y, TabsBarWidth)
MachoMenuSmallText(MenuWindow, "User: " .. (authenticatedUser or "S1Dev User"))
MachoMenuSetAccent(MenuWindow, 30, 144, 255) -- Blue accent
local MenuKeybind = MachoMenuSetKeybind(MenuWindow, 0x14) -- CapsLock

-- ============================================================
--   MAIN TAB
-- ============================================================
local MainTab = MachoMenuAddTab(MenuWindow, 'Main')
local MainSection = MachoMenuGroup(MainTab, 'S1Dev Features', GetSectionCoords(1, 1, 2, 2))

MachoMenuButton(MainSection, 'Noclip [TOGGLE]', function()
    ToggleNoclip()
end)

MachoMenuButton(MainSection, 'Godmode [TOGGLE]', function()
    ToggleGodmode()
end)

MachoMenuButton(MainSection, 'Super Jump [TOGGLE]', function()
    ToggleSuperJump()
end)

MachoMenuButton(MainSection, 'Fast Run [TOGGLE]', function()
    ToggleFastRun()
end)

MachoMenuButton(MainSection, 'Invisible [TOGGLE]', function()
    ToggleInvisible()
end)

MachoMenuButton(MainSection, 'Revive', function()
    ReviveSelf()
end)

MachoMenuButton(MainSection, 'Heal', function()
    HealSelf()
end)

-- ============================================================
--   CRASH & BYPASS TAB
-- ============================================================
local CrashTab = MachoMenuAddTab(MenuWindow, 'Crash')
local CrashSection = MachoMenuGroup(CrashTab, 'Crash & Bypass', GetSectionCoords(1, 1, 2, 2))

MachoMenuButton(CrashSection, 'Crash Nearby Player', function()
    CrashNearbyPlayers()
end)

MachoMenuButton(CrashSection, 'Universal AC Bypass', function()
    UniversalACBypass()
end)

-- ============================================================
--   TELEPORT TAB
-- ============================================================
local TeleportTab = MachoMenuAddTab(MenuWindow, 'Teleport')
local TeleportSection = MachoMenuGroup(TeleportTab, 'Teleport', GetSectionCoords(1, 1, 2, 2))

MachoMenuButton(TeleportSection, 'TP to Waypoint', function()
    local blip = GetFirstBlipInfoId(8)
    if DoesBlipExist(blip) then
        local wc = GetBlipInfoIdCoord(blip)
        local found, gz = GetGroundZFor_3dCoord(wc.x, wc.y, 100.0, false)
        SetEntityCoords(PlayerPedId(), wc.x, wc.y, found and gz + 1.0 or wc.z + 2.0)
        MachoMenuNotification("S1Dev", "~g~Teleported to waypoint!")
    else
        MachoMenuNotification("S1Dev", "~r~No waypoint set!")
    end
end)

MachoMenuButton(TeleportSection, 'TP to Airport', function()
    SetEntityCoords(PlayerPedId(), -1037.0, -2738.0, 20.17)
    MachoMenuNotification("S1Dev", "~g~Teleported to Airport!")
end)

MachoMenuButton(TeleportSection, 'TP to City Center', function()
    SetEntityCoords(PlayerPedId(), -75.0, -820.0, 326.17)
    MachoMenuNotification("S1Dev", "~g~Teleported to City Center!")
end)

MachoMenuButton(TeleportSection, 'TP Up in Air', function()
    local c = GetEntityCoords(PlayerPedId())
    SetEntityCoords(PlayerPedId(), c.x, c.y, 2000.0)
    MachoMenuNotification("S1Dev", "~g~Teleported up high!")
end)

-- ============================================================
--   WEAPONS TAB
-- ============================================================
local WeaponsTab = MachoMenuAddTab(MenuWindow, 'Weapons')
local WeaponsSection = MachoMenuGroup(WeaponsTab, 'Weapons', GetSectionCoords(1, 1, 2, 2))

MachoMenuButton(WeaponsSection, 'Give All Weapons', function()
    local weapons = {
        "WEAPON_PISTOL", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL", "WEAPON_MICROSMG",
        "WEAPON_SMG", "WEAPON_ASSAULTRIFLE", "WEAPON_CARBINERIFLE", "WEAPON_MG",
        "WEAPON_COMBATMG", "WEAPON_PUMPSHOTGUN", "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER",
        "WEAPON_RPG", "WEAPON_MINIGUN", "WEAPON_GRENADE"
    }
    local ped = PlayerPedId()
    for _, weapon in ipairs(weapons) do
        GiveWeaponToPed(ped, GetHashKey(weapon), 9999, false, true)
    end
    MachoMenuNotification("S1Dev", "~g~All weapons given!")
end)

MachoMenuButton(WeaponsSection, 'Remove All Weapons', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
    MachoMenuNotification("S1Dev", "~r~All weapons removed!")
end)

MachoMenuButton(WeaponsSection, 'Give RPG', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_RPG"), 99, false, true)
    MachoMenuNotification("S1Dev", "~g~RPG given!")
end)

MachoMenuButton(WeaponsSection, 'Give Minigun', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_MINIGUN"), 9999, false, true)
    MachoMenuNotification("S1Dev", "~g~Minigun given!")
end)

-- ============================================================
--   SETTINGS TAB
-- ============================================================
local SettingsTab = MachoMenuAddTab(MenuWindow, 'Settings')
local SettingsSection = MachoMenuGroup(SettingsTab, 'Settings', GetSectionCoords(1, 1, 2, 2))

MachoMenuButton(SettingsSection, 'Check Anti-Cheat', function()
    local detected = false
    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local lower = string.lower(resourceName)
            if lower:find('fiveguard') or lower:find('electron') or lower:find('waveshield') then
                detected = true
                MachoMenuNotification("S1Dev", "Detected: " .. resourceName)
                break
            end
        end
    end
    if not detected then
        MachoMenuNotification("S1Dev", "~g~No known Anti-Cheat detected")
    end
end)

MachoMenuButton(SettingsSection, 'Change Keybind', function()
    waitingForKey = true
    MachoMenuNotification('S1Dev', 'Press desired key to bind')
end)

local waitingForKey = false
MachoOnKeyDown(function(key)
    if waitingForKey then
        if key == 27 then
            waitingForKey = false
            MachoMenuNotification('S1Dev', 'Cancelled')
        else
            MachoMenuSetKeybind(MenuWindow, key)
            waitingForKey = false
            MachoMenuNotification('S1Dev', 'Keybind updated')
        end
    end
end)

print("^2[S1Dev]^7 ========================================")
print("^2[S1Dev]^7 Menu Loaded Successfully!")
print("^2[S1Dev]^7 Press CapsLock to open menu")
print("^2[S1Dev]^7 Features: Noclip, Godmode, Crash, Bypass")
print("^2[S1Dev]^7 ========================================")
