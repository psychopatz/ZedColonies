DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.ResearchStation = {
    buildingType = "ResearchStation",
    displayName = "Research Station",
    iconPath = "media/ui/Buildings/DC_ResearchStation.png",
    enabled = true,
    maxLevel = 3,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 42,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 4 },
                { category = "Hardware", count = 10 },
                { category = "Glass", count = 2 },
                { category = "Books", count = 2 },
            },
            effects = {
                researchQueueSlots = 24,
            }
        }
    }
}
