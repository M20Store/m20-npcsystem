local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPeds = {}
local selectedPedIndex = nil



local function ButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

local function Button(ControlButton)
    N_0xe83a3e3557a56640(ControlButton)
end

local function setupScaleform(scaleform)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end
    DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 0, 0)
    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(0)
    Button(GetControlInstructionalButton(2, 152, true))
    ButtonMessage("Cancel")
    PopScaleformMovieFunctionVoid()
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(1)
    Button(GetControlInstructionalButton(2, 153, true))
    ButtonMessage("Place object")
    PopScaleformMovieFunctionVoid()
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(2)
    Button(GetControlInstructionalButton(2, 15, true))
    ButtonMessage("Rotate object")
    PopScaleformMovieFunctionVoid()
    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()
    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

RegisterCommand(Config.Commands.CreatePed, function(source, args, RawCommand)
    local playerPed = PlayerPedId()
    local m20 = ClonePed(playerPed, GetEntityHeading(playerPed), false, true)
    SetEntityAlpha(m20, 150)
    SetEntityCollision(m20, false, false)
    FreezeEntityPosition(m20, true)
    local placingPed = true
    local pedHeading = GetEntityHeading(playerPed)
    local form = setupScaleform("instructional_buttons")
    
    CreateThread(function()
        while placingPed do
            local hit, coords, entity = RayCastGamePlayCamera(20.0)
            local mouseX, mouseY = GetControlNormal(0, 1), GetControlNormal(0, 2)
            local camCoords = GetGameplayCamCoord()
            local farCoords = GetOffsetFromEntityInWorldCoords(playerPed, mouseX * 20.0, mouseY * 20.0, 0.0)
            if hit then
                SetEntityCoords(m20, coords.x, coords.y, coords.z)
            else
                SetEntityCoords(m20, farCoords.x, farCoords.y, farCoords.z)
            end

            DrawScaleformMovieFullscreen(form, 255, 255, 255, 255, 0)
            
            if IsControlPressed(0, 348) then
                local mouseY = GetDisabledControlNormal(0, 2)
                
                if mouseY < 0 then
                    pedHeading = pedHeading - 8.0
                elseif mouseY > 0 then
                    pedHeading = pedHeading + 8.0
                end
                
                if pedHeading > 360.0 then pedHeading = pedHeading - 360.0 end
                if pedHeading < 0.0 then pedHeading = pedHeading + 360.0 end
            end
            
            if IsControlPressed(0, 14) then
                pedHeading = pedHeading - Config.RotationSpeed
                if pedHeading < 0.0 then pedHeading = pedHeading + 360.0 end
            end
            
            if IsControlPressed(0, 15) then
                pedHeading = pedHeading + Config.RotationSpeed
                if pedHeading > 360.0 then pedHeading = pedHeading - 360.0 end
            end
            
            if IsControlPressed(0, 174) then
                pedHeading = pedHeading + Config.RotationSpeed
                if pedHeading > 360.0 then pedHeading = pedHeading - 360.0 end
            end
            
            if IsControlPressed(0, 175) then
                pedHeading = pedHeading - Config.RotationSpeed
                if pedHeading < 0.0 then pedHeading = pedHeading + 360.0 end
            end

            if IsControlJustPressed(0, 44) then
                CancelPlacement(m20)
                placingPed = false
            end

            SetEntityHeading(m20, pedHeading)
            if IsControlJustPressed(0, 38) then 
                PlaceSpawnedPed(m20, pedHeading)
                placingPed = false
            end
            
            Wait(0)
        end
    end)
end)

function CancelPlacement(m20)
    DeleteEntity(m20)
end

function PlaceSpawnedPed(m20, pedHeading)
    FreezeEntityPosition(m20, true)
    ResetEntityAlpha(m20)
    SetEntityCollision(m20, true, true)
    SetEntityHeading(m20, pedHeading)
    table.insert(spawnedPeds, m20)
    OpenPedAnimationMenu(m20)
end

local function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestSweptSphere(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, 0.2, 339, PlayerPedId(), 4))
    return b, c, e
end

function OpenPedAnimationMenu(ped)
    local menuOptions = {}

    for _, anim in ipairs(Config.PoseEmotes) do
        if anim.scenario then
            table.insert(menuOptions, {
                header = anim.label,
                params = {
                    event = "startScenarioForClone",
                    args = { ped = ped, scenario = anim.scenario }
                }
            })
        elseif anim.dict and anim.anim then
            table.insert(menuOptions, {
                header = anim.label,
                params = {
                    event = "startCustomAnimationForClone",
                    args = { ped = ped, dict = anim.dict, anim = anim.anim }
                }
            })
        end
    end

    exports['qb-menu']:openMenu(menuOptions)
end

RegisterNetEvent("startScenarioForClone", function(data)
    TaskStartScenarioInPlace(data.ped, data.scenario, 0, true)
end)

RegisterNetEvent("startCustomAnimationForClone",function (data)
    RequestAnimDict(data.dict)
    while not HasAnimDictLoaded(data.dict) do
        Wait(10)
    end
    TaskPlayAnim(data.ped, data.dict, data.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
end)

function RayCastFromPlayer()
    local playerPed = PlayerPedId()
    local camRot = GetGameplayCamRot(2)
    local camPos = GetGameplayCamCoord()
    local direction = RotationToDirection(camRot)
    local distance = 1000.0
    local destination = vector3(camPos.x + direction.x * distance, camPos.y + direction.y * distance, camPos.z + direction.z * distance)

    local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, destination.x, destination.y, destination.z, -1, playerPed, 0)
    local _, hit, endCoords, _, _ = GetShapeTestResult(rayHandle)

    return hit == 1, endCoords
end

function RotationToDirection(rotation)
    local radianX = math.rad(rotation.x)
    local radianZ = math.rad(rotation.z)
    local cosX = math.cos(radianX)
    return vector3(-math.sin(radianZ) * cosX, math.cos(radianZ) * cosX, math.sin(radianX))
end

RegisterCommand(Config.Commands.EditPeds, function()
    if #spawnedPeds == 0 then
        QBCore.Functions.Notify("No spawned characters found.", "error")
        return
    end
    
    local menuOptions = {}
    
    for i, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            local coords = GetEntityCoords(ped)
            table.insert(menuOptions, {
                header = "Character #" .. i,
                txt = "Coordinates: " .. math.floor(coords.x) .. ", " .. math.floor(coords.y) .. ", " .. math.floor(coords.z),
                params = {
                    event = "selectPedForEdit",
                    args = { index = i }
                }
            })
        else
            table.remove(spawnedPeds, i)
        end
    end
    
    exports['qb-menu']:openMenu(menuOptions)
end)

RegisterCommand(Config.Commands.DeleteAllPeds, function()

    local count = 0
    for i, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
            count = count + 1
        end
    end
    
    spawnedPeds = {}
    
    QBCore.Functions.Notify("Deleted " .. count .. " characters.", "success")
end)

RegisterNetEvent("selectPedForEdit", function(data)
    selectedPedIndex = data.index
    local ped = spawnedPeds[selectedPedIndex]
    
    if not DoesEntityExist(ped) then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"SYSTEM", "Selected character does not exist."}
        })
        return
    end
    
    local pedOptions = {
        {
            header = "Edit Character #" .. selectedPedIndex,
            txt = "Choose an option",
            isMenuHeader = true
        },
        {
            header = "Change Animation",
            txt = "Choose a new animation for the character",
            params = {
                event = "changePedAnimation",
                args = { index = selectedPedIndex }
            }
        },
        {
            header = "Move Character",
            txt = "Change character position",
            params = {
                event = "movePed",
                args = { index = selectedPedIndex }
            }
        },
        {
            header = "Delete Character",
            txt = "Remove the character",
            params = {
                event = "deletePed",
                args = { index = selectedPedIndex }
            }
        },
        {
            header = "Back",
            txt = "Return to character list",
            params = {
                event = "commandEditpeds",
            }
        }
    }
    
    exports['qb-menu']:openMenu(pedOptions)
end)

RegisterNetEvent("changePedAnimation", function(data)

    
    local ped = spawnedPeds[data.index]
    
    if DoesEntityExist(ped) then
        OpenPedAnimationMenu(ped)
    else
        QBCore.Functions.Notify("Selected character does not exist.", "error")
    end
end)

RegisterNetEvent("movePed", function(data)

    local ped = spawnedPeds[data.index]
    
    if not DoesEntityExist(ped) then
        QBCore.Functions.Notify("Selected character does not exist.", "error")
        return
    end
    
    local playerPed = PlayerPedId()
    local pedHeading = GetEntityHeading(ped)
    local isMovingPed = true
    local form = setupScaleform("instructional_buttons")
    
    SetEntityAlpha(ped, 150, false)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, false, false)
    
    CreateThread(function()
        while isMovingPed do
            local hit, coords, entity = RayCastGamePlayCamera(20.0)
            local mouseX, mouseY = GetControlNormal(0, 1), GetControlNormal(0, 2)
            local camCoords = GetGameplayCamCoord()
            local farCoords = GetOffsetFromEntityInWorldCoords(playerPed, mouseX * 20.0, mouseY * 20.0, 0.0)
            
            if hit then
                SetEntityCoords(ped, coords.x, coords.y, coords.z)
            else
                SetEntityCoords(ped, farCoords.x, farCoords.y, farCoords.z)
            end
            
            DrawScaleformMovieFullscreen(form, 255, 255, 255, 255, 0)
            
            local rotationSpeed = Config.RotationSpeed
            
            if IsControlPressed(0, 174) then
                pedHeading = pedHeading + rotationSpeed
                if pedHeading > 360.0 then pedHeading = pedHeading - 360.0 end
            end
            
            if IsControlPressed(0, 175) then
                pedHeading = pedHeading - rotationSpeed
                if pedHeading < 0.0 then pedHeading = pedHeading + 360.0 end
            end
            
            SetEntityHeading(ped, pedHeading)
            
            if IsControlJustPressed(0, 44) then
                ResetEntityAlpha(ped)
                FreezeEntityPosition(ped, true)
                SetEntityCollision(ped, true, true)
                isMovingPed = false
            end
            
            if IsControlJustPressed(0, 38) then
                ResetEntityAlpha(ped)
                FreezeEntityPosition(ped, true)
                SetEntityCollision(ped, true, true)
                QBCore.Functions.Notify("Character moved to new position.", "success")
                isMovingPed = false
            end
            
            Wait(0)
        end
    end)
end)

RegisterNetEvent("deletePed", function(data)

    
    local ped = spawnedPeds[data.index]
    
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
        QBCore.Functions.Notify("Character successfully deleted.", "success")
    else
        QBCore.Functions.Notify("Selected character does not exist.", "error")
    end
    
    table.remove(spawnedPeds, data.index)
end)

RegisterNetEvent("commandEditpeds", function()

    
    ExecuteCommand(Config.Commands.EditPeds)
end)