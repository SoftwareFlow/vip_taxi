local currentTaxi = nil
local npcDriver = nil
local destination = nil
local isTaxiActive = false

RegisterCommand("taxi", function()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)

    -- VEHICLE MODEL --
    local vehicleModel = "superd" -- change here your vehicle i.e. "taxi"
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(500)
    end

    -- CREATE VEHICLE NEAR PLAYER --
    local taxi = CreateVehicle(vehicleModel, playerPos.x + 5, playerPos.y + 5, playerPos.z, GetEntityHeading(playerPed), true, false)
    SetEntityAsMissionEntity(taxi, true, true)
    SetVehicleDoorsLocked(taxi, 1)  -- Is vehicle locked?
    SetVehicleColours(taxi, 1, 64)
    SetVehicleNumberPlateText(taxi, "VIP")

    -- LOAD NPC MODEL --
    local npcModel = "a_m_m_business_01"
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(500)
    end

    -- CREATE DRIVER --
    local driver = CreatePed(4, npcModel, playerPos.x + 5, playerPos.y + 5, playerPos.z, GetEntityHeading(playerPed), true, true)
    SetEntityAsMissionEntity(driver, true, true)

    TaskWarpPedIntoVehicle(driver, taxi, -1)
    SetDriverAbility(driver, 1.0)
    SetDriverAggressiveness(driver, 0.0)
    SetPedKeepTask(driver, true)

    -- LET PLAYER SPAWN IN --
    TaskWarpPedIntoVehicle(playerPed, taxi, 1)

    -- SAVINGS --
    currentTaxi = taxi
    npcDriver = driver
    isTaxiActive = true


    local waypoint = GetFirstBlipInfoId(8)
    
    if waypoint then
        destination = GetBlipInfoIdCoord(waypoint)


        TaskVehicleDriveToCoordLongrange(driver, taxi, destination.x, destination.y, destination.z, 15.0, 786603, 10.0)
        

        Citizen.CreateThread(function()
            while isTaxiActive do
                Citizen.Wait(1000)

                local taxiPos = GetEntityCoords(currentTaxi)
                local distance = #(taxiPos - destination)


                if distance < 10.0 then
                    TaskVehicleTempAction(driver, currentTaxi, 6, 3000) -- Taxi anhalten
                    Citizen.Wait(3000)
                    DeleteVehicle(currentTaxi)
                    DeletePed(npcDriver)
                    currentTaxi = nil
                    npcDriver = nil
                    isTaxiActive = false
                    --print("Taxi was deleted, Destination arrived.") -- FOR DEBUG ONLY! READ IN F8
                end
            end
        end)
    else
        --print("No Waypoint set, taxi stay idle.") -- FOR DEBUG ONLY! READ IN F8
    end
end, false)

-- HOLD THE DRIVE --
RegisterCommand("holdtaxi", function()
    if isTaxiActive and currentTaxi and npcDriver then
        TaskVehicleTempAction(npcDriver, currentTaxi, 6, 1000)  -- Anhalten des Taxis
        isTaxiStopped = true
        print("Taxi wurde angehalten.")
    else
        print("Kein aktives Taxi.")
    end
end, false)

-- CONTINUE THE DRIVE --
RegisterCommand("gotaxi", function()
    if isTaxiActive and currentTaxi and npcDriver and destination then
        TaskVehicleDriveToCoordLongrange(npcDriver, currentTaxi, destination.x, destination.y, destination.z, 15.0, 786603, 10.0)
        isTaxiStopped = false
        print("Taxi fährt zum Wegpunkt.")
    else
        print("Kein aktives Taxi oder kein Wegpunkt gesetzt.")
    end
end, false)

-- CANCEL THE DRIVE --
RegisterCommand("canceltaxi", function()
    if isTaxiActive and currentTaxi and npcDriver then
        DeleteVehicle(currentTaxi)  -- Löscht das Taxi
        DeletePed(npcDriver)  -- Löscht den NPC-Fahrer
        currentTaxi = nil
        npcDriver = nil
        isTaxiActive = false
        isTaxiStopped = false
        print("Fahrt abgebrochen. Taxi wurde gelöscht.")
    else
        print("Kein aktives Taxi.")
    end
end, false)
