DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.MassGrave = {
    buildingType = "MassGrave",
    displayName = "Mass Grave",
    iconPath = "media/ui/Buildings/DC_MassGrave.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 40,
            xpReward = 80,
            recipe = {
                { category = "Wood", count = 10 },
                { category = "Stone", count = 12 },
            },
            effects = {
                massGraveSlots = 24,
                massGraveDecomposeDays = 7,
            }
        }
    }
}
