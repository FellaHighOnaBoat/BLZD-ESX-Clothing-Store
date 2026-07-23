local firstSpawn = false
local playerLoaded = false
local nearestStore = nil

isMenuOpen = false
isCreatorOpen = false
cam = nil
camAngle = 0.0
camDistance = 1.8
camHeight = 0.3
savedClothing = nil
savedAppearance = nil
inStore = false
storeType = nil
creatorBucket = false
creatorSubmitCb = nil
creatorCancelCb = nil
currentTattoos = {}

currentHeadBlend = {
    shapeFirst = 0,
    shapeSecond = 0,
    skinFirst = 0,
    skinSecond = 0,
    shapeMix = 0.5,
    skinMix = 0.5
}

CreateThread(function()
    for _, store in ipairs(Config.Stores) do
        local blip = AddBlipForCoord(store.coords.x, store.coords.y, store.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipColour(blip, Config.Blip.colour)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        local found = false

        for _, store in ipairs(Config.Stores) do
            local dist = #(coords - store.coords)
            if dist < store.radius then
                sleep = 0
                found = true
                nearestStore = store
                storeType = 'clothing'
                if not isMenuOpen and not isCreatorOpen then
                    lib.showTextUI('[E] - Clothing Store', { position = 'right-center' })
                    inStore = true
                end
                break
            end
        end

        if not found then
            for _, store in ipairs(Config.TattooStores) do
                local dist = #(coords - store.coords)
                if dist < store.radius then
                    sleep = 0
                    found = true
                    nearestStore = store
                    storeType = 'tattoo'
                    if not isMenuOpen and not isCreatorOpen then
                        lib.showTextUI('[E] - Tattoo Store', { position = 'right-center' })
                        inStore = true
                    end
                    break
                end
            end
        end

        if not found and inStore then
            inStore = false
            nearestStore = nil
            storeType = nil
            lib.hideTextUI()
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if inStore and not isMenuOpen and not isCreatorOpen and IsControlJustReleased(0, 38) then
            if storeType == 'clothing' then
                OpenClothingMenu()
            elseif storeType == 'tattoo' then
                OpenTattooMenu()
            end
        end
    end
end)

AddEventHandler('esx_skin:resetFirstSpawn', function()
    firstSpawn = true
end)

AddEventHandler('esx_skin:playerRegistered', function()
    if firstSpawn then
        firstSpawn = false
        OpenCreator(true)
    end
end)

RegisterNetEvent('esx_skin:openSaveableMenu')
AddEventHandler('esx_skin:openSaveableMenu', function(onSubmit, onCancel)
    OpenCreator(true, onSubmit, onCancel)
end)

RegisterNetEvent('esx_skin:openMenu')
AddEventHandler('esx_skin:openMenu', function(onSubmit, onCancel)
    OpenCreator(false, onSubmit, onCancel)
end)

RegisterNetEvent('esx_skin:openRestrictedMenu')
AddEventHandler('esx_skin:openRestrictedMenu', function(onSubmit, onCancel, restrictedComponents)
    OpenClothingMenu()
end)

AddEventHandler('esx:playerLoaded', function(xPlayer)
    playerLoaded = true

    Wait(500)

    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
        local ped = PlayerPedId()

        if skin and skin ~= false then
            ApplyFullAppearance(ped, skin)
        else
            if not isCreatorOpen then
                SetPedDefaultComponentVariation(ped)
            end
        end

        TriggerEvent('esx_skin:playerLoaded', skin, jobSkin)
    end)
end)

local skinApplied = false

AddEventHandler('esx:playerLoaded', function(xPlayer)
    playerLoaded = true
    skinApplied = false

    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
        local ped = PlayerPedId()

        if skin and skin ~= false then
            ApplyFullAppearance(ped, skin)
            skinApplied = true

            SetTimeout(2000, function()
                skinApplied = false
            end)
        else
            if not isCreatorOpen then
                SetPedDefaultComponentVariation(ped)
            end
        end

        TriggerEvent('esx_skin:playerLoaded', skin, jobSkin)
    end)
end)

RegisterNetEvent('skinchanger:loadSkin')
AddEventHandler('skinchanger:loadSkin', function(skin, cb)
    if skinApplied then
        if cb then cb() end
        return
    end

    local ped = PlayerPedId()
    if skin then
        ApplyFullAppearance(ped, skin)
    end
    if cb then cb() end
end)

AddEventHandler('esx_skin:loadSkin', function(skin, cb)
    if skinApplied then
        if cb then cb() end
        return
    end

    local ped = PlayerPedId()
    if skin then
        ApplyFullAppearance(ped, skin)
    end
    if cb then cb() end
end)

RegisterNetEvent('skinchanger:getSkin', function(cb)
    while not playerLoaded do
        Wait(1000)
    end
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
        if skin and skin ~= false then
            cb(skin)
        else
            cb({})
        end
    end)
end)

RegisterNetEvent('esx_skin:loadSkin')

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if not playerLoaded then return end

    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
        if skin and skin ~= false then
            Wait(1000)
            ApplyFullAppearance(PlayerPedId(), skin)
        end
    end)
end)

CreateThread(function()
    while true do
        Wait(0)
        if isMenuOpen and cam then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 242, true)
            EnableControlAction(0, 243, true)
        end
    end
end)

RegisterNUICallback('rotate', function(data, cb)
    camAngle = camAngle + (data.deltaX or 0) * 0.1
    UpdateCam()
    cb({})
end)

RegisterNUICallback('moveVertical', function(data, cb)
    camHeight = camHeight - (data.deltaY or 0) * 0.001
    camHeight = math.max(-1.0, math.min(camHeight, 0.66))
    UpdateCam()
    cb({})
end)

RegisterNUICallback('zoom', function(data, cb)
    local delta = data.delta or 0
    if delta > 0 then
        camDistance = math.min(camDistance + 0.15, 4.0)
    else
        camDistance = math.max(camDistance - 0.15, 0.5)
    end
    UpdateCam()
    cb({})
end)

RegisterNUICallback('changeModel', function(data, cb)
    local model = data.model == 'female' and Config.Models.female or Config.Models.male
    local hash = LoadModel(model)
    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)

    Wait(100)
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.0, false)

    currentHeadBlend = {
        shapeFirst = 0,
        shapeSecond = 0,
        skinFirst = 0,
        skinSecond = 0,
        shapeMix = 0.5,
        skinMix = 0.5
    }

    local appearance = GetFullAppearance(ped)
    local maxVals = GetMaxValues(ped)
    local gender = data.model == 'female' and 'female' or 'male'

    cb({ appearance = appearance, maxValues = maxVals, tattooData = GetTattooListForNUI(gender) })
end)

RegisterNUICallback('setComponent', function(data, cb)
    local ped = PlayerPedId()
    if data.isProp then
        if data.drawable == -1 then
            ClearPedProp(ped, data.componentId)
        else
            SetPedPropIndex(ped, data.componentId, data.drawable, data.texture, true)
        end
    elseif data.type == 'hair_color' then
        SetPedHairColor(ped, data.value, data.highlight or 0)
    elseif data.type == 'hair_highlight' then
        local hairColor = GetPedHairColor(ped)
        SetPedHairColor(ped, hairColor, data.value)
    else
        SetPedComponentVariation(ped, data.componentId, data.drawable, data.texture, 2)
    end
    cb({})
end)

RegisterNUICallback('setFaceFeature', function(data, cb)
    local ped = PlayerPedId()
    SetPedFaceFeature(ped, data.index, data.value + 0.0)
    cb({})
end)

RegisterNUICallback('setHeadBlend', function(data, cb)
    local ped = PlayerPedId()
    
    local shapeFirst = tonumber(data.shapeFirst) or 0
    local shapeSecond = tonumber(data.shapeSecond) or 0
    local skinFirst = tonumber(data.skinFirst) or 0
    local skinSecond = tonumber(data.skinSecond) or 0
    local shapeMix = (tonumber(data.shapeMix) or 0.5) + 0.0
    local skinMix = (tonumber(data.skinMix) or 0.5) + 0.0
    
    currentHeadBlend = {
        shapeFirst = shapeFirst,
        shapeSecond = shapeSecond,
        skinFirst = skinFirst,
        skinSecond = skinSecond,
        shapeMix = shapeMix,
        skinMix = skinMix
    }
    
    local hasHeadBlend = GetPedHeadBlendData(ped)
    
    if not hasHeadBlend then
        SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
        Wait(0)
    end
    
    SetPedHeadBlendData(ped,
        shapeFirst, shapeSecond, 0,
        skinFirst, skinSecond, 0,
        shapeMix, skinMix, 0.0,
        false
    )
    
    cb({})
end)

RegisterNUICallback('setHeadOverlay', function(data, cb)
    local ped = PlayerPedId()
    local overlayId = data.overlayId
    local index = data.index or 0
    local opacity = (data.opacity or 1.0) + 0.0

    if index == 0 or index == 255 then
        SetPedHeadOverlay(ped, overlayId, 255, 0.0)
    else
        SetPedHeadOverlay(ped, overlayId, index, opacity)
        if data.hasColor then
            local colorType = data.colorType or 1
            local firstColor = data.firstColor or 0
            local secondColor = data.secondColor or 0
            SetPedHeadOverlayColor(ped, overlayId, colorType, firstColor, secondColor)
        end
    end
    cb({})
end)

RegisterNUICallback('setEyeColor', function(data, cb)
    local ped = PlayerPedId()
    SetPedEyeColor(ped, data.value)
    cb({})
end)

RegisterNUICallback('setTattoos', function(data, cb)
    local ped = PlayerPedId()
    ClearPedDecorations(ped)

    local tattoos = data.tattoos or {}
    for _, tattoo in ipairs(tattoos) do
        local collectionHash = GetHashKey(tattoo.collection)
        local nameHash = GetHashKey(tattoo.nameHash)
        AddPedDecorationWithZone(ped, collectionHash, nameHash, tattoo.zone and GetTattooZoneIndex(tattoo.zone) or 0)
    end

    cb({})
end)

RegisterNUICallback('applyTattoos', function(data, cb)
    local ped = PlayerPedId()
    ClearPedDecorations(ped)

    local tattoos = data.tattoos or {}
    currentTattoos = tattoos
    for _, tattoo in ipairs(tattoos) do
        SetPedDecoration(ped, GetHashKey(tattoo.collection), GetHashKey(tattoo.nameHash))
    end

    cb({})
end)

RegisterNUICallback('clearAllTattoos', function(data, cb)
    local ped = PlayerPedId()
    ClearPedDecorations(ped)
    currentTattoos = {}
    cb({})
end)

RegisterNUICallback('previewTattoo', function(data, cb)
    local ped = PlayerPedId()
    ClearPedDecorations(ped)

    local currentTats = data.currentTattoos or {}
    for _, tattoo in ipairs(currentTats) do
        SetPedDecoration(ped, GetHashKey(tattoo.collection), GetHashKey(tattoo.nameHash))
    end

    if data.preview then
        SetPedDecoration(ped, GetHashKey(data.preview.collection), GetHashKey(data.preview.nameHash))
    end

    cb({})
end)

RegisterNUICallback('toggleItem', function(data, cb)
    local ped = PlayerPedId()
    local itemType = data.itemType
    local current = savedClothing or savedAppearance

    if itemType == 'hat' then
        if data.remove then
            ClearPedProp(ped, 0)
        elseif current and current.props and (current.props[0] or current.props['0']) then
            local p = current.props[0] or current.props['0']
            SetPedPropIndex(ped, 0, p.drawable, p.texture, true)
        end
    elseif itemType == 'glasses' then
        if data.remove then
            ClearPedProp(ped, 1)
        elseif current and current.props and (current.props[1] or current.props['1']) then
            local p = current.props[1] or current.props['1']
            SetPedPropIndex(ped, 1, p.drawable, p.texture, true)
        end
    elseif itemType == 'mask' then
        if data.remove then
            SetPedComponentVariation(ped, 1, 0, 0, 2)
        elseif current and current.components and (current.components[1] or current.components['1']) then
            local c = current.components[1] or current.components['1']
            SetPedComponentVariation(ped, 1, c.drawable, c.texture, 2)
        end
    elseif itemType == 'torso' then
        if data.remove then
            SetPedComponentVariation(ped, 11, 15, 0, 2)
            SetPedComponentVariation(ped, 8, 15, 0, 2)
            SetPedComponentVariation(ped, 3, 15, 0, 2)
        elseif current and current.components then
            for _, cid in ipairs({11, 8, 3}) do
                local c = current.components[cid] or current.components[tostring(cid)]
                if c then SetPedComponentVariation(ped, cid, c.drawable, c.texture, 2) end
            end
        end
    elseif itemType == 'pants' then
        if data.remove then
            SetPedComponentVariation(ped, 4, 21, 0, 2)
        elseif current and current.components and (current.components[4] or current.components['4']) then
            local c = current.components[4] or current.components['4']
            SetPedComponentVariation(ped, 4, c.drawable, c.texture, 2)
        end
    elseif itemType == 'shoes' then
        if data.remove then
            SetPedComponentVariation(ped, 6, 34, 0, 2)
        elseif current and current.components and (current.components[6] or current.components['6']) then
            local c = current.components[6] or current.components['6']
            SetPedComponentVariation(ped, 6, c.drawable, c.texture, 2)
        end
    end

    cb({ clothing = GetFullAppearance(ped) })
end)

RegisterNUICallback('close', function(data, cb)
    if data.save and data.tattoos then
        savedTattoos = data.tattoos
    end
    
    if data.save and data.hasToggles then
        local ped = PlayerPedId()
        local current = savedClothing or savedAppearance
        if current then
            ApplyFullAppearance(ped, current)
            Wait(1)
        end
    end
    
    CloseMenu(data.save or false, data.tattoos)
    cb({})
end)

RegisterNUICallback('closeOutfits', function(data, cb)
    isMenuOpen = false
    isCreatorOpen = false
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('saveOutfit', function(data, cb)
    local appearance = GetFullAppearance(PlayerPedId())
    lib.callback('clothing:saveOutfit', false, function(result)
        cb({ success = result })
    end, data.name, appearance)
end)

RegisterNUICallback('loadOutfit', function(data, cb)
    lib.callback('clothing:loadOutfit', false, function(result)
        if result then
            ApplyFullAppearance(PlayerPedId(), result)
            savedClothing = result
            cb({ success = true, clothing = result })
        else
            cb({ success = false })
        end
    end, data.name)
end)

RegisterNUICallback('deleteOutfit', function(data, cb)
    lib.callback('clothing:deleteOutfit', false, function(result)
        cb({ success = result })
    end, data.name)
end)

RegisterNUICallback('getOutfits', function(data, cb)
    lib.callback('clothing:getOutfits', false, function(result)
        cb(result or {})
    end)
end)

RegisterNetEvent('mc-admin:client:openAdminClothing', function()
    isMenuOpen = false
    isCreatorOpen = false
    OpenCreator(false)
end)

exports('GetSkin', GetSkin)

RegisterCommand('debugskin', function()
    local ped = PlayerPedId()
    
    local headBlendResult = {GetPedHeadBlendData(ped)}
    print('--- CURRENT PED BLEND ---')
    print(json.encode(headBlendResult))
    
    lib.callback('clothing:getPlayerAppearance', false, function(appearance)
        print('--- DATABASE APPEARANCE ---')
        if appearance then
            print('headBlend: ' .. json.encode(appearance.headBlend))
            print('tattoos: ' .. json.encode(appearance.tattoos or {}))
        else
            print('No appearance found in database')
        end
    end)
end, false)

RegisterNetEvent('clothing:applyAppearance')
AddEventHandler('clothing:applyAppearance', function(appearance)
    if appearance then
        ApplyFullAppearance(PlayerPedId(), appearance)
    end
end)