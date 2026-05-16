DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.Recycler = {
    buildingType = "Recycler",
    displayName = "Recycler",
    iconPath = "media/ui/Buildings/DC_Workshop.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 36,
            xpReward = 120,
            recipe = {
                { category = "Metal", count = 4 },
                { category = "Hardware", count = 8 },
                { category = "ElectronicScrap", count = 2 },
            },
            effects = {
                recyclerSlots = 1,
            }
        }
    }
}

return Config
