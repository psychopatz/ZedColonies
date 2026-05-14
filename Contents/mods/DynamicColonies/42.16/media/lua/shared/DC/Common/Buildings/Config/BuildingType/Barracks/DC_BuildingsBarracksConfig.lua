DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.DEFAULT_BARRACKS_CAPACITY = 4

Config.Definitions.Barracks = {
    buildingType = "Barracks",
    displayName = "Barracks",
    iconPath = "media/ui/Buildings/DC_Barracks.png",
    enabled = true,
    maxLevel = 3,
    isInfinite = false,
    levels = {
        [1] = {
            enabled = true,
            workPoints = 36,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 4 },
                { category = "Hardware", count = 11 },
                { category = "Cloth", count = 2 }
            },
            effects = {
                housingSlots = 4,
                recoveryMultiplier = 1.33
            }
        },
        [2] = {
            enabled = true,
            workPoints = 54,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 6 },
                { category = "Hardware", count = 18 },
                { category = "Cloth", count = 4 },
                { category = "Adhesive", count = 1 }
            },
            effects = {
                housingSlots = 4,
                recoveryMultiplier = 1.66
            }
        },
        [3] = {
            enabled = true,
            workPoints = 78,
            xpReward = 120,
            recipe = {
                { category = "Wood", count = 8 },
                { category = "Hardware", count = 28 },
                { category = "Cloth", count = 6 },
                { category = "Adhesive", count = 2 }
            },
            effects = {
                housingSlots = 4,
                recoveryMultiplier = 2.00
            }
        }
    }
}

function Config.GetBarracksSlotsForLevel(level)
    local levelDefinition = Config.GetLevelDefinition("Barracks", level)
    return math.max(
        0,
        math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.housingSlots) or Config.DEFAULT_BARRACKS_CAPACITY)
    )
end

function Config.GetBarracksRecoveryMultiplier(level)
    local levelDefinition = Config.GetLevelDefinition("Barracks", level)
    return math.max(
        0.01,
        tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.recoveryMultiplier) or 1.0
    )
end
