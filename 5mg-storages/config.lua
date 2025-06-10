Config = {}

-- Framework Configuration
-- Supported frameworks: 'esx', 'qbcore', 'qbx', 'ox_core'
Config.Framework = 'esx' -- Change this to your framework

-- Framework specific settings
Config.FrameworkSettings = {
    esx = {
        resourceName = 'es_extended',
        getSharedObject = function()
            return exports['es_extended']:getSharedObject()
        end,
        playerIdentifier = 'identifier',
        moneyType = 'money' -- 'money', 'bank', 'cash'
    },
    qbcore = {
        resourceName = 'qb-core',
        getSharedObject = function()
            return exports['qb-core']:GetCoreObject()
        end,
        playerIdentifier = 'citizenid',
        moneyType = 'cash' -- 'cash', 'bank'
    },
    qbx = {
        resourceName = 'qbx_core',
        getSharedObject = function()
            return exports.qbx_core
        end,
        playerIdentifier = 'citizenid',
        moneyType = 'cash' -- 'cash', 'bank'
    },
    ox_core = {
        resourceName = 'ox_core',
        getSharedObject = function()
            return Ox
        end,
        playerIdentifier = 'charid',
        moneyType = 'money' -- 'money'
    }
}

-- Multiple storage locations across Los Santos
Config.StorageLocations = {
    vector4(394.5931, -880.6722, 29.4053, 87.3453),
    vector4(252.3456, -1002.1234, 29.3012, 180.0)
}


Config.StorageLocation = Config.StorageLocations[1]

Config.StorageUnit = {
    price = 1000,
    capacity = 10,
    weight = 50,
    label = "Storage Unit",
    icon = "fas fa-box"
}

Config.UpgradeLevels = {
    {
        level = 1,
        slots = 10,
        weight = 50,
        price = 0
    },
    {
        level = 2,
        slots = 15,
        weight = 100,
        price = 10000
    },
    {
        level = 3,
        slots = 25,
        weight = 200,
        price = 20000
    },
    {
        level = 4,
        slots = 35,
        weight = 300,
        price = 25000
    },
    {
        level = 5,
        slots = 45,
        weight = 400,
        price = 30000
    }
}

Config.Target = {
    radius = 2.0,
    icon = "fas fa-box",
    label = "Access Storage"
}


Config.LocationSettings = {
    enableLocationSpecificPricing = true,
    locationPriceMultipliers = {
        [1] = 1.0,
        [2] = 1.0
    }
}


Config.Blip = {
    sprite = 478,
    display = 4,
    scale = 0.7,
    colour = 5,
    shortRange = true,
    name = "Storage Units"
}

Config.UI = {
    title = "Storage Management",
    theme = "dark"
}

Config.TableName = "5mg_storages"

Config.Stash = {
    prefix = "storage_unit_",
    label = "Storage Unit"
}