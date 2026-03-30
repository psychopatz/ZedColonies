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
                { fullType = "Base.Tarp", count = 1 },
                { fullType = "Base.Plank", count = 12 },
                { fullType = "Base.Nails", count = 8 },
                { fullType = "Base.DuctTape", count = 1 }
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
            { fullType = "Base.Mov_DarkGreenBarrel", count = 1 },
            { fullType = "Base.Tarp", count = 1 },
            { fullType = "Base.DuctTape", count = 2 }
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
            { fullType = "Base.Mov_LightGreenBarrel", count = 1 },
            { fullType = "Base.Tarp", count = 1 },
            { fullType = "Base.DuctTape", count = 2 }
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
            { fullType = "Base.Mov_OrangeBarrel", count = 1 },
            { fullType = "Base.Tarp", count = 1 },
            { fullType = "Base.DuctTape", count = 2 }
        },
        effects = {
            waterCollectionRateBonus = 2
        },
        description = "Adds an orange barrel manifold to improve rain collection throughput."
    }
}
