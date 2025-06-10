CreateThread(function()
    while not Framework.Ready do
        Wait(100)
    end
    print('^2[5mg-storages] ^7Server framework ready: ' .. Config.Framework)
    RegisterFrameworkCallbacks()
end)

function RegisterFrameworkCallbacks()
    Framework.RegisterCallback('5mg-storages:server:checkOwnership', function(source, cb)
        local player = Framework.GetPlayer(source)
        local identifier = Framework.GetPlayerIdentifier(player)
        if not identifier then
            cb(false, nil)
            return
        end
        MySQL.Async.fetchAll('SELECT * FROM `'..Config.TableName..'` WHERE `owner` = ?', {
            identifier
        }, function(result)
            if result and #result > 0 then
                cb(true, result[1])
            else
                cb(false, nil)
            end
        end)
    end)

    Framework.RegisterCallback('5mg-storages:server:getStorageUnits', function(source, cb)
        local player = Framework.GetPlayer(source)
        local identifier = Framework.GetPlayerIdentifier(player)
        if not player or not identifier then
            cb({}, "Player not found")
            return
        end
        MySQL.Async.fetchAll('SELECT * FROM `'..Config.TableName..'` WHERE `owner` = ?', {
            identifier
        }, function(result)
            if result and #result > 0 then
                for i, unit in ipairs(result) do
                    if not unit.stash_id or unit.stash_id == "" then
                        local stashId = GenerateStashId(identifier)
                        MySQL.Async.execute('UPDATE `'..Config.TableName..'` SET `stash_id` = ? WHERE `id` = ?', {
                            stashId,
                            unit.id
                        })
                        result[i].stash_id = stashId
                    end
                    result[i].stashId = result[i].stash_id
                end
                cb(result)
            else
                cb({})
            end
        end)
    end)
end


MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `]]..Config.TableName..[[` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `owner` varchar(60) DEFAULT NULL,
            `label` varchar(50) DEFAULT 'Storage Unit',
            `capacity` int(11) DEFAULT 10,
            `weight` int(11) DEFAULT 10,
            `level` int(11) DEFAULT 1,
            `icon` varchar(50) DEFAULT 'fas fa-box',
            `shared_access` longtext DEFAULT NULL,
            PRIMARY KEY (`id`)
        )
    ]], {}, function(rowsChanged)
        print('^2[5mg-storages] ^7Database table initialized')
        

        MySQL.Async.fetchAll([[
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = ?
            AND COLUMN_NAME = 'stash_id'
        ]], {Config.TableName}, function(result)
            if result and #result == 0 then
                MySQL.Async.execute([[
                    ALTER TABLE `]]..Config.TableName..[[`
                    ADD COLUMN `stash_id` varchar(100) DEFAULT NULL
                ]], {}, function(rowsChanged)
                    print('^2[5mg-storages] ^7Added stash_id column to database table')
                end)
            else
                MySQL.Async.execute([[
                    ALTER TABLE `]]..Config.TableName..[[`
                    MODIFY COLUMN `stash_id` varchar(100) DEFAULT NULL
                ]], {}, function(rowsChanged)
                    print('^2[5mg-storages] ^7Updated stash_id column size')
                end)
            end
        end)
    end)
end)

function GenerateStashId(identifier)
    local shortId = string.sub(identifier:gsub(":", "_"), -10)
    local randomNum = math.random(1000, 9999)
    return Config.Stash.prefix .. shortId .. "_" .. randomNum
end

function GetNextUpgradeLevel(currentLevel)
    for i, level in ipairs(Config.UpgradeLevels) do
        if level.level == currentLevel + 1 then
            return level
        end
    end
    return nil
end



RegisterNetEvent('5mg-storages:server:upgradeStorage')
AddEventHandler('5mg-storages:server:upgradeStorage', function(stashId)
    local src = source
    local player = Framework.GetPlayer(src)
    local identifier = Framework.GetPlayerIdentifier(player)
    
    if not player or not identifier then
        Framework.Notify(src, 'Error', 'Player not found', 'error')
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM `'..Config.TableName..'` WHERE `stash_id` = ? AND `owner` = ?', {
        stashId,
        identifier
    }, function(result)
        if result and #result > 0 then
            local storageData = result[1]
            local currentLevel = storageData.level or 1
            local nextLevel = GetNextUpgradeLevel(currentLevel)
            
            if nextLevel then
                local playerMoney = Framework.GetPlayerMoney(player)
                if playerMoney >= nextLevel.price then
                    Framework.RemovePlayerMoney(player, nextLevel.price)
                    
                    MySQL.Async.execute('UPDATE `'..Config.TableName..'` SET `capacity` = ?, `weight` = ?, `level` = ? WHERE `stash_id` = ?', {
                        nextLevel.slots,
                        nextLevel.weight,
                        nextLevel.level,
                        stashId
                    }, function(rowsChanged)
                        if rowsChanged > 0 then
                            exports.ox_inventory:RegisterStash(stashId, storageData.label, nextLevel.slots, nextLevel.weight * 1000, identifier)
                            
                            Framework.Notify(src, 'Storage Upgraded', 'Storage upgraded to level ' .. nextLevel.level .. ' (' .. nextLevel.slots .. ' slots, ' .. nextLevel.weight .. 'kg)', 'success')
                            
                            TriggerClientEvent('5mg-storages:client:refreshStorageUI', src)
                        end
                    end)
                else
                    Framework.Notify(src, 'Insufficient Funds', 'You need $' .. nextLevel.price .. ' to upgrade your storage', 'error')
                end
            else
                Framework.Notify(src, 'Maximum Level', 'Your storage is already at maximum level', 'error')
            end
        else
            Framework.Notify(src, 'Error', 'You do not own this storage unit', 'error')
        end
    end)
end)

RegisterNetEvent('5mg-storages:server:purchaseStorage')
AddEventHandler('5mg-storages:server:purchaseStorage', function(label, icon, locationIndex)
    local src = source
    local player = Framework.GetPlayer(src)
    local identifier = Framework.GetPlayerIdentifier(player)
    
    if not player or not identifier then
        Framework.Notify(src, 'Error', 'Player not found', 'error')
        return
    end
    
    local price = Config.StorageUnit.price
    if Config.LocationSettings.enableLocationSpecificPricing and locationIndex and Config.LocationSettings.locationPriceMultipliers[locationIndex] then
        price = math.floor(Config.StorageUnit.price * Config.LocationSettings.locationPriceMultipliers[locationIndex])
    end
    
    local playerMoney = Framework.GetPlayerMoney(player)
    if playerMoney >= price then
        Framework.RemovePlayerMoney(player, price)
        
        local stashId = GenerateStashId(identifier)
        local initialLevel = Config.UpgradeLevels[1]
        
        MySQL.Async.execute('INSERT INTO `'..Config.TableName..'` (`owner`, `stash_id`, `label`, `capacity`, `weight`, `level`, `icon`, `shared_access`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            identifier,
            stashId,
            label or Config.StorageUnit.label,
            initialLevel.slots,
            initialLevel.weight,
            initialLevel.level,
            icon or Config.StorageUnit.icon,
            json.encode({})
        }, function(rowsChanged)
            if rowsChanged > 0 then
                exports.ox_inventory:RegisterStash(stashId, label or Config.StorageUnit.label, initialLevel.slots, initialLevel.weight * 1000, identifier)
                
                Framework.Notify(src, 'Storage Purchased', 'You purchased a new storage unit for $' .. price, 'success')
                
                TriggerClientEvent('5mg-storages:client:refreshStorageUI', src)
            end
        end)
    else
        Framework.Notify(src, 'Insufficient Funds', 'You need $' .. price .. ' to purchase a storage unit', 'error')
    end
end)


RegisterNetEvent('5mg-storages:server:openStorage')
AddEventHandler('5mg-storages:server:openStorage', function(stashId)
    local src = source
    local player = Framework.GetPlayer(src)
    
    if not stashId then
        print("^1[5mg-storages] Error: No stash ID provided")
        Framework.Notify(src, 'Error', 'Storage ID not found', 'error')
        return
    end
    
    print("^2[5mg-storages] Opening storage with stash ID: " .. stashId)
    

    MySQL.Async.fetchAll('SELECT * FROM `'..Config.TableName..'` WHERE `stash_id` = ?', {stashId}, function(result)
        if result and #result > 0 then
            local storage = result[1]
            local label = storage.label or "Storage Unit"
            local slots = storage.capacity or Config.StorageUnit.capacity
            local weight = storage.weight or Config.StorageUnit.weight
            

            exports.ox_inventory:RegisterStash(stashId, label, slots, weight * 1000, nil)
            TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashId)
            
            print("^2[5mg-storages] Opened inventory for player " .. Framework.GetPlayerName(src))
        else
            print("^1[5mg-storages] Storage not found in database: " .. stashId)
            Framework.Notify(src, 'Error', 'Storage not found in database', 'error')
        end
    end)
end)


RegisterNetEvent('5mg-storages:server:openStorageManagement')
AddEventHandler('5mg-storages:server:openStorageManagement', function(stashId)
    local src = source
    local player = Framework.GetPlayer(src)
    local identifier = Framework.GetPlayerIdentifier(player)
    
    if not player or not identifier then
        Framework.Notify(src, 'Error', 'Player not found', 'error')
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM `'..Config.TableName..'` WHERE `stash_id` = ? AND `owner` = ?', {
        stashId,
        identifier
    }, function(result)
        if result and #result > 0 then
            local storageData = result[1]
            local currentLevel = storageData.level or 1
            local nextLevel = GetNextUpgradeLevel(currentLevel)
            
            TriggerClientEvent('5mg-storages:client:openStorageManagement', src, {
                stashId = stashId,
                label = storageData.label,
                icon = storageData.icon,
                capacity = storageData.capacity,
                weight = storageData.weight,
                level = currentLevel,
                nextLevel = nextLevel,
                sharedAccess = json.decode(storageData.shared_access or '[]')
            })
        else
            Framework.Notify(src, 'Error', 'You do not own this storage unit', 'error')
        end
    end)
end)


RegisterNetEvent('5mg-storages:server:renameStorage')
AddEventHandler('5mg-storages:server:renameStorage', function(stashId, newLabel)
    local src = source
    local player = Framework.GetPlayer(src)
    local identifier = Framework.GetPlayerIdentifier(player)
    
    if not player or not identifier then
        Framework.Notify(src, 'Error', 'Player not found', 'error')
        return
    end
    

    MySQL.Async.execute('UPDATE `'..Config.TableName..'` SET `label` = ? WHERE `stash_id` = ? AND `owner` = ?', {
        newLabel,
        stashId,
        identifier
    }, function(rowsChanged)
        if rowsChanged > 0 then
            Framework.Notify(src, 'Storage Unit', 'Storage unit renamed to ' .. newLabel, 'success')
            

            TriggerClientEvent('5mg-storages:client:refreshStorageUI', src)
        else
            Framework.Notify(src, 'Error', 'Failed to rename storage unit', 'error')
        end
    end)
end)


RegisterNetEvent('5mg-storages:server:changeIcon')
AddEventHandler('5mg-storages:server:changeIcon', function(stashId, icon)
    local src = source
    local player = Framework.GetPlayer(src)
    local identifier = Framework.GetPlayerIdentifier(player)
    
    if not player or not identifier then
        Framework.Notify(src, 'Error', 'Player not found', 'error')
        return
    end
    

    MySQL.Async.execute('UPDATE `'..Config.TableName..'` SET `icon` = ? WHERE `stash_id` = ? AND `owner` = ?', {
        icon,
        stashId,
        identifier
    }, function(rowsChanged)
        if rowsChanged > 0 then
            Framework.Notify(src, 'Storage Unit', 'Storage icon updated successfully', 'success')
            

            TriggerClientEvent('5mg-storages:client:refreshStorageUI', src)
        else
            Framework.Notify(src, 'Error', 'Failed to update storage icon', 'error')
        end
    end)
end)


RegisterNetEvent('5mg-storages:server:shareAccess')
AddEventHandler('5mg-storages:server:shareAccess', function(stashId, playerId)
    local src = source
    local player = Framework.GetPlayer(src)
    local identifier = Framework.GetPlayerIdentifier(player)
    local targetPlayer = Framework.GetPlayer(playerId)
    local targetIdentifier = Framework.GetPlayerIdentifier(targetPlayer)
    
    if not player or not identifier then
        Framework.Notify(src, 'Error', 'Player not found', 'error')
        return
    end
    
    if not targetPlayer or not targetIdentifier then
        Framework.Notify(src, 'Error', 'Target player not found', 'error')
        
        TriggerClientEvent('5mg-storages:client:shareAccessResponse', src, {
            success = false,
            message = 'Target player not found'
        })
        return
    end
    

    MySQL.Async.fetchAll('SELECT * FROM `'..Config.TableName..'` WHERE `stash_id` = ? AND `owner` = ?', {
        stashId,
        identifier
    }, function(result)
        if result and #result > 0 then
            local storageData = result[1]
            local sharedAccess = json.decode(storageData.shared_access or '{}')
            

            local hasAccess = false
            for _, access in pairs(sharedAccess) do
                if access.identifier == targetIdentifier then
                    hasAccess = true
                    break
                end
            end
            
            if not hasAccess then

                table.insert(sharedAccess, {
                    identifier = targetIdentifier,
                    name = Framework.GetPlayerName(playerId)
                })
                

                MySQL.Async.execute('UPDATE `'..Config.TableName..'` SET `shared_access` = ? WHERE `stash_id` = ?', {
                    json.encode(sharedAccess),
                    stashId
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        Framework.Notify(src, 'Storage', 'Access granted to player ' .. Framework.GetPlayerName(playerId), 'success')
                        

                        TriggerClientEvent('5mg-storages:client:shareAccessResponse', src, {
                            success = true,
                            message = 'Access granted to player ' .. Framework.GetPlayerName(playerId)
                        })
                        

                        TriggerClientEvent('5mg-storages:client:updateSharedAccess', src, stashId, sharedAccess)
                    else
                        Framework.Notify(src, 'Error', 'Failed to share access', 'error')
                    end
                end)
            else
                Framework.Notify(src, 'Error', 'Player already has access to this storage', 'error')
            end
        else
            Framework.Notify(src, 'Error', 'You do not own this storage unit', 'error')
        end
    end)
end)


RegisterNetEvent('5mg-storages:server:removeAccess')
AddEventHandler('5mg-storages:server:removeAccess', function(stashId, targetIdentifier)
    local src = source
    local player = Framework.GetPlayer(src)
    local identifier = Framework.GetPlayerIdentifier(player)
    
    if not player or not identifier then
        Framework.Notify(src, 'Error', 'Player not found', 'error')
        return
    end
    

    MySQL.Async.fetchAll('SELECT * FROM `'..Config.TableName..'` WHERE `stash_id` = ? AND `owner` = ?', {
        stashId,
        identifier
    }, function(result)
        if result and #result > 0 then
            local storageData = result[1]
            local sharedAccess = json.decode(storageData.shared_access or '{}')
            

            local newSharedAccess = {}
            local removed = false
            for _, access in pairs(sharedAccess) do
                if access.identifier ~= targetIdentifier then
                    table.insert(newSharedAccess, access)
                else
                    removed = true
                end
            end
            
            if removed then

                MySQL.Async.execute('UPDATE `'..Config.TableName..'` SET `shared_access` = ? WHERE `stash_id` = ?', {
                    json.encode(newSharedAccess),
                    stashId
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        Framework.Notify(src, 'Storage Unit', 'Access removed successfully', 'success')
                        

                        TriggerClientEvent('5mg-storages:client:updateSharedAccess', src, stashId, newSharedAccess)
                    else
                        Framework.Notify(src, 'Error', 'Failed to remove access', 'error')
                    end
                end)
            else
                Framework.Notify(src, 'Error', 'Player does not have access to this storage', 'error')
            end
        else
            Framework.Notify(src, 'Error', 'You do not own this storage unit', 'error')
        end
    end)
end)


RegisterNetEvent('5mg-storages:server:getSharedAccess')
AddEventHandler('5mg-storages:server:getSharedAccess', function(stashId)
    local src = source
    local player = Framework.GetPlayer(src)
    local identifier = Framework.GetPlayerIdentifier(player)
    
    if not player or not identifier then
        Framework.Notify(src, 'Error', 'Player not found', 'error')
        return
    end
    

    MySQL.Async.fetchAll('SELECT * FROM `'..Config.TableName..'` WHERE `stash_id` = ? AND `owner` = ?', {
        stashId,
        identifier
    }, function(result)
        if result and #result > 0 then
            local storageData = result[1]
            local sharedAccess = json.decode(storageData.shared_access or '{}')
            

            TriggerClientEvent('5mg-storages:client:updateSharedAccess', src, stashId, sharedAccess)
        else
            Framework.Notify(src, 'Error', 'You do not own this storage unit', 'error')
        end
    end)
end)
function GetNextUpgradeLevel(currentLevel)
    for i, level in ipairs(Config.UpgradeLevels) do
        if level.level > currentLevel then
            return level
        end
    end
    return nil
end