----------------------
-- Author : Deediezi
-- Version 4.5
--
-- Contributors : No contributors at the moment.
--
-- Github link : https://github.com/Deediezi/FiveM_LockSystem
-- You can contribute to the project. All the information is on Github.

--  Main algorithm with all functions and events - Client side

----
-- @var vehicles[plate_number] = newVehicle Object
local vehicles = {}
local engines = {}
local isInVehicle = false
local dict = "missfra1mcs_2_crew_react"
local anim = "handsup_standing_base"

ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

---- Retrieve the keys of a player when he reconnects.
-- The keys are synchronized with the server. If you restart the server, all keys disappear.
AddEventHandler("playerSpawned", function()
    TriggerServerEvent("ls:retrieveVehiclesOnconnect")
end)


---- Timer
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local player = GetPlayerPed(-1)
        if IsPedInAnyVehicle(player, 0) and not isInVehicle then 
            car = GetVehiclePedIsIn(player, 0)
            localVehPlate = string.lower(ESX.Math.Trim(GetVehicleNumberPlateText(car)))
            engines[localVehPlate] = (GetIsVehicleEngineRunning(car) and 1 or 0)
            isInVehicle = true 
        elseif not IsPedInAnyVehicle(player, 0) then
            isInVehicle = false 
        end
        if IsPedInAnyVehicle(player, 0) then 
            local veh = GetVehiclePedIsIn(player, 0)
            local vehPlate = string.lower(ESX.Math.Trim(GetVehicleNumberPlateText(veh)))
            if engines[vehPlate] == 0 then 
                SetVehicleUndriveable(GetVehiclePedIsIn(player, 0),true)
                local driver = GetPedInVehicleSeat(veh, -1)
                if IsControlJustPressed(0, 74) and driver == player then
                    if vehicles[vehPlate] == "locked" or not hasVehicle(vehPlate) then
                        local time = math.random(60,80)
                        local chance = 90
                        ESX.TriggerServerCallback('ls:getHotwires',function(value)
                            if value ~= nil and value == 1 then
                                time = math.random(5000,10000)
                                chance = 100
                                exports["mythic_notify"]:DoHudText("inform","Vehicle appears to be hotwired by someone else")
                            end
                        end,vehPlate)
                        TriggerEvent("mythic_progbar:client:progress", {
                            name = "hotwire_action",
                            duration = time,
                            label = "Hotwiring Vehicle",
                            useWhileDead = false,
                            canCancel = true,
                            controlDisables = {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            },
                            animation = {
                                animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
                                anim = "machinic_loop_mechandplayer",
                                flags = 49,
                            },
                            prop = {
                                
                            },
                        }, function(status)
                            if not status then
                                if math.random(0,100) <= chance then
                                    engines[vehPlate] = 1
                                    vehicles[vehPlate] = "hotwired"
                                    TriggerServerEvent("ls:addHotwire",vehPlate)
                                else
                                    exports["mythic_notify"]:DoHudText("inform","Could not hotwire this vehicle")
                                end
                            end
                        end)
                    end
                end
            end
        end
    end
end)

function changeEngineState(state,vehicle)
   local plate = string.lower(ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)))
   engines[plate] = state
end

Citizen.CreateThread(function()
    timer = Config.lockTimer * 1000
    time = 0
	while true do
		Wait(1000)
		time = time + 1000
	end
end)

---- Prevents the player from breaking the window if the vehicle is locked
-- (fixing a bug in the previous version)
Citizen.CreateThread(function()
	while true do
		Wait(0)
		local ped = GetPlayerPed(-1)
        if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId(ped))) then
        	local veh = GetVehiclePedIsTryingToEnter(PlayerPedId(ped))
	        local lock = GetVehicleDoorLockStatus(veh)
	        if lock == 4 then
	        	ClearPedTasks(ped)
	        end
        end
	end
end)

---- Locks vehicles if non-playable characters are in them, and makes them get out and give you keys if you aim at them
-- Can be disabled in "config/shared.lua"
if(Config.disableCar_NPC)then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local ped = GetPlayerPed(-1)
            if IsPedArmed(ped, 6) and not IsPedInAnyVehicle(ped, 1) then 
                if IsPlayerFreeAiming(PlayerId()) then
                    local pcoords = GetEntityCoords(ped,true)
                    local vicVeh = GetTargetedVehicle(pcoords,ped)
                    if vicVeh and vicVeh ~= 0 then
                        local victim = GetPedInVehicleSeat(vicVeh, -1)
                        if victim and not IsPedDeadOrDying(victim, 1) and not IsPedAPlayer(victim) then
                            Citizen.Wait(500)
                            if IsPlayerFreeAiming(PlayerId()) then
                                RequestAnimDict(dict)
                                while not HasAnimDictLoaded(dict) do
                                    RequestAnimDict(dict)
                                    Citizen.Wait(5)
                                end
                                local plt = string.lower(ESX.Math.Trim(GetVehicleNumberPlateText(vicVeh)))
                                ClearPedTasks(victim)
                                Citizen.Wait(100)
                                TaskLeaveAnyVehicle(victim, 1, 1)
                                Citizen.Wait(1000)
                                if IsPedSittingInVehicle(victim, vicVeh) then
                                    TaskLeaveAnyVehicle(victim, 1, 1)
                                    Citizen.Wait(500)
                                end
                                Citizen.Wait(1000)
                                local vcoords = GetEntityCoords(victim,true)
                                if not IsPedDeadOrDying(victim, 1) then
                                    TaskStandStill(victim, 3000)
                                    TaskPlayAnim(victim, dict, anim, 3.0, 2.0, .01, 49, 1.0, false, false, false)
                                    SetBlockingOfNonTemporaryEvents(victim, true)
                                    FreezeEntityPosition(victim, true)
                                    Citizen.Wait(3000)
                                    pcoords = GetEntityCoords(ped)
                                    ClearPedSecondaryTask(victim)
                                    TaskSmartFleePed(victim, ped, 100.0, -1, 0, 0)
                                    SetVehicleCanBeUsedByFleeingPeds(vicVeh, false)
                                    Citizen.Wait(50)
                                    FreezeEntityPosition(victim, false)
                                end
                                if not hasVehicle(plt) then
                                    if #(pcoords-vcoords) < 5.0 or IsPedDeadOrDying(victim, 1) then
                                        TriggerEvent("ls:newVehicle", plt, vicVeh, 1)
                                        TriggerServerEvent("ls:addOwner", plt)

                                        TriggerEvent("ls:notify", "Got the keys.")
                                    end
                                end
                            end
                        end
                    end
                end 
            end 
            if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId(ped))) then
                local veh = GetVehiclePedIsTryingToEnter(PlayerPedId(ped))
                local lock = GetVehicleDoorLockStatus(veh)
                if lock == 7 then
                    SetVehicleDoorsLocked(veh, 2)
                end
                local pedd = GetPedInVehicleSeat(veh, -1)
                if pedd then
                    SetPedCanBeDraggedOut(pedd, false)
                end
                if IsPedDeadOrDying(pedd,1) and pedd ~= 0 then 
                    while not IsPedSittingInVehicle(ped, veh) do
                        Citizen.Wait(500)
                    end
                    if GetPedInVehicleSeat(veh, -1) == ped then
                        local plt = string.lower(ESX.Math.Trim(GetVehicleNumberPlateText(veh)))
                        if not hasVehicle(plt) then
                            print(hasVehicle(plt))
                            TriggerEvent("ls:newVehicle", plt, veh, 1)
                            TriggerServerEvent("ls:addOwner", plt)

                            TriggerEvent("ls:notify", "Got the keys.")
                        end
                    end
                end
            end
        end
    end)
end


RegisterNetEvent("ls:lockOrGetKey")
AddEventHandler("ls:lockOrGetKey", function()
-- Init player infos
    local ply = GetPlayerPed(-1)
    local pCoords = GetEntityCoords(ply, true)
    local px, py, pz = table.unpack(GetEntityCoords(ply, true))
    isInside = false

    -- Retrieve the local ID of the targeted vehicle
    if IsPedInAnyVehicle(ply, true) and GetPedInVehicleSeat(GetVehiclePedIsIn(ply, false), -1) == ply then
        -- by sitting inside him
        localVehId = GetVehiclePedIsIn(ply, false)
        isInside = true
    else
        -- by targeting the vehicle
        localVehId = GetTargetedVehicle(pCoords, ply)
    end

    -- Get targeted vehicle infos
    if(localVehId and localVehId ~= 0)then
        local localVehPlateTest = GetVehicleNumberPlateText(localVehId)
        if localVehPlateTest ~= nil then
            local localVehPlate = string.lower(ESX.Math.Trim(localVehPlateTest))
            local localVehLockStatus = GetVehicleDoorLockStatus(localVehId)
            local hasKey = false

            -- If the vehicle appear in the table (if this is the player's vehicle or a locked vehicle)
            for plate, vehicle in pairs(vehicles) do
                if(string.lower(plate) == localVehPlate ) then
                    -- If the vehicle is not locked (this is the player's vehicle)
                    if(vehicle ~= "locked" and vehicle ~= "hotwired")then
                        hasKey = true
                        if(time > timer)then
                            -- update the vehicle infos (Useful for hydrating instances created by the /givekey command)
                            vehicle.update(localVehId, localVehLockStatus)
                            -- Lock or unlock the vehicle
                            vehicle.lock()
                            time = 0
                        else
                            TriggerEvent("ls:notify", _U("lock_cooldown", (timer / 1000)))
                        end
                    end
                end
            end

            -- If the player doesn't have the keys
            if(not hasKey and vehicles[localVehPlate] ~= "locked" and vehicles[localVehPlate] ~= "hotwired")then
                -- If the player is inside the vehicle
                if(isInside)then
                    exports["mythic_notify"]:DoHudText("inform","Searching for keys")
                    Citizen.Wait(5000)
                    if(canSteal())then
                        -- Check if the vehicle is already owned.
                        -- And send the parameters to create the vehicle object if this is not the case.
                        TriggerServerEvent('ls:checkOwner', localVehId, localVehPlate, localVehLockStatus)
                    else
                        -- If the player doesn't find the keys
                        -- Lock the vehicle (players can't try to find the keys again)
                        vehicles[localVehPlate] = "locked"
                        TriggerServerEvent("ls:lockTheVehicle", localVehPlate)
                        TriggerEvent("ls:notify", _U("keys_not_inside"))
                    end
                end
            end
        else
            TriggerEvent("ls:notify", _U("could_not_find_plate"))
        end
    end
end)

RegisterNetEvent("ls:engineControl")
AddEventHandler("ls:engineControl", function()
    local car = GetVehiclePedIsIn(GetPlayerPed(-1), false)
    local found = false
    local localVehPlate
    if(car and car ~= 0)then
        local localVehPlateTest = GetVehicleNumberPlateText(car)
        if localVehPlateTest ~= nil then
            localVehPlate = string.lower(ESX.Math.Trim(localVehPlateTest))
            for plate, vehicle in pairs(vehicles) do
                if(string.lower(plate) == localVehPlate ) then
                    -- If the vehicle is not locked (this is the player's vehicle)
                    if(vehicle ~= "locked")then
                        found = true
                    end
                end
            end
        end
    end
    if found or vehicles[localVehPlate] == "hotwired" then 
        if engines[localVehPlate] == 0 then 
            SetVehicleEngineOn(car,true,false,false)
            SetVehicleUndriveable(car,false)
            engines[localVehPlate] = 1
        else
            SetVehicleEngineOn(car,false,false,false)
            engines[localVehPlate] = 0
        end
    elseif engines[localVehPlate] == 1 then 
        ESX.TriggerServerCallback('ls:getHotwires',function(value)
            if value ~= nil and value == 1 then
                exports["mythic_notify"]:DoHudText("inform","Vehicle appears to be hotwired")
                vehicles[localVehPlate] = "hotwired"
                SetVehicleEngineOn(car,false,false,false)
                engines[localVehPlate] = 0
            else
                exports["mythic_notify"]:DoHudText("error","You dont have keys.")
            end
        end,localVehPlate)
    else
        exports["mythic_notify"]:DoHudText("error","You dont have keys.")
    end
end)

RegisterNetEvent("ls:setEngine")
AddEventHandler("ls:setEngine", function(car, plate,bool)
    local plate =string.lower(ESX.Math.Trim(plate))
    SetVehicleEngineOn(car, bool, false, false)
    if bool== true then 
        engines[car] = 1
    else
        engines[car] = 0
    end
end)

------------------------    EVENTS      ------------------------
------------------------     :)         ------------------------

---- Update a vehicle plate (for developers)
-- @param string oldPlate
-- @param string newPlate
RegisterNetEvent("ls:updateVehiclePlate")
AddEventHandler("ls:updateVehiclePlate", function(oldPlate, newPlate)
    local oldPlate = string.lower(oldPlate)
    local newPlate = string.lower(newPlate)

    if(vehicles[oldPlate])then
        vehicles[newPlate] = vehicles[oldPlate]
        vehicles[oldPlate] = nil

        TriggerServerEvent("ls:updateServerVehiclePlate", oldPlate, newPlate)
    end
end)

---- Event called from the server
-- Get the keys and create the vehicle Object if the vehicle has no owner
-- @param boolean hasOwner
-- @param int localVehId
-- @param string localVehPlate
-- @param int localVehLockStatus
RegisterNetEvent("ls:getHasOwner")
AddEventHandler("ls:getHasOwner", function(hasOwner, localVehId, localVehPlate, localVehLockStatus,msg)
    if(not hasOwner)then
        TriggerEvent("ls:newVehicle", localVehPlate, localVehId, localVehLockStatus)
        TriggerServerEvent("ls:addOwner", localVehPlate)
        if msg == nil then
            TriggerEvent("ls:notify", getRandomMsg())
        else
            TriggerEvent("ls:notify", msg)
        end
    else
        TriggerEvent("ls:notify", _U("vehicle_not_owned"))
    end
end)

---- Create a new vehicle object
-- @param int id [opt]
-- @param string plate
-- @param string lockStatus [opt]
RegisterNetEvent("ls:newVehicle")
AddEventHandler("ls:newVehicle", function(plate, id, lockStatus)
    if(plate)then
        local plate = string.lower(ESX.Math.Trim(plate))
        if(not id)then id = nil end
        if(not lockStatus)then lockStatus = nil end
        vehicles[plate] = newVehicle()
        vehicles[plate].__construct(plate, id, lockStatus)
    else
        print("Can't create the vehicle instance. Missing argument PLATE")
    end
end)

---- Event called from server when a player execute the /givekey command
-- Create a new vehicle object with its plate
-- @param string plate
RegisterNetEvent("ls:giveKeys")
AddEventHandler("ls:giveKeys", function(plate)
    local plate = string.lower(plate)
    TriggerEvent("ls:newVehicle", plate, nil, nil)
end)


RegisterNetEvent('ls:notify')
AddEventHandler('ls:notify', function(text, duration)
	exports["mythic_notify"]:DoHudText("inform",text)
end)

------------------------    FUNCTIONS      ------------------------
------------------------        :O         ------------------------

---- A simple algorithm that checks if the player finds the keys or not.
-- @return boolean
function canSteal()
    nb = math.random(1, 100)
    percentage = Config.percentage
    if(nb < percentage)then
        return true
    else
        return false
    end
end

---- Return a random message
-- @return string
function getRandomMsg()
    msgNb = math.random(1, #Config.randomMsg)
    return Config.randomMsg[msgNb]
end

---- Get a vehicle in direction
-- @param array coordFrom
-- @param array coordTo
-- @return int
function GetVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed(-1), 0)
	local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

function hasVehicle(plt)
    local found = false 
    for plate, vehicle in pairs(vehicles) do
        if(string.lower(plate) == plt ) then
            -- If the vehicle is not locked (this is the player's vehicle)
            if(vehicle ~= "locked")then
                found = true
            end
        end
    end
    return found
end

---- Get the vehicle in front of the player
-- @param array pCoords
-- @param int ply
-- @return int
function GetTargetedVehicle(pCoords, ply)
    for i = 1, 200 do
        coordB = GetOffsetFromEntityInWorldCoords(ply, 0.0, (6.281)/i, 0.0)
        targetedVehicle = GetVehicleInDirection(pCoords, coordB)
        if(targetedVehicle ~= nil and targetedVehicle ~= 0)then
            return targetedVehicle
        end
    end
    return
end

