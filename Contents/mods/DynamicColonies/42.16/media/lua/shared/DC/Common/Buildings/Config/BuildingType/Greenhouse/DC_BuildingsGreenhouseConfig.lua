DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.Greenhouse = {
    buildingType = "Greenhouse",
    displayName = "Greenhouse",
    iconPath = "media/ui/Buildings/DC_Greenhouse.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 60,
            xpReward = 140,
            recipe = {
                { category = "Wood", count = 16 },
                { category = "Hardware", count = 24 },
                { category = "Cloth", count = 4 },
                { category = "Adhesive", count = 2 }
            },
            effects = {
                gardenSlots = 4,
                greenhouseWaterPerDayPerSlot = 10
            }
        }
    }
}
