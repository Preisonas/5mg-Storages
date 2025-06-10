Framework = {}
Framework.Ready = false

function Framework.Init()
    local frameworkConfig = Config.FrameworkSettings[Config.Framework]
    if not frameworkConfig then
        print('^1[5mg-storages] ^7Invalid framework specified in config: ' .. tostring(Config.Framework))
        return false
    end
    local attempts = 0
    while not Framework.Ready and attempts < 100 do
        local success, result = pcall(frameworkConfig.getSharedObject)
        if success and result then
            Framework.Object = result
            Framework.Ready = true
            print('^2[5mg-storages] ^7Framework initialized: ' .. Config.Framework)
            break
        end
        attempts = attempts + 1
        Wait(100)
    end
    if not Framework.Ready then
        print('^1[5mg-storages] ^7Failed to initialize framework: ' .. Config.Framework)
        return false
    end
    return true
end

function Framework.GetPlayer(source)
    if not Framework.Ready or not Framework.Object then return nil end
    if Config.Framework == 'esx' then
        return Framework.Object.GetPlayerFromId(source)
    elseif Config.Framework == 'qbcore' or Config.Framework == 'qbx' then
        return Framework.Object.Functions.GetPlayer(source)
    elseif Config.Framework == 'ox_core' then
        return Framework.Object.GetPlayer(source)
    end
    return nil
end

function Framework.GetPlayerIdentifier(player)
    if not player then return nil end
    if Config.Framework == 'esx' then
        return player.identifier
    elseif Config.Framework == 'qbcore' or Config.Framework == 'qbx' then
        return player.PlayerData.citizenid
    elseif Config.Framework == 'ox_core' then
        return tostring(player.charid)
    end
    return nil
end

function Framework.GetPlayerMoney(player, moneyType)
    if not player then return 0 end
    moneyType = moneyType or Config.FrameworkSettings[Config.Framework].moneyType
    if Config.Framework == 'esx' then
        if moneyType == 'money' or moneyType == 'cash' then
            return player.getMoney()
        elseif moneyType == 'bank' then
            return player.getAccount('bank').money
        end
    elseif Config.Framework == 'qbcore' or Config.Framework == 'qbx' then
        return player.PlayerData.money[moneyType] or 0
    elseif Config.Framework == 'ox_core' then
        return player.get('money') or 0
    end
    return 0
end

function Framework.RemovePlayerMoney(player, amount, moneyType)
    if not player then return false end
    moneyType = moneyType or Config.FrameworkSettings[Config.Framework].moneyType
    if Config.Framework == 'esx' then
        if moneyType == 'money' or moneyType == 'cash' then
            player.removeMoney(amount)
        elseif moneyType == 'bank' then
            player.removeAccountMoney('bank', amount)
        end
        return true
    elseif Config.Framework == 'qbcore' or Config.Framework == 'qbx' then
        return player.Functions.RemoveMoney(moneyType, amount)
    elseif Config.Framework == 'ox_core' then
        return player.remove('money', amount)
    end
    return false
end

function Framework.Notify(source, title, message, type, duration)
    duration = duration or 5000
    if Config.Framework == 'esx' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = title,
            description = message,
            type = type,
            duration = duration
        })
    elseif Config.Framework == 'qbcore' then
        TriggerClientEvent('QBCore:Notify', source, message, type, duration)
    elseif Config.Framework == 'qbx' then
        TriggerClientEvent('qbx_core:notify', source, {
            title = title,
            description = message,
            type = type,
            duration = duration
        })
    elseif Config.Framework == 'ox_core' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = title,
            description = message,
            type = type,
            duration = duration
        })
    end
end

function Framework.RegisterCallback(name, callback)
    if not Framework.Ready or not Framework.Object then 
        print('^1[5mg-storages] ^7Framework not ready for callback registration: ' .. name)
        return 
    end
    if Config.Framework == 'esx' then
        Framework.Object.RegisterServerCallback(name, callback)
    elseif Config.Framework == 'qbcore' then
        Framework.Object.Functions.CreateCallback(name, callback)
    elseif Config.Framework == 'qbx' then
        exports.qbx_core:CreateCallback(name, callback)
    elseif Config.Framework == 'ox_core' then
        exports.ox_core:RegisterCallback(name, callback)
    end
end

function Framework.TriggerCallback(name, callback, ...)
    if not Framework.Ready or not Framework.Object then 
        print('^1[5mg-storages] ^7Framework not ready for callback trigger: ' .. name)
        return 
    end
    if Config.Framework == 'esx' then
        Framework.Object.TriggerServerCallback(name, callback, ...)
    elseif Config.Framework == 'qbcore' then
        Framework.Object.Functions.TriggerCallback(name, callback, ...)
    elseif Config.Framework == 'qbx' then
        exports.qbx_core:TriggerCallback(name, callback, ...)
    elseif Config.Framework == 'ox_core' then
        exports.ox_core:TriggerCallback(name, callback, ...)
    end
end

function Framework.GetPlayerName(source)
    if Config.Framework == 'esx' then
        return GetPlayerName(source)
    elseif Config.Framework == 'qbcore' or Config.Framework == 'qbx' then
        local player = Framework.GetPlayer(source)
        if player then
            return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        end
        return GetPlayerName(source)
    elseif Config.Framework == 'ox_core' then
        local player = Framework.GetPlayer(source)
        if player then
            return player.get('firstName') .. ' ' .. player.get('lastName')
        end
        return GetPlayerName(source)
    end
    return GetPlayerName(source)
end

function Framework.HasPermission(source, permission)
    if not Framework.Ready or not Framework.Object then return false end
    if Config.Framework == 'esx' then
        local player = Framework.GetPlayer(source)
        if player then
            return player.getGroup() == 'admin' or player.getGroup() == 'superadmin'
        end
    elseif Config.Framework == 'qbcore' or Config.Framework == 'qbx' then
        return Framework.Object.Functions.HasPermission(source, permission or 'admin')
    elseif Config.Framework == 'ox_core' then
        local player = Framework.GetPlayer(source)
        if player then
            return player.hasGroup('admin')
        end
    end
    return false
end

if IsDuplicityVersion() then
    CreateThread(function()
        Framework.Init()
    end)
else
    CreateThread(function()
        Framework.Init()
    end)
end