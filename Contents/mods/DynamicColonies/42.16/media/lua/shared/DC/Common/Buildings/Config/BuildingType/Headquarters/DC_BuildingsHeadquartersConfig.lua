DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

local function buildInitialLevels()
    local levels = {}
    for level = 1, 5 do
        local baseWorkPoints = 100 + ((level - 1) * 50)
        local xpReward = 50 + ((level - 1) * 25)
        local baseCount = 8 + ((level - 1) * 4)
        local nailCount = 4 + ((level - 1) * 2)
        levels[level] = {
            enabled = true,
            workPoints = baseWorkPoints,
            xpReward = xpReward,
            recipe = {
                { fullType = "DCColonies.DCBlueprintHeadquarters", count = 1 },
                { fullType = "Base.Plank", count = baseCount },
                { fullType = "Base.Nails", count = nailCount },
                { fullType = "Base.WoodenPlank", count = baseCount / 2 }
            },
            effects = {
                level = level,
                description = "Headquarters Level " .. level
            }
        }
    end
    return levels
end

Config.Definitions.Headquarters = {
    buildingType = "Headquarters",
    displayName = "Headquarters",
    iconPath = "media/ui/Buildings/DC_Headquarters.png",
    enabled = true,
    maxLevel = 5,
    isInfinite = false,
    levels = buildInitialLevels()
}

local HQConfig = {
    buildingType = "Headquarters",
    displayName = "Headquarters",
    iconPath = "media/ui/Buildings/DC_Headquarters.png",
    enabled = true,
    isInfinite = true
}

local function buildRecipe(targetLevel)
    local level = math.max(1, math.floor(tonumber(targetLevel) or 1))
    local baseCount = 8 + ((level - 1) * 4)
    local nailCount = 4 + ((level - 1) * 2)
    return {
        { fullType = "DCColonies.DCBlueprintHeadquarters", count = 1 },
        { fullType = "Base.Plank", count = baseCount },
        { fullType = "Base.Nails", count = nailCount },
        { fullType = "Base.WoodenPlank", count = baseCount / 2 }
    }
end

function HQConfig.GetDefinition()
    local levels = {}
    for level = 1, 5 do
        levels[level] = HQConfig.GetLevelDefinition(level)
    end
    return {
        buildingType = HQConfig.buildingType,
        displayName = HQConfig.displayName,
        iconPath = HQConfig.iconPath,
        enabled = HQConfig.enabled,
        maxLevel = 5,
        isInfinite = false,
        levels = levels
    }
end

function HQConfig.GetLevelDefinition(targetLevel)
    local level = math.max(1, math.floor(tonumber(targetLevel) or 1))
    local baseWorkPoints = 100 + ((level - 1) * 50)
    local xpReward = 50 + ((level - 1) * 25)
    return {
        enabled = true,
        workPoints = baseWorkPoints,
        xpReward = xpReward,
        recipe = buildRecipe(level),
        effects = {
            level = level,
            description = "Headquarters Level " .. level
        }
    }
end

Config.HQ = HQConfig
