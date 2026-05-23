-- ============================================================
--   S1Dev Menu - Noclip, Crash, Bypass
--   Open: CapsLock (0x14)
-- ============================================================

MachoMenuNotification("S1Dev", "S1Dev Private 3.5v\n\nCapsLock to open menu")

-- ============================================================
--   GLOBAL VARIABLES
-- ============================================================
local noclipActive = false
local noclipSpeed = 7.0
local noclipThread = nil

-- ============================================================
--   UNIVERSAL AC BYPASS
-- ============================================================
local function UniversalACBypass()
    MachoMenuNotification("S1Dev", "Running Universal AC Bypass...")
    
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
    
    MachoMenuNotification("S1Dev", "Universal AC Bypass Applied!")
end

-- ============================================================
--   CRASH NEARBY PLAYER (FIXED - WORKING)
-- ============================================================
local function CrashNearbyPlayers()
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetPlayer = nil
    local targetServerId = nil
    local targetName = nil
    local closestDist = 150.0
    
    -- Find closest player
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            if DoesEntityExist(ep) then
                local ec = GetEntityCoords(ep)
                local dist = #(myCoords - ec)
                if dist < closestDist then
                    closestDist = dist
                    targetPlayer = player
                    targetServerId = GetPlayerServerId(player)
                    targetName = GetPlayerName(player)
                end
            end
        end
    end
    
    if not targetPlayer then
        MachoMenuNotification("S1Dev", "No players nearby!")
        return false
    end
    
    MachoMenuNotification("S1Dev", "Cashing " .. targetName .. " [ID:" .. targetServerId .. "]")
    
    local targetPed = GetPlayerPed(targetPlayer)
    local targetCoords = GetEntityCoords(targetPed)
    local myPed = PlayerPedId()
    
    -- Find nearest vehicle to the target
    local nearestVehicle = GetClosestVehicle(targetCoords, 100.0, 0, 70)
    
    if not nearestVehicle or nearestVehicle == 0 then
        -- No vehicle nearby, use ped spam crash method
        local modelHash = GetHashKey("player_one")
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 50 do
            Citizen.Wait(100)
            timeout = timeout + 1
        end
        
        if HasModelLoaded(modelHash) then
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
                    SetPedCanRagdoll(ped, false)
                end
                if i % 20 == 0 then Citizen.Wait(50) end
            end
            SetModelAsNoLongerNeeded(modelHash)
            MachoMenuNotification("S1Dev", "Ped crash executed on " .. targetName)
            return true
        end
    else
        -- Vehicle crash method
        local myOriginalCoords = GetEntityCoords(myPed)
        
        -- Hide player
        SetEntityVisible(myPed, false, false)
        SetLocalPlayerVisibleLocally(false)
        
        -- Get into the vehicle
        local netId = NetworkGetNetworkIdFromEntity(nearestVehicle)
        NetworkRequestControlOfEntity(nearestVehicle)
        
        local timeout = 0
        while not NetworkHasControlOfEntity(nearestVehicle) and timeout < 50 do
            NetworkRequestControlOfEntity(nearestVehicle)
            Citizen.Wait(10)
            timeout = timeout + 1
        end
        
        SetPedIntoVehicle(myPed, nearestVehicle, -1)
        Citizen.Wait(100)
        
        -- Attach vehicle to target player
        AttachEntityToEntityPhysically(
            nearestVehicle,
            targetPed,
            -1,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            1.0, 1.0, 1.0,
            true, true, false, false, 1
        )
        
        -- Launch vehicle
        SetEntityVelocity(nearestVehicle, 0, 0, 200)
        ApplyForceToEntity(nearestVehicle, 1, 0, 0, 500, 0, 0, 0, 0, false, false, true, true, true)
        
        -- Get out of vehicle
        Citizen.Wait(50)
        TaskLeaveVehicle(myPed, nearestVehicle, 0)
        Citizen.Wait(100)
        
        -- Return player to original position
        SetEntityCoords(myPed, myOriginalCoords.x, myOriginalCoords.y, myOriginalCoords.z, false, false, false, false)
        Citizen.Wait(50)
        SetEntityVisible(myPed, true, false)
        SetLocalPlayerVisibleLocally(true)
        
        MachoMenuNotification("S1Dev", "Vehicle crash executed on " .. targetName)
        return true
    end
    
    return false
end

-- ============================================================
--   NOCLIP
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
        MachoMenuNotification("S1Dev", "Noclip ON - WASD + Space/Ctrl to fly")
    else
        SetEntityVisible(PlayerPedId(), true, false)
        SetLocalPlayerVisibleLocally(true)
        MachoMenuNotification("S1Dev", "Noclip OFF")
    end
end

-- ============================================================
--   MENU
-- ============================================================
local MenuSize = vec2(400, 250)
local MenuStartCoords = vec2(500, 500) 

local TabsBarWidth = 0
local SectionChildWidth = MenuSize.x - TabsBarWidth
local SectionsCount = 1
local SectionsPadding = 10
local MachoPaneGap = 10
local EachSectionWidth = (SectionChildWidth - (SectionsPadding * (SectionsCount + 1))) / SectionsCount

local SectionOneStart = vec2(TabsBarWidth + (SectionsPadding * 1) + (EachSectionWidth * 0), SectionsPadding + MachoPaneGap)
local SectionOneEnd = vec2(SectionOneStart.x + EachSectionWidth, MenuSize.y - SectionsPadding)

MenuWindow = MachoMenuWindow(MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y)
MachoMenuSetAccent(MenuWindow, 30, 144, 255) -- Blue accent
MachoMenuSetKeybind(MenuWindow, 0x14) -- CapsLock

FirstSection = MachoMenuGroup(MenuWindow, "S1Dev Menu", SectionOneStart.x, SectionOneStart.y, SectionOneEnd.x, SectionOneEnd.y)

-- Noclip button
MachoMenuButton(FirstSection, "Noclip [TOGGLE]", function()
    ToggleNoclip()
end)

-- Noclip speed slider
MachoMenuSlider(FirstSection, "Noclip Speed", noclipSpeed, 1.0, 20.0, "", 1, function(Value)
    noclipSpeed = Value
end)

-- Crash button
MachoMenuButton(FirstSection, "Crash Nearby Player", function()
    CrashNearbyPlayers()
end)

-- Bypass button
MachoMenuButton(FirstSection, "Universal AC Bypass", function()
    UniversalACBypass()
end)

-- Close button
MachoMenuButton(FirstSection, "Close Menu", function()
    MachoMenuDestroy(MenuWindow)
end)

print("^2[S1Dev] ^7Loaded! Press CapsLock to open menu")