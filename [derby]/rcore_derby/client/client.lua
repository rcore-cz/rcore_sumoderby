---------------------------------------------------------------
-- Init logic
---------------------------------------------------------------
local ArenaAPI = exports.ArenaAPI

local ScaleformHandle = RequestScaleformMovie("mp_big_message_freemode")
local DisplayMessage = false
local ArenaBusy = false
local SpawnData = nil
local InCar = false
local vehicle = nil
local PrevPos = nil

local RemoveStreakInSeconds = 0
local CurrentStreak = -1

------------------------

Config.WinnerPositions = {
    First = {
        Position = vector3(405.45, -967.74, -100),
        Heading = 180.0,
    },
    Second = {
        Position = vector3(402.44, -964.72, -100),
        Heading = 86.93,
    },
    Third = {
        Position = vector3(405.45, -961.93, -100),
        Heading = 2.5,
    },
}

Config.WinnerCameraPositions = {
    First = {
        Position = vector3(405.49, -968.91, -98.5),
        Rotation = vector3(0, 0, 0),
    },
    Second = {
        Position = vector3(401.28, -964.79, -98.5),
        Rotation = vector3(0, 0, -90),
    },
    Third = {
        Position = vector3(405.45, -960.48, -98.5),
        Rotation = vector3(0, 0, -180),
    },
    Fourth = {
        Position = vector3(409.71, -964.77, -98.5),
        Rotation = vector3(0, 0, -90),
    }
}

Config.RestPlayers = {
    Position = vector3(414.16, -962.76, -100),
    Heading = 90.64,
}

---------------------------------------------------------------
-- Function list
---------------------------------------------------------------
-- Will send NUI message to html with command "make page visible"
--- @param bool bool
function SetDisplay(bool)
    SendNUIMessage({
        type = "ui",
        status = bool,
    })
end

-- Will add 100 points in scoreboard on top of screen
function AddDestroyScore()
    SendNUIMessage({ type = "addScore", })
end

-- Will display free mode message
--- @param Message string
--- @param time int
--- @param Desc string
function ShowFreemodeMessage(Message, time, Desc)
    DisplayMessage = true
    BeginScaleformMovieMethod(ScaleformHandle, "SHOW_SHARD_WASTED_MP_MESSAGE") -- The function you want to call from the AS file
    PushScaleformMovieMethodParameterString(Message) -- bigTxt
    PushScaleformMovieMethodParameterString(Desc or "") -- msgText
    EndScaleformMovieMethod()
    Wait(time)
end

-- Will return a current name of the arena what player is inside
-- if he isnt in any arena it will return "none"
function GetPlayerActiveArena()
    for k, v in pairs(Config.DerbyArenaNameList) do
        if ArenaAPI:IsPlayerInArena(v) then
            return v
        end
    end
    return "none"
end

-- Will hide Free mode message
function HideFreemodeMessage()
    DisplayMessage = false
end

-- Will use function "SakeGamePlaycam" with permission list
function _ShakeCam(...)
    if Config.EnableEffects and Config.EnableShakeCam then
        ShakeGameplayCam(...)
    end
end

-- Will use "AnimpostfxPlay" with permission list
function CamEffect(...)
    if Config.EnableEffects and Config.EnableFXEffects then
        AnimpostfxPlay(...)
    end
end

-- Will respawn player
--- @param ped entity
--- @param coords vector3
--- @param heading float
function RespawnPed(ped, coords, heading)
    if not Config.EnableReviveEvent then
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        SetPlayerInvincible(ped, false)
        ClearPedBloodDamage(ped)
    else
        FreezeEntityPosition(PlayerPedId(), true)
        Config.ReviveEvent()
        Wait(300)
        FreezeEntityPosition(PlayerPedId(), false)
    end
end

-- Honestly no idea why is this here in function category... will move it later
for k, v in pairs(Config.DerbyArenaNameList) do
    ArenaAPI:OnPlayerExitLobby(v, function()
        SetDisplay(false)
        if InCar and vehicle ~= 0 then
            DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
            DeleteEntity(vehicle)
        end
        InCar = false
        if ArenaBusy then
            SetEntityCoords(PlayerPedId(), PrevPos.x, PrevPos.y, PrevPos.z)
            vehicle = nil
            ArenaBusy = false
        end
    end)
end

-- This is just simple label to get Player server ID
--- @param ped entity
function _GetPlayerServerID(ped)
    return GetPlayerServerId(NetworkGetEntityOwner(ped))
end

---------------------------------------------------------------
-- Threads
---------------------------------------------------------------
-- repair player vehicle if 15 seconds passed
CreateThread(function()
    while true do
        Wait(15000)
        if ArenaAPI:IsPlayerInArena(GetPlayerActiveArena()) and ArenaBusy then
            local playerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            SetVehicleEngineHealth(playerVehicle, 1000)
            SetVehicleEngineOn(playerVehicle, true, true)
            SetVehicleFixed(playerVehicle)
        end
    end
end)

-- dont allow player to shoot from car
CreateThread(function()
    while true do
        Wait(0)
        if ArenaBusy then
            SetPlayerCanDoDriveBy(PlayerId(), false)
        else
            Wait(1000)
        end
    end
end)

-- if player somehow get out of vehicle, teleport him back
CreateThread(function()
    while true do
        Wait(1000)
        if ArenaAPI:IsPlayerInArena(GetPlayerActiveArena()) and ArenaBusy and vehicle ~= nil then
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        end
    end
end)

-- Controls who actually push who off the cliff (Code by TEB from five-dev.cz)
CreateThread(function()
    while true do
        Wait(200)
        if ArenaBusy then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)

            if veh > 0 then
                local vehCoord = GetEntityCoords(veh)
                local fwdVector = GetEntityForwardVector(veh)
                local rayEnd = vehCoord + fwdVector * 4

                local ray = StartShapeTestRay(vehCoord.x, vehCoord.y, vehCoord.z, rayEnd.x, rayEnd.y, rayEnd.z, 2, veh, 4)
                local _, hit, endCoords, _, entityHit = GetShapeTestResult(ray)

                if hit > 0 and entityHit > 0 then
                    local driverPed = GetPedInVehicleSeat(entityHit, -1)
                    -- this isnt best practise but i am too lazy to make better one.
                    TriggerServerEvent("rcore_derby:SetPlayerHit", _GetPlayerServerID(driverPed))
                end
            end
        else
            Wait(1000)
        end
    end
end)

-- checking if player is outside arena so we can teleport him back and count lifes
CreateThread(function()
    while true do
        Wait(500)
        if ArenaAPI:IsPlayerInArena(GetPlayerActiveArena()) and ArenaBusy and InCar then
            if #(GetEntityCoords(PlayerPedId()) - Config.ArenaLocation) > Config.ArenaDistance or GetEntityCoords(PlayerPedId()).z < Config.MinimumZLevel then
                TriggerServerEvent("rcore_derby:CountLife")
                DoScreenFadeOut(1000)
                Wait(1000)
                local playerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                local position = SpawnData.Position
                local heading = SpawnData.Heading

                SetEntityCoords(playerVehicle, position.x, position.y, position.z)
                SetVehicleOnGroundProperly(playerVehicle)

                SetEntityHeading(playerVehicle, heading)

                SetVehicleEngineHealth(playerVehicle, 1000)
                SetVehicleEngineOn(playerVehicle, true, true)
                SetVehicleFixed(playerVehicle)
                DoScreenFadeIn(500)
            end
        end
    end
end)

-- Displaying message
CreateThread(function()
    while true do
        Wait(0)
        if DisplayMessage then
            DrawScaleformMovieFullscreen(ScaleformHandle, 255, 255, 255, 255)
        else
            Wait(500)
        end
    end
end)

-- Counting how many kills
CreateThread(function()
    while true do
        Wait(1000)
        if ArenaBusy then
            if RemoveStreakInSeconds == 0 then
                CurrentStreak = -1
            else
                RemoveStreakInSeconds = RemoveStreakInSeconds - 1
            end
        end
    end
end)
---------------------------------------------------------------
-- Events
---------------------------------------------------------------
-- Will select player position on end scene
-- and display score of the players
-- and will teleportem back to their previous positions
RegisterNetEvent("rcore_derby:ArenaEnded")
AddEventHandler("rcore_derby:ArenaEnded", function(sorted)
    DoScreenFadeOut(1500)
    Wait(1500)
    local ServerID = _GetPlayerServerID(PlayerPedId())
    ArenaBusy = false
    disableControls(true)
    SetDisplay(false)
    DeleteEntity(GetVehiclePedIsIn(PlayerPedId(), false))
    DeleteEntity(vehicle)
    vehicle = nil

    local func = {
        [1] = function()
            local ped = PlayerPedId()
            local v = Config.WinnerPositions.First
            SetEntityCoords(ped, v.Position.x, v.Position.y, v.Position.z)
            SetEntityHeading(ped, v.Heading)
        end,
        [2] = function()
            local ped = PlayerPedId()
            local v = Config.WinnerPositions.Second
            SetEntityCoords(ped, v.Position.x, v.Position.y, v.Position.z)
            SetEntityHeading(ped, v.Heading)
        end,
        [3] = function()
            local ped = PlayerPedId()
            local v = Config.WinnerPositions.Third
            SetEntityCoords(ped, v.Position.x, v.Position.y, v.Position.z)
            SetEntityHeading(ped, v.Heading)
        end
    }

    Wait(10)

    local vv = Config.WinnerCameraPositions.Fourth

    SetEntityCoords(PlayerPedId(), vv.Position.x, vv.Position.y, vv.Position.z)

    local countPos = -3
    for k, v in pairs(sorted) do
        countPos = countPos + 1
        if v.id == ServerID then
            if func[k] then
                func[k]()
                local ped = PlayerPedId()
                FreezeEntityPosition(ped, true)
                ClearPedBloodDamage(ped)
                ClearPedEnvDirt(ped)
            else
                local minus = -1 * countPos
                local ped = PlayerPedId()
                local v = Config.RestPlayers.Position
                SetEntityCoords(ped, v.x, v.y + minus, v.z)
                SetEntityHeading(ped, Config.RestPlayers.Heading)
                FreezeEntityPosition(ped, true)
                ClearPedBloodDamage(ped)
                ClearPedEnvDirt(ped)
            end
        end
    end

    Wait(3000)
    DoScreenFadeIn(1500)


    local data = Config.WinnerCameraPositions
    local effectName = "HeistLocate" or Config.GameplayCameraEffect
    local camera = createCamera('winnerCam', data.First.Position, data.First.Rotation)
    Wait(10)
    camera.render()
    Wait(2000)
    ShowFreemodeMessage('', 300, '')
    PlaySoundFrontend(-1, "LOSER", "HUD_AWARDS")
    CamEffect(effectName, 2500, false)
    ShowFreemodeMessage(Locales["1_place"], 4950, '~n~~w~' .. GetPlayerName(GetPlayerFromServerId(sorted[1].id)) .. '~n~~n~' .. sorted[1].score .. ' ' .. Locales["points"])
    HideFreemodeMessage()
    Wait(100)

    if sorted[2] ~= nil then
        camera.changePosition(data.Second.Position, data.First.Position, data.Second.Rotation, 5000)

        ShowFreemodeMessage('', 300, '')
        PlaySoundFrontend(-1, "LOSER", "HUD_AWARDS")
        CamEffect(effectName, 2500, false)
        ShowFreemodeMessage(Locales["2_place"], 4950, '~n~~w~' .. GetPlayerName(GetPlayerFromServerId(sorted[2].id or -1)) .. '~n~~n~' .. sorted[2].score or -1 .. ' ' .. Locales["points"])
        HideFreemodeMessage()
        camera.destroy()
        camera = createCamera('winnerCam', data.Second.Position, data.Second.Rotation)
        Wait(10)
        camera.render()
        Wait(10)
    end
    if sorted[3] ~= nil then
        camera.changePosition(data.Third.Position, data.Second.Position, data.Third.Rotation, 5000)
        camera.destroy()
        camera = createCamera('winnerCam', data.Third.Position, data.Third.Rotation)
        camera.render()
        Wait(10)
        ShowFreemodeMessage('', 300, '')
        PlaySoundFrontend(-1, "LOSER", "HUD_AWARDS")
        CamEffect(effectName, 2500, false)
        ShowFreemodeMessage(Locales["3_place"], 4950, '~n~~w~' .. GetPlayerName(GetPlayerFromServerId(sorted[3].id or -1)) .. '~n~~n~' .. sorted[3].score or -1 .. ' ' .. Locales["points"])
        HideFreemodeMessage()
    end
    if sorted[4] ~= nil then
        camera.changePosition(data.Fourth.Position, data.Third.Position, data.Fourth.Rotation, 5000)
        ShowFreemodeMessage('', 300, '')
        PlaySoundFrontend(-1, "LOSER", "HUD_AWARDS")
        CamEffect(effectName, 2500, false)

        local string = ""
        for i = 4, #sorted do
            string = string .. string.format(Locales["other_position"], GetPlayerName(GetPlayerFromServerId(sorted[i].id)), i, sorted[i].score)
        end

        ShowFreemodeMessage(Locales["others"], 4950, string)
        HideFreemodeMessage()
    end

    DoScreenFadeOut(1500)
    Wait(1500)
    DoScreenFadeIn(1500)
    SetEntityCoords(PlayerPedId(), PrevPos.x, PrevPos.y, PrevPos.z)
    FreezeEntityPosition(PlayerPedId(), false)
    stopRendering()
    disableControls(false)
    TriggerServerEvent("rcore_derby:RemovePlayerFromWorld")
    InCar = false
end)

-- will display player score
-- and count killstreak
RegisterNetEvent("rcore_derby:DisplayScore")
AddEventHandler("rcore_derby:DisplayScore", function()
    if ArenaBusy then
        SendNUIMessage({ type = "addScore", })
        RemoveStreakInSeconds = 5
        CurrentStreak = CurrentStreak + 1
        if CurrentStreak ~= -1 then
            SendNUIMessage({ type = "killFeed", image = CurrentStreak, })
        end
        CamEffect("HeistLocate", 1000, false)
    end
end)

-- when arena start this will get called,
-- it will spawn player vehicle put him inside him
-- and tell show him count down from 3 to 1
RegisterNetEvent("rcore_derby:ArenaStarted")
AddEventHandler("rcore_derby:ArenaStarted", function(data)
    SetDisplay(true)
    StopScreenEffect('DeathFailOut')
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    RespawnPed(ped, coords, 0.0)


    ArenaBusy = true
    SpawnData = data

    DoScreenFadeOut(1500)

    Wait(1500)

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        TaskLeaveVehicle(PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(), false), 16)
    end

    Wait(500)

    local model = GetHashKey(Config.SpawnCarList[math.random(#Config.SpawnCarList)])
    local playerPed = PlayerPedId()
    local heading = data.Heading
    local coords = data.Position
    PrevPos = GetEntityCoords(playerPed)
    FreezeEntityPosition(playerPed, true)
    Wait(1000)
    RequestModel(model)

    while not HasModelLoaded(model) do
        Wait(33)
    end

    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
    Wait(1000)
    FreezeEntityPosition(playerPed, false)
    Wait(1000)
    vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, true)

    FreezeEntityPosition(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 4)

    SetVehicleOnGroundProperly(vehicle)
    SetModelAsNoLongerNeeded(model)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    Wait(500)
    DoScreenFadeIn(1500)
    Wait(1500)
    InCar = true
    local intensity = 0.025 or Config.ShakeIntensity
    local effectName = "HeistLocate" or Config.GameplayCameraEffect
    local shakeEffect = "SMALL_EXPLOSION_SHAKE" or Config.FxEffect

    ShowFreemodeMessage('~g~', 10)
    ShowFreemodeMessage('~g~3', 300)
    _ShakeCam(shakeEffect, intensity)
    CamEffect(effectName, 500, false)
    ShowFreemodeMessage('~g~3', 1500)
    _ShakeCam(shakeEffect, intensity)
    CamEffect(effectName, 1000, false)
    ShowFreemodeMessage('~g~2', 1500)
    _ShakeCam(shakeEffect, intensity)
    CamEffect(effectName, 1000, false)
    ShowFreemodeMessage('~g~1', 1500)
    _ShakeCam(shakeEffect, intensity)
    CamEffect(effectName, 1000, false)

    ShowFreemodeMessage(Locales["start"], 1000)
    AnimpostfxStopAll()
    FreezeEntityPosition(vehicle, false)
    ShowFreemodeMessage(Locales["start"], 1000)
    HideFreemodeMessage()
end)
