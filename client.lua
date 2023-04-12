-- Basics
ESX = nil
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

-- Cops on Patrol
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		StopAnyPedModelBeingSuppressed()
		SetScenarioTypeEnabled(WORLD_VEHICLE_POLICE_CAR, true)  
		SetScenarioTypeEnabled(WORLD_VEHICLE_POLICE_BIKE, true)  
		SetScenarioTypeEnabled(WORLD_VEHICLE_POLICE_NEXT_TO_CAR, true)  
		SetCreateRandomCops(true)  
		SetCreateRandomCopsNotOnScenarios(true)
		SetCreateRandomCopsOnScenarios(true) 	
		SetVehicleModelIsSuppressed(GetHashKey("police"), false)  
		SetVehicleModelIsSuppressed(GetHashKey("police2"), false)  
		SetVehicleModelIsSuppressed(GetHashKey("police3"), false)  
		SetVehicleModelIsSuppressed(GetHashKey("police4"), false)  
		SetVehicleModelIsSuppressed(GetHashKey("policeb"), false)  
		SetVehicleModelIsSuppressed(GetHashKey("policet"), false)  
		SetVehicleModelIsSuppressed(GetHashKey("pranger"), false)  
		SetVehicleModelIsSuppressed(GetHashKey("sheriff"), false)	
		SetVehicleModelIsSuppressed(GetHashKey("sheriff2"), false)	
		if IsPedInAnyVehicle(PlayerPedId(), false) then
			SetDispatchIdealSpawnDistance(490.0) --Ensure no pop-ins while driving fast
		else
			SetDispatchIdealSpawnDistance(200.0)
		end
	end
end)

-- Enumeration
local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end
        enum.destructor = nil
        enum.handle = nil
    end
}
local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()
        if not id or id == 0 then
            disposeFunc(iter)
            return
        end
      
        local enum = {handle = iter, destructor = disposeFunc}
        setmetatable(enum, entityEnumerator)
      
        local next = true
        repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
        until not next
      
        enum.destructor, enum.handle = nil, nil
        disposeFunc(iter)
    end)
end
function EnumeratePeds()
    return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end
function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end
function GetAllPeds()
    local peds = {}
    for ped in EnumeratePeds() do
        if DoesEntityExist(ped) then
            table.insert(peds, ped)
        end
    end
    return peds
end
function GetAllVehicles()
    local vehicles = {}
    for vehicle in EnumerateVehicles() do
        if DoesEntityExist(vehicle) then
            table.insert(vehicles, vehicle)
        end
    end
    return vehicles
end

-- Speeding Tickets from NPC Police

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1500)
		local playerPed = GetPlayerPed(-1)
		local playerPed2 = PlayerId()
		local pCoords = GetEntityCoords(playerPed, true)
		local playerveh = GetVehiclePedIsIn(playerPed, false)
		local playervehclass = GetVehicleClass(playerveh)
		local wantedlevel = GetPlayerWantedLevel(playerPed2)
		for vehicle in EnumerateVehicles() do
			local vtype = GetVehicleClass(vehicle)
			local vCoords = GetEntityCoords(vehicle, true)
			local copped = GetPedInVehicleSeat(vehicle, -1)
			local pedvehicle = GetVehiclePedIsIn(playerPed, false)
			local speed = GetEntitySpeed(pedvehicle)
			local mphcalc = speed * 2.236936
			local inpedvehicle = IsPedInVehicle(playerPed, pedvehicle, false)
			if vtype == 18 then  
				local vCoords = GetEntityCoords(vehicle, true)
				if GetDistanceBetweenCoords(pCoords.x, pCoords.y, pCoords.z, vCoords.x, vCoords.y, vCoords.z, true) <= 35.0 then 
					if copped ~= playerPed and copped ~= playerPed2 and wantedlevel == 0 and inpedvehicle == 1 and playervehclass ~= 18 
					and HasEntityClearLosToEntityInFront(copped, playerPed) then
						if mphcalc >= 45.0 and mphcalc <= 70.9 and DoesEntityExist(copped) and playervehclass ~= 18 then 
							local mph = ESX.Math.Round(mphcalc)
							exports['mythic_notify']:SendAlert("inform", 'Radar Detected - '..mph..' / 65 mph', 1500)
						end
						if mphcalc >= 71.0 and mphcalc <= 139.9 and DoesEntityExist(copped) and playervehclass ~= 18 then 
							local mph = ESX.Math.Round(mphcalc)
							SetEntityAsMissionEntity(vehicle, true, true)
							SetEntityAsMissionEntity(copped, true, true)
							SetEntityInvincible(vehicle, true)
							exports['mythic_notify']:SendAlert("error", 'Radar Detected - '..mph..' / 65 mph', 2500)
							Citizen.Wait(2000)
							SetVehicleSiren(vehicle, true)
							TaskVehicleFollow(copped, vehicle, pedvehicle, 35.0, 572, 20)
							Citizen.Wait(20000)
							exports['progressBars']:startUI(20000, "PULL OVER...")
							Citizen.Wait(20000)
							local speed2 = GetEntitySpeed(pedvehicle)
							local mphcalc2 = speed2 * 2.236936
							local pCoords = GetEntityCoords(playerPed, true)
							local copCoords = GetEntityCoords(copped, true)
							local distance = GetDistanceBetweenCoords(pCoords.x, pCoords.y, pCoords.z, copCoords.x, copCoords.y, copCoords.z, true) 
							local driverdoor = GetWorldPositionOfEntityBone(pedvehicle, GetEntityBoneIndexByName(pedvehicle, "door_dside_f"))
							local wantedlevel2 = GetPlayerWantedLevel(playerPed2)
							if mphcalc2 <= 2.5 and wantedlevel2 == 0 and distance <= 25.0 then
								exports['mythic_notify']:SendAlert("error", 'Engine Off')
								exports['mythic_notify']:SendAlert("inform", 'Window Down')
								Citizen.Wait(3000)
								TaskLeaveVehicle(copped, vehicle, 0)
								TaskGoToCoordAnyMeans(copped, pCoords, 1.0, 0, 786603, 0xbf800000)
								Citizen.Wait(15000)
								TriggerServerEvent('warrant:speedingticket')
								exports['mythic_notify']:SendAlert("inform", 'You have been fined $500 for speeding')
								exports['mythic_notify']:SendAlert("success", 'You are free to go')
								SetPedAsNoLongerNeeded(copped)
								SetVehicleAsNoLongerNeeded(vehicle)
							elseif mphcalc2 <= 2.5 and wantedlevel2 == 0 and distance >= 25.0 then
								TriggerServerEvent('warrant:speedingticket')
								Citizen.Wait(1000)
								exports['mythic_notify']:SendAlert("error", 'The officer has been called away')
								exports['mythic_notify']:SendAlert("inform", 'Your plate has been fined $500 for speeding')
								exports['mythic_notify']:SendAlert("success", 'You are free to go')
								SetPedAsNoLongerNeeded(copped)
								SetVehicleAsNoLongerNeeded(vehicle)
							elseif mphcalc2 > 2.5 and wantedlevel2 == 0 then 
								exports['mythic_notify']:SendAlert("inform", 'Failed to Stop')
								exports['mythic_notify']:SendAlert("error", 'A Warrant has been issued for your arrest')
								SetPlayerWantedLevel(PlayerId(), 1, false)
								SetPlayerWantedLevelNow(PlayerId(), false)
								Citizen.Wait(200)
								SetPedAsNoLongerNeeded(copped)
								SetVehicleAsNoLongerNeeded(vehicle)
							else
								SetPedAsNoLongerNeeded(copped)
								SetVehicleAsNoLongerNeeded(vehicle)
							end
						end
						if mphcalc >= 140.0 and DoesEntityExist(copped) and playervehclass ~= 18 then 
							local mph = ESX.Math.Round(mphcalc)
							exports['mythic_notify']:SendAlert("error", 'Radar Detected - '..mph..' / 135 mph', 2500)
							Citizen.Wait(1000)
							exports['mythic_notify']:SendAlert("success", 'Excessive Speeding')
							exports['mythic_notify']:SendAlert("inform", 'A Warrant has been issued for your arrest')
							SetPlayerWantedLevel(PlayerId(), 1, false)
							SetPlayerWantedLevelNow(PlayerId(), false)
							Citizen.Wait(200)
							SetPedAsNoLongerNeeded(copped)
							SetVehicleAsNoLongerNeeded(vehicle)
						end
					end
				end
			end
		end
    end
end)
