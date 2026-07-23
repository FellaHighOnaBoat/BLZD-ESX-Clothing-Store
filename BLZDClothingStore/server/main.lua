local creatorBucketBase = 1000

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    RunMigrations()
end)

function RunMigrations()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `blzd_outfits` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(60) NOT NULL,
            `name` VARCHAR(50) NOT NULL,
            `clothing_data` LONGTEXT NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_outfit` (`identifier`, `name`)
        )
    ]])

    local columnExists = MySQL.scalar.await([[
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'appearance'
    ]])

    if columnExists == 0 then
        MySQL.query.await('ALTER TABLE `users` ADD COLUMN `appearance` LONGTEXT DEFAULT NULL')
    end
end

RegisterNetEvent('clothing:enterCreatorBucket')
AddEventHandler('clothing:enterCreatorBucket', function()
    local src = source
    local bucket = creatorBucketBase + src
    SetPlayerRoutingBucket(src, bucket)
end)

RegisterNetEvent('clothing:leaveCreatorBucket')
AddEventHandler('clothing:leaveCreatorBucket', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
end)

ESX.RegisterServerCallback('esx_skin:getPlayerSkin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false, {})
        return
    end
    local identifier = xPlayer.getIdentifier()
    local result = MySQL.scalar.await('SELECT appearance FROM users WHERE identifier = ?', { identifier })
    if result and result ~= '' then
        local appearance = json.decode(result)
        cb(appearance, {
            skin_male = xPlayer.job and xPlayer.job.skin_male or {},
            skin_female = xPlayer.job and xPlayer.job.skin_female or {}
        })
    else
        cb(false, {
            skin_male = xPlayer.job and xPlayer.job.skin_male or {},
            skin_female = xPlayer.job and xPlayer.job.skin_female or {}
        })
    end
end)

RegisterNetEvent('esx_skin:save')
AddEventHandler('esx_skin:save', function(appearance)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local identifier = xPlayer.getIdentifier()
    local data = json.encode(appearance)
    MySQL.update('UPDATE users SET appearance = ? WHERE identifier = ?', { data, identifier })
end)

lib.callback.register('clothing:saveAppearance', function(source, appearance)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local identifier = xPlayer.getIdentifier()
    local data = json.encode(appearance)
    MySQL.update('UPDATE users SET appearance = ? WHERE identifier = ?', { data, identifier })
    return true
end)

lib.callback.register('clothing:getPlayerAppearance', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    local identifier = xPlayer.getIdentifier()
    local result = MySQL.scalar.await('SELECT appearance FROM users WHERE identifier = ?', { identifier })
    if result and result ~= '' then
        return { appearance = json.decode(result), isNew = false }
    end
    return { appearance = nil, isNew = true }
end)

lib.callback.register('clothing:saveOutfit', function(source, name, clothing)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local identifier = xPlayer.getIdentifier()
    local clothingJson = json.encode(clothing)
    local affected = MySQL.update.await(
        'INSERT INTO blzd_outfits (identifier, name, clothing_data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE clothing_data = ?',
        { identifier, name, clothingJson, clothingJson }
    )
    return affected and affected > 0
end)

lib.callback.register('clothing:loadOutfit', function(source, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    local identifier = xPlayer.getIdentifier()
    local result = MySQL.scalar.await(
        'SELECT clothing_data FROM blzd_outfits WHERE identifier = ? AND name = ?',
        { identifier, name }
    )
    if result then
        local clothing = json.decode(result)
        MySQL.update('UPDATE users SET appearance = ? WHERE identifier = ?', { result, identifier })
        return clothing
    end
    return nil
end)

lib.callback.register('clothing:deleteOutfit', function(source, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local identifier = xPlayer.getIdentifier()
    local affected = MySQL.update.await(
        'DELETE FROM blzd_outfits WHERE identifier = ? AND name = ?',
        { identifier, name }
    )
    return affected and affected > 0
end)

lib.callback.register('clothing:getOutfits', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return {} end
    local identifier = xPlayer.getIdentifier()
    local results = MySQL.query.await(
        'SELECT name, clothing_data, created_at FROM blzd_outfits WHERE identifier = ? ORDER BY created_at DESC',
        { identifier }
    )
    local outfits = {}
    for _, row in ipairs(results or {}) do
        table.insert(outfits, {
            name = row.name,
            clothingData = json.decode(row.clothing_data),
            createdAt = row.created_at
        })
    end
    return outfits
end)

lib.callback.register('clothing:checkAdmin', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local group = xPlayer.getGroup()
    for _, adminGroup in ipairs(Config.AdminGroups) do
        if group == adminGroup then
            return true
        end
    end
    return false
end)

exports('GetPlayerAppearance', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    local identifier = xPlayer.getIdentifier()
    local result = MySQL.scalar.await('SELECT appearance FROM users WHERE identifier = ?', { identifier })
    if result and result ~= '' then
        return json.decode(result)
    end
    return nil
end)

exports('SetPlayerAppearance', function(source, appearance)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local identifier = xPlayer.getIdentifier()
    local data = json.encode(appearance)
    MySQL.update('UPDATE users SET appearance = ? WHERE identifier = ?', { data, identifier })
    TriggerClientEvent('clothing:applyAppearance', source, appearance)
    return true
end)

exports('GetAppearanceByIdentifier', function(identifier)
    local result = MySQL.scalar.await('SELECT appearance FROM users WHERE identifier = ?', { identifier })
    if result and result ~= '' then
        return json.decode(result)
    end
    return nil
end)

RegisterNetEvent('clothing:requestApplyAppearance')
AddEventHandler('clothing:requestApplyAppearance', function()
    local source = source
    local appearance = exports['BLZDClothingStore']:GetPlayerAppearance(source)
    if appearance then
        TriggerClientEvent('clothing:applyAppearance', source, appearance)
    end
end)