DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.Headquarters = {
    buildingType = "Headquarters",
    displayName = "Headquarters",
    iconPath = "media/ui/Buildings/DC_Headquarters.png",
    enabled = true,
    maxLevel = 0,
    isInfinite = true,
    levels = {}
}

local HQConfig = {
    buildingType = "Headquarters",
    displayName = "Headquarters",
    iconPath = "media/ui/Buildings/DC_Headquarters.png",
    enabled = true,
    isInfinite = true
}

local function buildRecipe(targetLevel)
    return {
        { fullType = "Base.Plank", count = 8 },
        { fullType = "Base.Nails", count = 4 }
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
    local frontierConfig = Config and Config.Frontier or nil
    local currentCap = frontierConfig and frontierConfig.GetMaxActiveBarricades and frontierConfig.GetMaxActiveBarricades(level) or 0
    local previousCap = level > 1 and frontierConfig and frontierConfig.GetMaxActiveBarricades and frontierConfig.GetMaxActiveBarricades(level - 1) or 0
    return {
        enabled = true,
        workPoints = 0,
        xpReward = 0,
        recipe = buildRecipe(level),
        effects = {
            maxActiveBarricades = currentCap,
            barricadeCapDelta = math.max(0, currentCap - previousCap)
        }
    }
end

Config.HQ = HQConfig
