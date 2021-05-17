local PlayerJoined = false

local Cached3DText = {}

-- will display a help text on left top screen
function showHelpNotification(text)
    BeginTextCommandDisplayHelp("THREESTRINGS")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, 5000)
end

CreateThread(function()
    Wait(1000)
    for k, v in pairs(Config.MarkerList) do
        local marker = createMarker()

        marker.setType(v.style)

        marker.setPosition(v.pos)
        marker.setScale(v.size)
        marker.setColor(v.color)

        marker.setInRadius(v.size.x / 2)

        marker.setRotation(v.rotate)
        marker.setFaceCamera(v.faceCamera)

        marker.setKeys(Config.KeyListToInteract)

        -- on enter we will check if player is in vehicle if yes show open message of no show deny message.
        marker.on("enter", function()
            showHelpNotification("Push ~INPUT_CONTEXT~ to join to the game lobby")
        end)

        marker.on("leave", function()
            if PlayerJoined then
                ExecuteCommand("minigame leave")
                PlayerJoined = false
            end
        end)

        -- on key event we control if player is in vehicle if yes = open menu, if no = nothing will happen
        marker.on("key", function()
            if not PlayerJoined then
                ExecuteCommand("minigame join " .. k)
                PlayerJoined = true
            end
        end)

        marker.render()
        local arena = exports.ArenaAPI:GetArena(k)
        if arena then
            Cached3DText[k] = create3DText(string.format(v.text, #arena.PlayerList or {}, arena.MaximumCapacity))

            Cached3DText[k].setPosition(v.pos + vector3(0, 0, 3))

            Cached3DText[k].render()
        end
        createBlip(v.blip.name, v.blip.blipId, v.pos, v.blip)
    end
end)

RegisterNetEvent("ArenaAPI:sendStatus")
AddEventHandler("ArenaAPI:sendStatus", function(type, data)
    -- just to make sure the data will get updated first in "ArenaAPI" i will make a dedicated event later for this.
    Wait(1000)
    if Cached3DText[data.ArenaIdentifier] then
        Cached3DText[data.ArenaIdentifier].setText(string.format(Config.MarkerList[data.ArenaIdentifier].text, data.CurrentCapacity, data.MaximumCapacity))
    end
end)