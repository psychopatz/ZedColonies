DT_Buildings = DT_Buildings or {}
DT_Buildings.Config = DT_Buildings.Config or {}

local Config = DT_Buildings.Config

local HQConfig = {
    buildingType = "Headquarters",
    displayName = "Headquarters",
    iconPath = "media/ui/Buildings/DT_Headquarters.png",
    enabled = true,
    isInfinite = true
}

local function buildRecipe(targetLevel)
    local level = math.max(1, math.floor(tonumber(targetLevel) or 1))
    return {
        { fullType = "Base.Log", count = 4 + (level * 2) },
        { fullType = "Base.Nails", count = 12 + (level * 8) },
        { fullType = "Base.Sheet", count = 2 + math.floor((level + 1) / 2) },
        { fullType = "Base.Hinge", count = 1 + math.floor(level / 2) }
    }
end

function HQConfig.GetDefinition()
    return {
        buildingType = HQConfig.buildingType,
        displayName = HQConfig.displayName,
        iconPath = HQConfig.iconPath,
        enabled = HQConfig.enabled,
        maxLevel = 0,
        isInfinite = true,
        levels = {}
    }
end

function HQConfig.GetLevelDefinition(targetLevel)
    local level = math.max(1, math.floor(tonumber(targetLevel) or 1))
    return {
        enabled = true,
        workPoints = 30 + (level * 18),
        xpReward = 150 + (level * 20),
        recipe = buildRecipe(level),
        effects = {
            expandsMap = level > 1,
            unlockRing = math.max(1, level - 1)
        }
    }
end

Config.HQ = HQConfig

return HQConfig
