DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config
Config.Definitions = Config.Definitions or {}

Config.Definitions.Barricade = {
    buildingType = "Barricade",
    displayName = "Barricade",
    iconPath = "media/ui/Buildings/DC_Barricade.png",
    enabled = true,
    maxLevel = 1,
    isInfinite = false,
    levels = {}
}

Config.Frontier = Config.Frontier or {}

local FrontierConfig = Config.Frontier

FrontierConfig.CARDINAL_DIRECTIONS = FrontierConfig.CARDINAL_DIRECTIONS or {
    { x = -1, y = 0 },
    { x = 1, y = 0 },
    { x = 0, y = -1 },
    { x = 0, y = 1 }
}

local function normalizeRingDistance(plotX, plotY)
    local x = math.abs(math.floor(tonumber(plotX) or 0))
    local y = math.abs(math.floor(tonumber(plotY) or 0))
    return math.max(1, math.max(x, y))
end

local function buildBarricadeRecipe(ringDistance)
    local ring = math.max(1, math.floor(tonumber(ringDistance) or 1))
    if ring <= 2 then
        return {
            { category = "Wood", count = 4 },
            { category = "Cloth", count = 4 }
        }
    end

    return {
        { category = "Wood", count = 2 + math.max(0, ring - 1) },
        { category = "Hardware", count = 9 + (math.max(0, ring - 1) * 4) },
        { category = "Cloth", count = 1 + math.floor(math.max(0, ring - 1) / 2) }
    }
end

function FrontierConfig.GetRingDistance(plotX, plotY)
    return normalizeRingDistance(plotX, plotY)
end

function FrontierConfig.GetMaxActiveBarricades(hqLevel)
    local level = math.max(0, math.floor(tonumber(hqLevel) or 0))
    if level <= 0 then
        return 0
    end
    return level * 8
end

function FrontierConfig.GetRingBarricadeCapacity(ringDistance)
    local ring = math.max(0, math.floor(tonumber(ringDistance) or 0))
    if ring <= 0 then
        return 0
    end
    return ring * 8
end

function FrontierConfig.GetBarricadeDefinition()
    return {
        buildingType = "Barricade",
        displayName = "Barricade",
        iconPath = "media/ui/Buildings/DC_Barricade.png",
        enabled = true,
        maxLevel = 1,
        isInfinite = false,
        levels = {}
    }
end

function FrontierConfig.GetBarricadeLevelDefinition(targetLevel, plotX, plotY)
    local level = math.max(1, math.floor(tonumber(targetLevel) or 1))
    if level > 1 then
        return nil
    end

    local ring = normalizeRingDistance(plotX, plotY)
    return {
        enabled = true,
        workPoints = ring <= 2 and 10 or (18 + (ring * 6)),
        xpReward = 80 + (ring * 10),
        recipe = buildBarricadeRecipe(ring),
        effects = {
            claimsFrontier = true,
            ringDistance = ring,
            barricadeHP = 100 + (ring * 20)
        }
    }
end
