local RSGCore = exports['rsg-core']:GetCoreObject()
local carthash = nil
local cargohash = nil
local lighthash = nil
local distance = nil
local currentDeliveryWagon = nil
local wagonSpawned = false
local DeliverySecondsRemaining = 0
local deliverytime = 0
local deliveryactive = false

----------------------------------------------------
-- function format delivery time
----------------------------------------------------
function secondsToClock(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local seconds = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

----------------------------------------------------
-- function drawtext
----------------------------------------------------
function DrawText3D(x, y, z, text)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str,_x,_y)
end

----------------------------------------------------
-- delivery timer
----------------------------------------------------
local function DeliveryTimer(deliverytime, vehicle, endcoords)
    
    DeliverySecondsRemaining = (deliverytime * 60)

    Citizen.CreateThread(function()
        while true do
            if DeliverySecondsRemaining > 0 then
                Wait(1000)
                DeliverySecondsRemaining = DeliverySecondsRemaining - 1
                if DeliverySecondsRemaining == 0 and wagonSpawned == true then
                    ClearGpsMultiRoute(endcoords)
                    endcoords = nil
                    DeleteVehicle(vehicle)
                    wagonSpawned = false
                    deliveryactive = false
                    lib.notify({ title = Lang:t('error.failed_del'), description = Lang:t('error.failed_del_descr'), type = 'error' })
                end
            end

            if deliveryactive == true then
                local formattedTime = secondsToClock(DeliverySecondsRemaining)
                lib.showTextUI('Time Remaining : '..formattedTime, {
                    position = "top-center",
                    icon = 'fa-regular fa-clock',
                    style = {
                        borderRadius = 0,
                        backgroundColor = '#82283E',
                        color = 'white'
                    }
                })
                Wait(0)
            else
                lib.hideTextUI()
                return
            end
            Wait(0)
        end
    end)
end

----------------------------------------------------
-- prompts and blips
----------------------------------------------------
Citizen.CreateThread(function()
    for delivery, v in pairs(Config.DeliveryLocations) do
        exports['rsg-core']:createPrompt(v.deliveryid, v.startcoords, RSGCore.Shared.Keybinds['J'], v.name, {
            type = 'client',
            event = 'rsg-delivery:client:vehiclespawn',
            args = { v.deliveryid, v.cart, v.cartspawn, v.cargo, v.light, v.endcoords, v.showgps, v.deliverytime },
        })
        if v.showblip == true then
            local DeliveryBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.startcoords)
            SetBlipSprite(DeliveryBlip, joaat(Config.Blip.blipSprite), true)
            SetBlipScale(DeliveryBlip, Config.Blip.blipScale)
            Citizen.InvokeNative(0x9CB1A1623062F402, DeliveryBlip, Config.Blip.blipName)
        end
    end
end)

----------------------------------------------------
-- spawn wagon / set delivery
----------------------------------------------------
RegisterNetEvent('rsg-delivery:client:vehiclespawn')
AddEventHandler('rsg-delivery:client:vehiclespawn', function(deliveryid, cart, cartspawn, cargo, light, endcoords, showgps, deliverytime)
    if wagonSpawned == false then
        local playerPed = PlayerPedId()
        local carthash = joaat(cart)
        local cargohash = joaat(cargo)
        local lighthash = joaat(light)
        local coordsCartSpawn = vector3(cartspawn.x, cartspawn.y, cartspawn.z)
        local coordsEnd = vector3(endcoords.x, endcoords.y, endcoords.z)
        local distance = #(coordsCartSpawn - coordsEnd) 
        local cashreward = (math.floor(distance) / 100)
        
        if Config.Debug == true then
            print('carthash '..carthash)
            print('cargohash '..cargohash)
            print('lighthash '..lighthash)
            print('distance '..distance)
            print('cashreward '..cashreward)
        end
        
        RequestModel(carthash, cargohash, lighthash)
        while not HasModelLoaded(carthash, cargohash, lighthash) do
            RequestModel(carthash, cargohash, lighthash)
            Citizen.Wait(0)
        end
        
        local coords = vector3(cartspawn.x, cartspawn.y, cartspawn.z)
        local heading = cartspawn.w
        local vehicle = CreateVehicle(carthash, coords, heading, true, false)
        SetVehicleOnGroundProperly(vehicle)
        Wait(200)
        SetModelAsNoLongerNeeded(carthash)
        Citizen.InvokeNative(0xD80FAF919A2E56EA, vehicle, cargohash)
        Citizen.InvokeNative(0xC0F0417A90402742, vehicle, lighthash)
        TaskEnterVehicle(playerPed, vehicle, 10000, -1, 1.0, 1, 0)
        if showgps == true then
            StartGpsMultiRoute(joaat("COLOR_RED"), true, true)
            AddPointToGpsMultiRoute(endcoords)
            SetGpsMultiRouteRender(true)
        end
        currentDeliveryWagon = vehicle
        wagonSpawned = true
        deliveryactive = true
        DeliveryTimer(deliverytime, vehicle, endcoords)
        while true do
            local sleep = 1000
            if wagonSpawned == true then
                local vehpos = GetEntityCoords(currentDeliveryWagon, true)
                if #(vehpos - endcoords) < 250.0 then
                    sleep = 0
                    DrawText3D(endcoords.x, endcoords.y, endcoords.z + 0.98, Lang:t('label.delivery_point'))
                    if #(vehpos - endcoords) < 3.0 then
                        if showgps == true then
                            ClearGpsMultiRoute(endcoords)
                        end
                        endcoords = nil
                        DeleteVehicle(currentDeliveryWagon)
                        wagonSpawned = false
                        deliveryactive = false
                        DeliverySecondsRemaining = 0
                        SetEntityAsNoLongerNeeded(currentDeliveryWagon)
                        TriggerServerEvent('rsg-delivery:server:givereward', cashreward)
                        lib.notify({ title = Lang:t('success.success_del'), description = Lang:t('success.success_del_descr'), type = 'success' })
                    end
                end
            end
            Wait(sleep)
        end
    end
end)

---------------------------------------------------------------------
-- get wagon state / fail delivery if damaged
---------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        if wagonSpawned then
            local drivable = Citizen.InvokeNative(0xB86D29B10F627379, currentDeliveryWagon, false, false) -- IsVehicleDriveable
            if not drivable then
                lib.notify({ title = 'Delivery Failed!', description = 'your delivery failed due to damaged wagon!', type = 'inform', duration = 7000 })
                DeleteVehicle(currentDeliveryWagon)
                wagonSpawned = false
                deliveryactive = false
                DeliverySecondsRemaining = 0
                SetEntityAsNoLongerNeeded(currentDeliveryWagon)
                wagonSpawned = false
                ClearGpsMultiRoute()
                lib.hideTextUI()
            end
        end
    end
end)
