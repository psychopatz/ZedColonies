DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.Workshop = {
    buildingType = "Workshop",
    displayName = "Workshop",
    iconPath = "media/ui/Buildings/DC_Workshop.png",
    enabled = false,
    maxLevel = 3,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = false,
            workPoints = 48,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 6 },
                { category = "Hardware", count = 12 },
                { category = "Cloth", count = 2 },
            },
            effects = {
                productionSlots = 1,
            }
        }
    }
}
