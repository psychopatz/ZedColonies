DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.Incinerator = {
    buildingType = "Incinerator",
    displayName = "Incinerator",
    iconPath = "media/ui/Buildings/DC_Incinerator.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    unlockHook = "Research_Incinerator",
    levels = {
        [1] = {
            enabled = true,
            workPoints = 70,
            xpReward = 140,
            recipe = {
                { category = "Metal", count = 22 },
                { category = "Hardware", count = 18 },
                { category = "Electronics", count = 4 },
            },
            effects = {
                incineratorBatchSize = 6,
                incineratorCooldownHours = 12,
                incineratorFuelPerBatch = 0,
            }
        }
    }
}
