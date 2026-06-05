DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.Cemetery = {
    buildingType = "Cemetery",
    displayName = "Cemetery",
    iconPath = "media/ui/Buildings/DC_Cemetery.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 45,
            xpReward = 90,
            recipe = {
                { category = "Wood", count = 18 },
                { category = "Stone", count = 18 },
                { category = "Hardware", count = 12 },
            },
            effects = {
                cemeterySlots = 8,
                cemeteryDecomposeDays = 14,
            }
        }
    }
}
