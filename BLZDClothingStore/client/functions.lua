function LoadModel(model)
    local hash = type(model) == 'string' and GetHashKey(model) or model
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    return hash
end

function GetTattooListForNUI(gender)
    local tattoosByZone = {}
    for _, zone in ipairs(Config.Tattoos.zones) do
        tattoosByZone[zone.id] = {}
    end

    for i, tattoo in ipairs(Config.TattooList) do
        local nameHash
        if gender == 'female' then
            nameHash = tattoo.nameHashFemale or tattoo.nameHashMale
        else
            nameHash = tattoo.nameHashMale or tattoo.nameHashFemale
        end

        if nameHash and tattoosByZone[tattoo.zone] then
            table.insert(tattoosByZone[tattoo.zone], {
                index = i,
                collection = tattoo.collection,
                nameHash = nameHash,
                displayName = tattoo.displayName,
                zone = tattoo.zone,
            })
        end
    end

    return {
        zones = Config.Tattoos.zones,
        tattoosByZone = tattoosByZone,
    }
end

function OpenClothingMenu()
    if isMenuOpen then return end
    isMenuOpen = true
    lib.hideTextUI()

    local ped = PlayerPedId()
    savedClothing = GetFullAppearance(ped)

    local appearance = GetFullAppearance(ped)
    local gender = appearance.model or 'male'

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        mode = 'clothing',
        clothingData = appearance,
        maxValues = GetMaxValues(ped),
        tattooData = GetTattooListForNUI(gender),
    })

    CreateEditCam()
end

function OpenTattooMenu()
    if isMenuOpen then return end
    isMenuOpen = true
    lib.hideTextUI()

    local ped = PlayerPedId()
    savedClothing = GetFullAppearance(ped)

    local appearance = GetFullAppearance(ped)
    local gender = appearance.model or 'male'

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        mode = 'tattoo',
        clothingData = appearance,
        maxValues = GetMaxValues(ped),
        tattooData = GetTattooListForNUI(gender),
    })

    CreateEditCam()
end

function OpenCreator(isNew, onSubmit, onCancel)
    if isCreatorOpen then return end
    isCreatorOpen = true
    isMenuOpen = true
    lib.hideTextUI()

    creatorSubmitCb = onSubmit
    creatorCancelCb = onCancel

    if isNew then
        TriggerServerEvent('clothing:enterCreatorBucket')
        creatorBucket = true

        local spawn = Config.CreatorSpawn
        local ped = PlayerPedId()

        SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
        SetEntityHeading(ped, spawn.w)

        Wait(500)

        local interiorId = GetInteriorAtCoords(spawn.x, spawn.y, spawn.z)
        if interiorId ~= 0 then
            LoadInterior(interiorId)
            while not IsInteriorReady(interiorId) do
                Wait(100)
            end
        end

        Wait(500)
    end

    local ped = PlayerPedId()
    savedAppearance = GetFullAppearance(ped)

    local appearance = GetFullAppearance(ped)
    local gender = appearance.model or 'male'

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        mode = 'creator',
        isNew = isNew or false,
        clothingData = appearance,
        maxValues = GetMaxValues(ped),
        tattooData = GetTattooListForNUI(gender),
    })

    CreateEditCam()
end

function RestoreToggledItems(ped)
    local current = savedClothing or savedAppearance
    if not current then return end

    ApplyFullAppearance(ped, current)
end


function CloseMenu(save)
    if not isMenuOpen then return end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    local wasCreator = isCreatorOpen
    local wasNew = creatorBucket

    if not save then
        if wasCreator and savedAppearance then
            ApplyFullAppearance(PlayerPedId(), savedAppearance)
        elseif savedClothing then
            ApplyFullAppearance(PlayerPedId(), savedClothing)
        end
    end

    if save then
        local appearance = GetFullAppearance(PlayerPedId())
        lib.callback('clothing:saveAppearance', false, function(result) end, appearance)
        TriggerServerEvent('esx_skin:save', appearance)

        if wasCreator and creatorSubmitCb then
            creatorSubmitCb(appearance)
        end
    else
        if wasCreator and creatorCancelCb then
            creatorCancelCb()
        end
    end

    if wasNew and save then
        if cam then
            SetCamActive(cam, false)
            RenderScriptCams(false, false, 0, true, false)
            DestroyCam(cam, false)
            cam = nil
        end

        local ped = PlayerPedId()
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)

        local dest = Config.AfterCreatorSpawn

        DoScreenFadeOut(0)

        SetEntityCoords(ped, dest.x, dest.y, dest.z, false, false, false, true)
        SetEntityHeading(ped, dest.w)

        TriggerServerEvent('clothing:leaveCreatorBucket')
        creatorBucket = false

        CreateThread(function()
            Wait(1000)
            SetEntityCoords(PlayerPedId(), dest.x, dest.y, dest.z, false, false, false, true)
            SetEntityHeading(PlayerPedId(), dest.w)
            Wait(500)
            DoScreenFadeIn(500)
        end)
    elseif wasNew and not save then
        DestroyEditCam()
        return
    else
        DestroyEditCam()
    end

    isMenuOpen = false
    isCreatorOpen = false
    savedClothing = nil
    savedAppearance = nil
    creatorSubmitCb = nil
    creatorCancelCb = nil

    if inStore then
        lib.showTextUI('[E] - Clothing Store', { position = 'right-center' })
    end
end

function CreateEditCam()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    local camX = coords.x + camDistance * math.cos(math.rad(camAngle))
    local camY = coords.y + camDistance * math.sin(math.rad(camAngle))
    local camZ = coords.z + camHeight

    SetCamCoord(cam, camX, camY, camZ)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z + camHeight)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, false)
    FreezeEntityPosition(ped, true)
    TaskStandStill(ped, -1)
end

function DestroyEditCam()
    if cam then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(cam, false)
        cam = nil
        FreezeEntityPosition(PlayerPedId(), false)
        ClearPedTasks(PlayerPedId())
    end
end

function UpdateCam()
    if not cam then return end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local camX = coords.x + camDistance * math.cos(math.rad(camAngle))
    local camY = coords.y + camDistance * math.sin(math.rad(camAngle))
    local camZ = coords.z + camHeight

    SetCamCoord(cam, camX, camY, camZ)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z + camHeight)
end

function GetTattooZoneIndex(zone)
    local zones = { head = 0, torso = 1, left_arm = 2, right_arm = 3, left_leg = 4, right_leg = 5 }
    return zones[zone] or 0
end

function GetFullAppearance(ped)
    local appearance = {
        model = GetEntityModel(ped) == GetHashKey(Config.Models.female) and 'female' or 'male',
        components = {},
        props = {},
        hairColor = GetPedHairColor(ped),
        hairHighlight = GetPedHairHighlightColor(ped),
        faceFeatures = {},
        headOverlays = {},
        eyeColor = GetPedEyeColor(ped),
        headBlend = {}
    }

    for i = 0, 11 do
        appearance.components[i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i)
        }
    end

    for i = 0, 7 do
        appearance.props[i] = {
            drawable = GetPedPropIndex(ped, i),
            texture = GetPedPropTextureIndex(ped, i)
        }
    end

    for i = 0, 19 do
        appearance.faceFeatures[i] = GetPedFaceFeature(ped, i)
    end

    for i = 0, 12 do
        local success, value, colorType, firstColor, secondColor, opacity = GetPedHeadOverlayData(ped, i)
        if success then
            appearance.headOverlays[i] = {
                index = value,
                opacity = (opacity or 1.0) + 0.0,
                colorType = colorType or 0,
                firstColor = firstColor or 0,
                secondColor = secondColor or 0
            }
        else
            appearance.headOverlays[i] = {
                index = 255,
                opacity = 1.0,
                colorType = 0,
                firstColor = 0,
                secondColor = 0
            }
        end
    end

    appearance.headBlend = {
        shapeFirst = currentHeadBlend.shapeFirst,
        shapeSecond = currentHeadBlend.shapeSecond,
        skinFirst = currentHeadBlend.skinFirst,
        skinSecond = currentHeadBlend.skinSecond,
        shapeMix = currentHeadBlend.shapeMix + 0.0,
        skinMix = currentHeadBlend.skinMix + 0.0
    }

    return appearance
end

function ApplyFullAppearance(ped, appearance)
    if not appearance then return end

    if appearance.model then
        local entityModel = GetEntityModel(ped)
        local maleHash = GetHashKey(Config.Models.male)
        local femaleHash = GetHashKey(Config.Models.female)
        
        local needsModelChange = false
        
        if appearance.model == 'female' and entityModel ~= femaleHash then
            needsModelChange = true
        elseif appearance.model == 'male' and entityModel ~= maleHash then
            needsModelChange = true
        end
        
        if needsModelChange then
            local model = appearance.model == 'female' and Config.Models.female or Config.Models.male
            local hash = LoadModel(model)
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
            Wait(100)
            ped = PlayerPedId()
        end
    end

    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
    Wait(0)
    
    if appearance.headBlend then
        local hb = appearance.headBlend
        local shapeFirst = tonumber(hb.shapeFirst) or 0
        local shapeSecond = tonumber(hb.shapeSecond) or 0
        local skinFirst = tonumber(hb.skinFirst) or 0
        local skinSecond = tonumber(hb.skinSecond) or 0
        local shapeMix = (tonumber(hb.shapeMix) or 0.5) + 0.0
        local skinMix = (tonumber(hb.skinMix) or 0.5) + 0.0
        
        currentHeadBlend = {
            shapeFirst = shapeFirst,
            shapeSecond = shapeSecond,
            skinFirst = skinFirst,
            skinSecond = skinSecond,
            shapeMix = shapeMix,
            skinMix = skinMix
        }
        
        SetPedHeadBlendData(ped,
            shapeFirst, shapeSecond, 0,
            skinFirst, skinSecond, 0,
            shapeMix, skinMix, 0.0,
            false
        )
    end

    if appearance.faceFeatures then
        for i = 0, 19 do
            local val = appearance.faceFeatures[i] or appearance.faceFeatures[tostring(i)] or 0.0
            SetPedFaceFeature(ped, i, val + 0.0)
        end
    end

    if appearance.components then
        for i = 0, 11 do
            local comp = appearance.components[i] or appearance.components[tostring(i)]
            if comp then
                SetPedComponentVariation(ped, i, comp.drawable or 0, comp.texture or 0, 2)
            end
        end
    end

    if appearance.props then
        for i = 0, 7 do
            local prop = appearance.props[i] or appearance.props[tostring(i)]
            if prop then
                if prop.drawable == -1 then
                    ClearPedProp(ped, i)
                else
                    SetPedPropIndex(ped, i, prop.drawable or 0, prop.texture or 0, true)
                end
            end
        end
    end

    if appearance.hairColor then
        SetPedHairColor(ped, appearance.hairColor, appearance.hairHighlight or 0)
    end

    if appearance.headOverlays then
        for i = 0, 12 do
            local overlay = appearance.headOverlays[i] or appearance.headOverlays[tostring(i)]
            if overlay then
                if overlay.index == 255 then
                    SetPedHeadOverlay(ped, i, 255, 0.0)
                else
                    SetPedHeadOverlay(ped, i, overlay.index, (overlay.opacity or 1.0) + 0.0)
                    SetPedHeadOverlayColor(ped, i, overlay.colorType or 0, overlay.firstColor or 0, overlay.secondColor or 0)
                end
            end
        end
    end

    if appearance.eyeColor and appearance.eyeColor >= 0 then
        SetPedEyeColor(ped, appearance.eyeColor)
    end

    ClearPedDecorations(ped)
    if appearance.tattoos and #appearance.tattoos > 0 then
        currentTattoos = appearance.tattoos
        for _, tattoo in ipairs(appearance.tattoos) do
            SetPedDecoration(ped, GetHashKey(tattoo.collection), GetHashKey(tattoo.nameHash))
        end
    else
        currentTattoos = {}
    end
end

function ApplyFullAppearance(ped, appearance)
    if not appearance then return end

    if appearance.model then
        local entityModel = GetEntityModel(ped)
        local maleHash = GetHashKey(Config.Models.male)
        local femaleHash = GetHashKey(Config.Models.female)
        
        local needsModelChange = false
        
        if appearance.model == 'female' and entityModel ~= femaleHash then
            needsModelChange = true
        elseif appearance.model == 'male' and entityModel ~= maleHash then
            needsModelChange = true
        end
        
        if needsModelChange then
            local model = appearance.model == 'female' and Config.Models.female or Config.Models.male
            local hash = LoadModel(model)
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
            Wait(100)
            ped = PlayerPedId()
        end
    end

    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
    Wait(0)
    
    if appearance.headBlend then
        local hb = appearance.headBlend
        local shapeFirst = tonumber(hb.shapeFirst) or 0
        local shapeSecond = tonumber(hb.shapeSecond) or 0
        local skinFirst = tonumber(hb.skinFirst) or 0
        local skinSecond = tonumber(hb.skinSecond) or 0
        local shapeMix = (tonumber(hb.shapeMix) or 0.5) + 0.0
        local skinMix = (tonumber(hb.skinMix) or 0.5) + 0.0
        
        currentHeadBlend = {
            shapeFirst = shapeFirst,
            shapeSecond = shapeSecond,
            skinFirst = skinFirst,
            skinSecond = skinSecond,
            shapeMix = shapeMix,
            skinMix = skinMix
        }
        
        SetPedHeadBlendData(ped,
            shapeFirst, shapeSecond, 0,
            skinFirst, skinSecond, 0,
            shapeMix, skinMix, 0.0,
            false
        )
    end

    if appearance.faceFeatures then
        for i = 0, 19 do
            local val = appearance.faceFeatures[i] or appearance.faceFeatures[tostring(i)] or 0.0
            SetPedFaceFeature(ped, i, val + 0.0)
        end
    end

    if appearance.components then
        for i = 0, 11 do
            local comp = appearance.components[i] or appearance.components[tostring(i)]
            if comp then
                SetPedComponentVariation(ped, i, comp.drawable or 0, comp.texture or 0, 2)
            end
        end
    end

    if appearance.props then
        for i = 0, 7 do
            local prop = appearance.props[i] or appearance.props[tostring(i)]
            if prop then
                if prop.drawable == -1 then
                    ClearPedProp(ped, i)
                else
                    SetPedPropIndex(ped, i, prop.drawable or 0, prop.texture or 0, true)
                end
            end
        end
    end

    if appearance.hairColor then
        SetPedHairColor(ped, appearance.hairColor, appearance.hairHighlight or 0)
    end

    if appearance.headOverlays then
        for i = 0, 12 do
            local overlay = appearance.headOverlays[i] or appearance.headOverlays[tostring(i)]
            if overlay then
                if overlay.index == 255 then
                    SetPedHeadOverlay(ped, i, 255, 0.0)
                else
                    SetPedHeadOverlay(ped, i, overlay.index, (overlay.opacity or 1.0) + 0.0)
                    SetPedHeadOverlayColor(ped, i, overlay.colorType or 0, overlay.firstColor or 0, overlay.secondColor or 0)
                end
            end
        end
    end

    if appearance.eyeColor and appearance.eyeColor >= 0 then
        SetPedEyeColor(ped, appearance.eyeColor)
    end

    ClearPedDecorations(ped)
    if appearance.tattoos and #appearance.tattoos > 0 then
        for _, tattoo in ipairs(appearance.tattoos) do
            SetPedDecoration(ped, GetHashKey(tattoo.collection), GetHashKey(tattoo.nameHash))
        end
    end
end

function GetMaxValues(ped)
    local maxValues = {
        components = {},
        props = {}
    }

    for i = 0, 11 do
        maxValues.components[i] = {
            maxDrawable = GetNumberOfPedDrawableVariations(ped, i) - 1,
            maxTexture = {}
        }
        for d = 0, maxValues.components[i].maxDrawable do
            maxValues.components[i].maxTexture[d] = GetNumberOfPedTextureVariations(ped, i, d) - 1
        end
    end

    for i = 0, 7 do
        maxValues.props[i] = {
            maxDrawable = GetNumberOfPedPropDrawableVariations(ped, i) - 1,
            maxTexture = {}
        }
        for d = 0, maxValues.props[i].maxDrawable do
            maxValues.props[i].maxTexture[d] = GetNumberOfPedPropTextureVariations(ped, i, d) - 1
        end
    end

    maxValues.maxHairColors = GetNumHairColors() - 1
    maxValues.maxMakeupColors = 63
    maxValues.maxParents = Config.MaxParents
    maxValues.maxEyeColors = Config.MaxEyeColors

    maxValues.headOverlays = {}
    for i = 0, 12 do
        maxValues.headOverlays[i] = GetPedHeadOverlayNum(i) - 1
    end

    return maxValues
end

function GetSkin()
    return GetFullAppearance(PlayerPedId())
end
