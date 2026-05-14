DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.WaterTank = {
    buildingType = "WaterTank",
    displayName = "Water Tank",
    iconPath = "media/ui/Buildings/DT_WaterStorage.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 42,
            xpReward = 110,
            recipe = {
                { category = "Cloth", count = 4 },
                { category = "Adhesive", count = 2 },
                { category = "Wood", count = 8 },
                { category = "Hardware", count = 20 }
            },
            effects = {
                waterStorageBonus = 100
            }
        }
    }
}
