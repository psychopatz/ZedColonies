DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}

local Config = DC_Buildings.Config

Config.MOD_DATA_KEY = "DColony_Buildings_Index"
Config.MOD_DATA_SCHEMA_VERSION = 3
Config.MOD_DATA_PREFIX = "DColony_Buildings_"
Config.DEFAULT_UNHOUSED_RECOVERY_MULTIPLIER = 1.00

Config.Definitions = Config.Definitions or {}
Config.InstallDefinitions = Config.InstallDefinitions or {}

function Config.GetDefinition(buildingType)
    local normalized = tostring(buildingType or "")
    if normalized == "Headquarters" and Config.HQ and Config.HQ.GetDefinition then
        return Config.HQ.GetDefinition()
    end
    if normalized == "Barricade" and Config.Frontier and Config.Frontier.GetBarricadeDefinition then
        return Config.Frontier.GetBarricadeDefinition()
    end
    return Config.Definitions[normalized]
end

function Config.GetDefinitionList()
    local definitions = {}
    for buildingType, _ in pairs(Config.Definitions or {}) do
        definitions[#definitions + 1] = Config.GetDefinition(buildingType)
    end
    table.sort(definitions, function(a, b)
        return tostring(a.displayName or a.buildingType or "") < tostring(b.displayName or b.buildingType or "")
    end)
    return definitions
end

function Config.GetLevelDefinition(buildingType, level)
    local normalized = tostring(buildingType or "")
    local levelIndex = math.max(0, math.floor(tonumber(level) or 0))
    if normalized == "Headquarters" and Config.HQ and Config.HQ.GetLevelDefinition then
        return Config.HQ.GetLevelDefinition(levelIndex)
    end
    if normalized == "Barricade" and Config.Frontier and Config.Frontier.GetBarricadeLevelDefinition then
        return Config.Frontier.GetBarricadeLevelDefinition(levelIndex, 0, 0)
    end

    local definition = Config.GetDefinition(normalized)
    return definition and definition.levels and definition.levels[levelIndex] or nil
end

function Config.GetMaxLevel(buildingType)
    local definition = Config.GetDefinition(buildingType)
    if not definition then
        return 0
    end
    if definition.isInfinite == true then
        return 0
    end
    return math.max(0, math.floor(tonumber(definition.maxLevel) or 0))
end

function Config.GetInstallDefinition(buildingType, installKey)
    local buildingInstalls = Config.InstallDefinitions[tostring(buildingType or "")]
    if not buildingInstalls then
        return nil
    end
    return buildingInstalls[tostring(installKey or "")]
end

function Config.GetInstallDefinitionList(buildingType)
    local definitions = {}
    local buildingInstalls = Config.InstallDefinitions[tostring(buildingType or "")]
    for installKey, _ in pairs(buildingInstalls or {}) do
        definitions[#definitions + 1] = Config.GetInstallDefinition(buildingType, installKey)
    end
    table.sort(definitions, function(a, b)
        local levelA = math.max(0, math.floor(tonumber(a and a.requiredLevel) or 0))
        local levelB = math.max(0, math.floor(tonumber(b and b.requiredLevel) or 0))
        if levelA == levelB then
            return tostring(a and a.displayName or a and a.installKey or "") < tostring(b and b.displayName or b and b.installKey or "")
        end
        return levelA < levelB
    end)
    return definitions
end

function Config.GetInstallMaxCount(buildingType, installKey, buildingLevel)
    local normalized = tostring(buildingType or "")
    if normalized == "Infirmary" and Config.Infirmary and Config.Infirmary.GetInstallMaxCount then
        return Config.Infirmary.GetInstallMaxCount(installKey, buildingLevel)
    end

    local definition = Config.GetInstallDefinition(buildingType, installKey)
    if not definition then
        return 0
    end

    return math.max(0, math.floor(tonumber(definition.maxCount) or 0))
end

function Config.GetUnhousedRecoveryMultiplier()
    return math.max(0.01, tonumber(Config.DEFAULT_UNHOUSED_RECOVERY_MULTIPLIER) or 0.33)
end

return Config
