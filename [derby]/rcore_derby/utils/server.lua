function ShowMessageToEveryone(source, locale, data)
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 255, 255, 255 },
        multiline = true,
        args = { "["..data.ArenaLabel.."]", string.format(Locales[locale], GetPlayerName(source) , data.ArenaLabel , data.CurrentCapacity , data.MaximumCapacity)}
    })
end