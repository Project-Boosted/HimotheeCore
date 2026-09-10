local currentCharacter = nil

RegisterNetEvent('himo_core:client:characterLoaded', function(character)
    currentCharacter = character
    LocalPlayer.state:set('himoCharacterLoaded', true, false)

    if HimoConfig.Debug then
        print(('[HimotheeCore] Character loaded: %s %s (%s)'):format(
            character.first_name,
            character.last_name,
            character.citizen_id
        ))
    end
end)

RegisterNetEvent('himo_core:client:characterUnloaded', function()
    currentCharacter = nil
    LocalPlayer.state:set('himoCharacterLoaded', false, false)
end)

exports('GetCharacter', function()
    return currentCharacter
end)
