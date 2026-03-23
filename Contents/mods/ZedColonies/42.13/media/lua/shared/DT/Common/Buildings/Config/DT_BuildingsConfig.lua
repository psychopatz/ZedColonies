DT_Buildings = DT_Buildings or {}
DT_Buildings.Config = DT_Buildings.Config or {}

local Config = DT_Buildings.Config

Config.MOD_DATA_KEY = "DynamicTrading_Buildings"
Config.DEFAULT_UNHOUSED_RECOVERY_MULTIPLIER = 0.33
Config.DEFAULT_BARRACKS_CAPACITY = 4
Config.DEFAULT_INFIRMARY_BASE_CAPACITY = 1
Config.DEFAULT_BUILDER_BASE_WORK_POINTS_PER_HOUR = 1.0

Config.ToolTags = {
    Builder = "Builder.Tool",
    Hammer = "Builder.Tool.Hammer",
    Saw = "Builder.Tool.Saw"
}

Config.BuilderToolFullTypes = {
    ["Base.Hammer"] = { Config.ToolTags.Builder, Config.ToolTags.Hammer },
    ["Base.BallPeenHammer"] = { Config.ToolTags.Builder, Config.ToolTags.Hammer },
    ["Base.ClubHammer"] = { Config.ToolTags.Builder, Config.ToolTags.Hammer },
    ["Base.Saw"] = { Config.ToolTags.Builder, Config.ToolTags.Saw },
    ["Base.GardenSaw"] = { Config.ToolTags.Builder, Config.ToolTags.Saw },
    ["Base.SmallSaw"] = { Config.ToolTags.Builder, Config.ToolTags.Saw },
    ["Base.CrudeSaw"] = { Config.ToolTags.Builder, Config.ToolTags.Saw }
}

local function buildBuildingDefinition(definition)
    return definition
end

local function buildInstallDefinition(definition)
    return definition
end

Config.Definitions = {
    Barracks = buildBuildingDefinition({
        buildingType = "Barracks",
        displayName = "Barracks",
        iconPath = "media/ui/Buildings/DT_Barracks.png",
        enabled = true,
        maxLevel = 3,
        isInfinite = false,
        levels = {
            [1] = {
                enabled = true,
                workPoints = 36,
                xpReward = 120,
                recipe = {
                    { fullType = "Base.Log", count = 4 },
                    { fullType = "Base.Nails", count = 10 },
                    { fullType = "Base.Sheet", count = 2 },
                    { fullType = "Base.Hinge", count = 1 }
                },
                effects = {
                    housingSlots = 4,
                    recoveryMultiplier = 1.00
                }
            },
            [2] = {
                enabled = true,
                workPoints = 54,
                xpReward = 120,
                recipe = {
                    { fullType = "Base.Log", count = 6 },
                    { fullType = "Base.Nails", count = 16 },
                    { fullType = "Base.Sheet", count = 4 },
                    { fullType = "Base.Hinge", count = 2 },
                    { fullType = "Base.Woodglue", count = 1 }
                },
                effects = {
                    housingSlots = 4,
                    recoveryMultiplier = 1.20
                }
            },
            [3] = {
                enabled = true,
                workPoints = 78,
                xpReward = 120,
                recipe = {
                    { fullType = "Base.Log", count = 8 },
                    { fullType = "Base.Nails", count = 24 },
                    { fullType = "Base.Sheet", count = 6 },
                    { fullType = "Base.Hinge", count = 4 },
                    { fullType = "Base.Woodglue", count = 2 }
                },
                effects = {
                    housingSlots = 4,
                    recoveryMultiplier = 1.40
                }
            }
        }
    }),
    Infirmary = buildBuildingDefinition({
        buildingType = "Infirmary",
        displayName = "Infirmary",
        iconPath = "media/ui/Buildings/DT_Infirmary.png",
        enabled = true,
        maxLevel = 3,
        isInfinite = false,
        levels = {
            [1] = {
                enabled = true,
                workPoints = 36,
                xpReward = 120,
                recipe = {
                    { fullType = "Base.Log", count = 4 },
                    { fullType = "Base.Nails", count = 10 },
                    { fullType = "Base.Sheet", count = 2 },
                    { fullType = "Base.Hinge", count = 1 }
                },
                effects = {
                    infirmaryBaseCapacity = 1,
                    infirmaryCapacityCap = 5
                }
            },
            [2] = {
                enabled = true,
                workPoints = 54,
                xpReward = 120,
                recipe = {
                    { fullType = "Base.Log", count = 6 },
                    { fullType = "Base.Nails", count = 16 },
                    { fullType = "Base.Sheet", count = 4 },
                    { fullType = "Base.Hinge", count = 2 },
                    { fullType = "Base.Woodglue", count = 1 }
                },
                effects = {
                    infirmaryBaseCapacity = 1,
                    infirmaryCapacityCap = 10
                }
            },
            [3] = {
                enabled = true,
                workPoints = 78,
                xpReward = 120,
                recipe = {
                    { fullType = "Base.Log", count = 8 },
                    { fullType = "Base.Nails", count = 24 },
                    { fullType = "Base.Sheet", count = 6 },
                    { fullType = "Base.Hinge", count = 4 },
                    { fullType = "Base.Woodglue", count = 2 }
                },
                effects = {
                    infirmaryBaseCapacity = 1,
                    infirmaryCapacityCap = 15
                }
            }
        }
    }),
    Armory = buildBuildingDefinition({
        buildingType = "Armory",
        displayName = "Armory",
        iconPath = "media/ui/Buildings/DT_Armory.png",
        enabled = false,
        maxLevel = 3,
        isInfinite = false,
        levels = {}
    }),
    Barricade = buildBuildingDefinition({
        buildingType = "Barricade",
        displayName = "Barricade",
        iconPath = "media/ui/Buildings/DT_Barricade.png",
        enabled = false,
        maxLevel = 3,
        isInfinite = false,
        levels = {}
    }),
    Greenhouse = buildBuildingDefinition({
        buildingType = "Greenhouse",
        displayName = "Greenhouse",
        iconPath = "media/ui/Buildings/DT_Greenhouse.png",
        enabled = false,
        maxLevel = 3,
        isInfinite = false,
        levels = {}
    }),
    Headquarters = buildBuildingDefinition({
        buildingType = "Headquarters",
        displayName = "Headquarters",
        iconPath = "media/ui/Buildings/DT_Headquarters.png",
        enabled = true,
        maxLevel = 0,
        isInfinite = true,
        levels = {}
    }),
    Kitchen = buildBuildingDefinition({
        buildingType = "Kitchen",
        displayName = "Kitchen",
        iconPath = "media/ui/Buildings/DT_Kitchen.png",
        enabled = false,
        maxLevel = 3,
        isInfinite = false,
        levels = {}
    }),
    Laboratory = buildBuildingDefinition({
        buildingType = "Laboratory",
        displayName = "Laboratory",
        iconPath = "media/ui/Buildings/DT_Laboratory.png",
        enabled = false,
        maxLevel = 3,
        isInfinite = false,
        levels = {}
    }),
    ResearchStation = buildBuildingDefinition({
        buildingType = "ResearchStation",
        displayName = "Research Station",
        iconPath = "media/ui/Buildings/DT_ResearchStation",
        enabled = false,
        maxLevel = 3,
        isInfinite = false,
        levels = {}
    }),
    Warehouse = buildBuildingDefinition({
        buildingType = "Warehouse",
        displayName = "Warehouse",
        iconPath = "media/ui/Buildings/DT_Warehouse.png",
        enabled = true,
        maxLevel = 2,
        isInfinite = false,
        levels = {
            [1] = {
                enabled = true,
                workPoints = 54,
                xpReward = 120,
                recipe = {
                    { fullType = "Base.Log", count = 6 },
                    { fullType = "Base.Nails", count = 24 },
                    { fullType = "Base.Sheet", count = 4 },
                    { fullType = "Base.Hinge", count = 2 },
                    { fullType = "Base.Woodglue", count = 1 }
                },
                effects = {
                    warehouseBaseBonus = 100
                }
            },
            [2] = {
                enabled = true,
                workPoints = 78,
                xpReward = 120,
                recipe = {
                    { fullType = "Base.Log", count = 8 },
                    { fullType = "Base.Nails", count = 36 },
                    { fullType = "Base.Sheet", count = 6 },
                    { fullType = "Base.Hinge", count = 4 },
                    { fullType = "Base.Woodglue", count = 2 }
                },
                effects = {
                    warehouseBaseBonus = 100
                }
            }
        }
    }),
    TradeStand = buildBuildingDefinition({
        buildingType = "TradeStand",
        displayName = "Trade Stand",
        iconPath = "media/ui/Buildings/DT_tradeStand.png",
        enabled = false,
        maxLevel = 3,
        isInfinite = false,
        levels = {}
    })
}

Config.InstallDefinitions = {
    Infirmary = {
        bed = buildInstallDefinition({
            installKey = "bed",
            displayName = "Bed",
            iconPath = "media/ui/Buildings/DT_Infirmary.png",
            requiredLevel = 1,
            maxCount = 14,
            workPoints = 18,
            xpReward = 60,
            recipe = {
                { fullType = "Base.Log", count = 2 },
                { fullType = "Base.Nails", count = 10 },
                { fullType = "Base.Sheet", count = 1 },
                { fullType = "Base.Hinge", count = 1 }
            },
            effects = {
                infirmaryCapacityBonus = 1
            },
            description = "Adds another medical bed so one more worker can receive infirmary treatment while sleeping."
        })
    },
    Warehouse = {
        rack = buildInstallDefinition({
            installKey = "rack",
            displayName = "Rack",
            iconPath = "media/ui/Buildings/DT_Warehouse.png",
            requiredLevel = 1,
            maxCount = 10,
            workPoints = 18,
            xpReward = 60,
            recipe = {
                { fullType = "Base.Log", count = 2 },
                { fullType = "Base.Nails", count = 10 },
                { fullType = "Base.Sheet", count = 1 },
                { fullType = "Base.Hinge", count = 1 }
            },
            effects = {
                warehouseCapacityBonus = 10
            },
            description = "Adds shelving racks to improve storage density inside this Warehouse."
        }),
        storage_boxes = buildInstallDefinition({
            installKey = "storage_boxes",
            displayName = "Storage Boxes",
            iconPath = "media/ui/Buildings/DT_Warehouse.png",
            requiredLevel = 2,
            maxCount = 10,
            workPoints = 30,
            xpReward = 90,
            recipe = {
                { fullType = "Base.Log", count = 4 },
                { fullType = "Base.Nails", count = 18 },
                { fullType = "Base.Sheet", count = 2 },
                { fullType = "Base.Hinge", count = 2 },
                { fullType = "Base.Woodglue", count = 1 }
            },
            effects = {
                warehouseCapacityBonus = 50
            },
            description = "Adds durable storage boxes for a larger storage jump once the Warehouse reaches level 2."
        })
    }
}

function Config.GetDefinition(buildingType)
    local normalized = tostring(buildingType or "")
    if normalized == "Headquarters" and Config.HQ and Config.HQ.GetDefinition then
        return Config.HQ.GetDefinition()
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
    local definition = Config.GetInstallDefinition(buildingType, installKey)
    if not definition then
        return 0
    end

    if tostring(buildingType or "") == "Infirmary" and tostring(installKey or "") == "bed" then
        local level = math.max(0, math.floor(tonumber(buildingLevel) or 0))
        return math.max(0, Config.GetInfirmaryCapacityCap(level) - Config.GetInfirmaryBaseCapacity(level))
    end

    return math.max(0, math.floor(tonumber(definition.maxCount) or 0))
end

function Config.GetBuilderToolTags(fullType)
    local mapped = Config.BuilderToolFullTypes[tostring(fullType or "")]
    local tags = {}
    for _, tag in ipairs(mapped or {}) do
        tags[#tags + 1] = tag
    end
    return tags
end

function Config.IsBuilderToolFullType(fullType)
    return Config.BuilderToolFullTypes[tostring(fullType or "")] ~= nil
end

function Config.GetBuilderBaseWorkPointsPerHour()
    return math.max(0.01, tonumber(Config.DEFAULT_BUILDER_BASE_WORK_POINTS_PER_HOUR) or 1.0)
end

function Config.GetUnhousedRecoveryMultiplier()
    return math.max(0.01, tonumber(Config.DEFAULT_UNHOUSED_RECOVERY_MULTIPLIER) or 0.33)
end

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

function Config.GetInfirmaryBaseCapacity(level)
    local levelDefinition = Config.GetLevelDefinition("Infirmary", level)
    return math.max(
        0,
        math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.infirmaryBaseCapacity) or Config.DEFAULT_INFIRMARY_BASE_CAPACITY)
    )
end

function Config.GetInfirmaryCapacityCap(level)
    local levelDefinition = Config.GetLevelDefinition("Infirmary", level)
    local levelIndex = math.max(0, math.floor(tonumber(level) or 0))
    return math.max(
        0,
        math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.infirmaryCapacityCap) or (levelIndex * 5))
    )
end

return Config
