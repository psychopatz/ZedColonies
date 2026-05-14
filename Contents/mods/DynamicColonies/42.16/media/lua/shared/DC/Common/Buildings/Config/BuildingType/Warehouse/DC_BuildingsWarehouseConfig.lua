DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}
Config.InstallDefinitions = Config.InstallDefinitions or {}

Config.Definitions.Warehouse = {
    buildingType = "Warehouse",
    displayName = "Warehouse",
    iconPath = "media/ui/Buildings/DC_Warehouse.png",
    enabled = true,
    maxLevel = 2,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 54,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 6 },
                { category = "Hardware", count = 26 },
                { category = "Cloth", count = 4 },
                { category = "Adhesive", count = 1 }
            },
            effects = {
                warehouseBaseBonus = 100
            }
        },
        [2] = {
            enabled = true,
            workPoints = 78,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 8 },
                { category = "Hardware", count = 40 },
                { category = "Cloth", count = 6 },
                { category = "Adhesive", count = 2 }
            },
            effects = {
                warehouseBaseBonus = 100
            }
        }
    }
}

Config.InstallDefinitions.Warehouse = {
    rack = {
        installKey = "rack",
        displayName = "Rack",
        iconPath = "media/ui/Buildings/DC_Warehouse.png",
        requiredLevel = 1,
        maxCount = 10,
        workPoints = 18,
        xpReward = 60,
        recipe = {
            { category = "Wood", count = 2 },
            { category = "Hardware", count = 11 },
            { category = "Cloth", count = 1 }
        },
        effects = {
            warehouseCapacityBonus = 10
        },
        description = "Adds shelving racks to improve storage density inside this Warehouse."
    },
    storage_boxes = {
        installKey = "storage_boxes",
        displayName = "Storage Boxes",
        iconPath = "media/ui/Buildings/DC_Warehouse.png",
        requiredLevel = 2,
        maxCount = 10,
        workPoints = 30,
        xpReward = 90,
        recipe = {
            { category = "Wood", count = 4 },
            { category = "Hardware", count = 20 },
            { category = "Cloth", count = 2 },
            { category = "Adhesive", count = 1 }
        },
        effects = {
            warehouseCapacityBonus = 50
        },
        description = "Adds durable storage boxes for a larger storage jump once the Warehouse reaches level 2."
    }
}
