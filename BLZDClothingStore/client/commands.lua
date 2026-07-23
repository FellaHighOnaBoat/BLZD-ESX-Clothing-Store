RegisterCommand('outfits', function()
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openOutfits' })
end, false)

RegisterCommand('adminclothing', function()
    lib.callback('clothing:checkAdmin', false, function(isAdmin)
        if isAdmin then
            isMenuOpen = false
            isCreatorOpen = false
            OpenCreator(false)
        end
    end)
end, false)