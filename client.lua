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
				if GetDistanceBetweenCoords(pCoords.x, pCoords.y, pCoords.z, vCoords.x, vCoords.y, vCoords.z, true) <= 50.0 then 
					if copped ~= playerPed and copped ~= playerPed2 and wantedlevel == 0 and inpedvehicle == 1 and playervehclass ~= 18 
					and HasEntityClearLosToEntityInFront(copped, playerPed) then
						if mphcalc >= 45.0 and mphcalc <= 70.0 and DoesEntityExist(copped) and playervehclass ~= 18 then 
							local mph = ESX.Math.Round(mphcalc)
							exports['mythic_notify']:SendAlert("inform", 'Radar Detected - '..mph..' / 65 mph', 1500)
						end
						if mphcalc > 70.0 and mphcalc <= 145.0 and DoesEntityExist(copped) and playervehclass ~= 18 then 
							local mph = ESX.Math.Round(mphcalc)
							SetEntityAsMissionEntity(vehicle, true, true)
							SetEntityAsMissionEntity(copped, true, true)
							exports['mythic_notify']:SendAlert("error", 'Radar Detected - '..mph..' / 65 mph', 2500)
							Citizen.Wait(2000)
							SetVehicleSiren(vehicle, true)
							TaskVehicleFollow(copped, vehicle, pedvehicle, 25.0, 572, 20)
							SetEntityInvincible(vehicle, true)
							speed2 = GetEntitySpeed(pedvehicle)
							mphcalc2 = speed2 * 2.236936
							pCoords = GetEntityCoords(playerPed, true)
							copCoords = GetEntityCoords(copped, true)
							driverdoor = GetWorldPositionOfEntityBone(pedvehicle, GetEntityBoneIndexByName(pedvehicle, "door_dside_f"))
							wantedlevel2 = GetPlayerWantedLevel(playerPed2)
							distance = GetDistanceBetweenCoords(pCoords.x, pCoords.y, pCoords.z, copCoords.x, copCoords.y, copCoords.z, true) 
							Citizen.Wait(7000) 
							exports['progressBars']:startUI(20000, "PULL OVER...")
							Citizen.Wait(20000)
							speed2 = GetEntitySpeed(pedvehicle)
							mphcalc2 = speed2 * 2.236936
							if mphcalc2 <= 2.5 and wantedlevel2 == 0 then
								while distance >= 25.0 and wantedlevel2 == 0 do
									ESX.ShowNotification("Please Wait Here...")
									speed2 = GetEntitySpeed(pedvehicle)
									mphcalc2 = speed2 * 2.236936
									if mphcalc2 > 2.5 and wantedlevel2 == 0 then 
										exports['mythic_notify']:SendAlert("inform", 'Failed to Stop')
										exports['mythic_notify']:SendAlert("error", 'A Warrant has been issued for your arrest')
										SetPlayerWantedLevel(PlayerId(), 1, false)
										SetPlayerWantedLevelNow(PlayerId(), false)
										Citizen.Wait(200)
										SetPedAsNoLongerNeeded(copped)
										SetVehicleAsNoLongerNeeded(vehicle)
										SetEntityInvincible(vehicle, false)
										break
									end
									Citizen.Wait(3000)
									pCoords = GetEntityCoords(playerPed, true)
									copCoords = GetEntityCoords(copped, true)
									distance = GetDistanceBetweenCoords(pCoords.x, pCoords.y, pCoords.z, copCoords.x, copCoords.y, copCoords.z, true) 
								end
								if mphcalc2 <= 2.5 and wantedlevel2 == 0 then
									exports['mythic_notify']:SendAlert("error", 'Engine Off')
									Citizen.Wait(1000)
									exports['mythic_notify']:SendAlert("inform", 'Window Down')
									Citizen.Wait(2000)
									TaskLeaveVehicle(copped, vehicle, 0)
									TaskGoToCoordAnyMeans(copped, pCoords, 1.0, 0, 786603, 0xbf800000)
								end
								while mphcalc2 <= 2.5 and wantedlevel2 == 0 and distance > 3.0 do
									speed2 = GetEntitySpeed(pedvehicle)
									mphcalc2 = speed2 * 2.236936
									if mphcalc2 > 2.5 and wantedlevel2 == 0 then 
										exports['mythic_notify']:SendAlert("inform", 'Failed to Stop')
										exports['mythic_notify']:SendAlert("error", 'A Warrant has been issued for your arrest')
										SetPlayerWantedLevel(PlayerId(), 1, false)
										SetPlayerWantedLevelNow(PlayerId(), false)
										Citizen.Wait(200)
										SetPedAsNoLongerNeeded(copped)
										SetVehicleAsNoLongerNeeded(vehicle)
										SetEntityInvincible(vehicle, false)
										break
									end
									Citizen.Wait(3000)
									pCoords = GetEntityCoords(playerPed, true)
									copCoords = GetEntityCoords(copped, true)
									distance = GetDistanceBetweenCoords(pCoords.x, pCoords.y, pCoords.z, copCoords.x, copCoords.y, copCoords.z, true) 
								end
								if mphcalc2 <= 2.5 and wantedlevel2 == 0 then
									TriggerServerEvent('warrant:speedingticket')
									exports['mythic_notify']:SendAlert("inform", 'You have been fined $500 for speeding')
									exports['mythic_notify']:SendAlert("success", 'You are free to go')
								end
								SetPedAsNoLongerNeeded(copped)
								SetVehicleAsNoLongerNeeded(vehicle)
								SetEntityInvincible(vehicle, false)
							elseif mphcalc2 > 2.5 and wantedlevel2 == 0 then 
								exports['mythic_notify']:SendAlert("inform", 'Failed to Stop')
								exports['mythic_notify']:SendAlert("error", 'A Warrant has been issued for your arrest')
								SetPlayerWantedLevel(PlayerId(), 1, false)
								SetPlayerWantedLevelNow(PlayerId(), false)
								Citizen.Wait(200)
								SetPedAsNoLongerNeeded(copped)
								SetVehicleAsNoLongerNeeded(vehicle)
								SetEntityInvincible(vehicle, false)
							end
						end
						if mphcalc > 145.0 and DoesEntityExist(copped) and playervehclass ~= 18 then 
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
