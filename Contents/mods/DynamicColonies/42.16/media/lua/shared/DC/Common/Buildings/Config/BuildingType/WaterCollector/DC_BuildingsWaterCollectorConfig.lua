DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}
Config.InstallDefinitions = Config.InstallDefinitions or {}

Config.Definitions.WaterCollector = {
    buildingType = "WaterCollector",
    displayName = "Water Collector",
    iconPath = "media/ui/Buildings/DT_WaterCollector.png",
    enabled = true,
    uniquePerColony = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 36,
            xpReward = 90,
            recipe = {
                { category = "Cloth", count = 1 },
                { category = "Wood", count = 12 },
                { category = "Hardware", count = 8 },
                { category = "Adhesive", count = 1 }
            },
            effects = {
                waterStorageBonus = 100,
                waterCollectionRate = 2
            }
        }
    }
}

Config.InstallDefinitions.WaterCollector = {
    barrel_dark_green = {
        installKey = "barrel_dark_green",
        displayName = "Dark Green Barrel",
        iconPath = "media/ui/Buildings/DT_WaterCollector.png",
        requiredLevel = 1,
        maxCount = 999,
        workPoints = 12,
        xpReward = 30,
        recipe = {
            { category = "WaterContainer", count = 1 },
            { category = "Cloth", count = 1 },
            { category = "Adhesive", count = 2 }
        },
        effects = {
            waterCollectionRateBonus = 2
        },
        description = "Adds a dark green barrel manifold to improve rain collection throughput."
    },
    barrel_light_green = {
        installKey = "barrel_light_green",
        displayName = "Light Green Barrel",
        iconPath = "media/ui/Buildings/DT_WaterCollector.png",
        requiredLevel = 1,
        maxCount = 999,
        workPoints = 12,
        xpReward = 30,
        recipe = {
            { category = "WaterContainer", count = 1 },
            { category = "Cloth", count = 1 },
            { category = "Adhesive", count = 2 }
        },
        effects = {
            waterCollectionRateBonus = 2
        },
        description = "Adds a light green barrel manifold to improve rain collection throughput."
    },
    barrel_orange = {
        installKey = "barrel_orange",
        displayName = "Orange Barrel",
        iconPath = "media/ui/Buildings/DT_WaterCollector.png",
        requiredLevel = 1,
        maxCount = 999,
        workPoints = 12,
        xpReward = 30,
        recipe = {
            { category = "WaterContainer", count = 1 },
            { category = "Cloth", count = 1 },
            { category = "Adhesive", count = 2 }
        },
        effects = {
            waterCollectionRateBonus = 2
        },
        description = "Adds an orange barrel manifold to improve rain collection throughput."
    }
}
