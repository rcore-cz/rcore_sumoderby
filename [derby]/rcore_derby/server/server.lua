ArenaHelper = exports.ArenaAPI

local CachedArenas = {}

function deepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end

    return _copy(object)
end

function tableSize(table)
    local size = 0
    for k, v in pairs(table) do
        size = size + 1
    end
    return size
end

function GetHighestScore(table)
    local minNumber = -2147483648
    local array = {}
    for i = 1, tableSize(table) do
        local highest = 0
        local key = -1
        for _key, value in pairs(table) do
            if minNumber < value then
                highest = value
                minNumber = value
                key = _key
            end
        end

        array[i] = { id = key, score = highest }
        table[key] = nil
        minNumber = -2147483648
    end
    return array
end

for k, v in pairs(Config.DerbyArenaNameList) do
    local PosCars = deepCopy(Config.PositionCars)

    local arena = ArenaHelper:CreateArena(v)

    arena.SetMaximumCapacity(#PosCars)
    arena.SetMinimumCapacity(Config.MinimumRequiredPeople)

    arena.SetMaximumLobbyTime(Config.MaxLobbyTime)
    arena.SetMaximumArenaTime(Config.MaxArenaTime)

    arena.SetArenaLabel(Config.ArenaName)

    arena.SetArenaPublic(Config.IsArenaPublic)

    arena.SetOwnWorld(true)

    arena.RemoveWorldAfterWin(false)

    if Config.DisplayJoinMessage then
        arena.OnPlayerJoinLobby(function(source, data)
            ShowMessageToEveryone(source, "join", data)
        end)

        arena.OnPlayerExitLobby(function(source, data)
            ShowMessageToEveryone(source, "leave", data)
        end)
    end

    arena.OnArenaStart(function(data)
        local SpawnData

        for k, v in pairs(arena.GetPlayerList()) do
            for key, value in pairs(PosCars) do
                if not value.Occupied then
                    SpawnData = value
                    value.Occupied = true
                    break
                end
            end
            arena.SetPlayerScore(k, "score", 0)
            TriggerClientEvent("rcore_derby:ArenaStarted", k, SpawnData)
        end
    end)

    arena.OnArenaEnd(function(data)
        local ScoreList = {}
        local SortedList = {}

        for k, v in pairs(arena.GetPlayerList()) do
            ScoreList[k] = arena.GetPlayerScore(k, "score")
        end
        SortedList = GetHighestScore(ScoreList)
        for i = 1, #SortedList do
            Config.GameEnded(SortedList[i].id, i, SortedList[i].score)
        end

        for k, v in pairs(arena.GetPlayerList()) do
            TriggerClientEvent("rcore_derby:ArenaEnded", k, SortedList)
        end

        for k, v in pairs(PosCars) do
            v.Occupied = false
        end
    end)

    table.insert(CachedArenas, arena)
end

RegisterNetEvent("rcore_derby:RemovePlayerFromWorld")
AddEventHandler("rcore_derby:RemovePlayerFromWorld", function()
    SetPlayerRoutingBucket(source, 0)
end)


RegisterNetEvent("rcore_derby:CountLife")
AddEventHandler("rcore_derby:CountLife", function()
    local _source = source
    for k, arena in pairs(CachedArenas) do
        if arena.IsPlayerInArena(_source) then
            if arena.PlayerScoreExists(_source, "HitBy") then
                local target = arena.GetPlayerScore(_source, "HitBy")
                if target ~= _source then
                    arena.GivePlayerScore(target, "score", 100)
                    TriggerClientEvent("rcore_derby:DisplayScore", target, _source)
                    arena.DeleteScore(_source, "HitBy")
                    break
                end
            end
        end
    end
end)

RegisterNetEvent("rcore_derby:SetPlayerHit")
AddEventHandler("rcore_derby:SetPlayerHit", function(playerID)
    local _source = source
    for k, arena in pairs(CachedArenas) do
        if arena.IsPlayerInArena(_source) and arena.IsPlayerInArena(playerID) then
            arena.SetPlayerScore(playerID, "HitBy", _source)
            break
        end
    end
end)