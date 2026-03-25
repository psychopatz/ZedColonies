DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Config = DC_Buildings.Config
local Buildings = DC_Buildings
local Internal = Buildings.Internal

Internal.Runtime = Internal.Runtime or {}

local Runtime = Internal.Runtime

local function copyDeep(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = copyDeep(entry)
    end
    return copy
end

local function ensureArray(value)
    return type(value) == "table" and value or {}
end

local function clearTable(target)
    for key, _ in pairs(target or {}) do
        target[key] = nil
    end
end

local function ensureModDataTable(key, defaults)
    if not ModData.exists(key) then
        ModData.add(key, defaults or {})
    end

    local data = ModData.get(key)
    if type(data) == "table" then
        return data
    end

    if ModData.remove then
        ModData.remove(key)
    end

    ModData.add(key, defaults or {})
    return ModData.get(key)
end

local function normalizeInstallCounts(instance)
    instance.installs = type(instance.installs) == "table" and instance.installs or {}
    for _, definition in ipairs(Config.GetInstallDefinitionList and Config.GetInstallDefinitionList(instance.buildingType) or {}) do
        local installKey = tostring(definition and definition.installKey or "")
        if installKey ~= "" then
            local maxCount = Config.GetInstallMaxCount and Config.GetInstallMaxCount(instance.buildingType, installKey, instance.level)
                or math.floor(tonumber(definition and definition.maxCount) or 0)
            instance.installs[installKey] = math.min(
                math.max(0, math.floor(tonumber(instance.installs[installKey]) or 0)),
                math.max(0, math.floor(tonumber(maxCount) or 0))
            )
        end
    end
end

local function normalizeBuildingInstance(instance)
    if type(instance) ~= "table" then
        return instance
    end

    instance.buildingType = tostring(instance.buildingType or "")
    instance.level = math.max(0, math.floor(tonumber(instance.level) or 0))
    instance.plotX = math.floor(tonumber(instance.plotX) or 0)
    instance.plotY = math.floor(tonumber(instance.plotY) or 0)
    normalizeInstallCounts(instance)
    return instance
end

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getOwnerKey(ownerUsername)
    local registry = getRegistry()
    if registry and registry.GetColonyIDForOwner then
        local colonyID = registry.GetColonyIDForOwner(ownerUsername, true)
        if colonyID ~= nil then
            return tostring(colonyID)
        end
    end

    return DC_Colony and DC_Colony.Config and DC_Colony.Config.GetOwnerUsername
        and DC_Colony.Config.GetOwnerUsername(ownerUsername)
        or tostring(ownerUsername or "local")
end

local function getAuthorityOwner(ownerUsername)
    return DC_Colony and DC_Colony.Config and DC_Colony.Config.GetOwnerUsername
        and DC_Colony.Config.GetOwnerUsername(ownerUsername)
        or tostring(ownerUsername or "local")
end

local function getIndexKey()
    return tostring(Config.MOD_DATA_KEY or "DColony_Buildings_Index")
end

local function getShardKey(ownerUsername)
    return tostring(Config.MOD_DATA_PREFIX or "DColony_Buildings_") .. tostring(getOwnerKey(ownerUsername))
end

local function getShardKeyForColonyID(colonyID)
    return tostring(Config.MOD_DATA_PREFIX or "DColony_Buildings_") .. tostring(colonyID)
end

local function buildEmptyIndex()
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    }
end

local function buildEmptyOwnerShard(ownerUsername)
    local colonyID = getOwnerKey(ownerUsername)
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        colonyID = colonyID,
        ownerUsername = getAuthorityOwner(ownerUsername),
        version = 1,
        counters = {
            nextBuildingID = 1,
            nextProjectID = 1
        },
        buildings = {},
        projects = {},
        map = nil
    }
end

local function normalizeOwnerData(ownerUsername, ownerData)
    ownerData.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    ownerData.colonyID = tostring(ownerData.colonyID or getOwnerKey(ownerUsername))
    ownerData.ownerUsername = getAuthorityOwner(ownerUsername or ownerData.ownerUsername)
    ownerData.version = math.max(1, math.floor(tonumber(ownerData.version) or 1))
    ownerData.counters = type(ownerData.counters) == "table" and ownerData.counters or {}
    ownerData.counters.nextBuildingID = math.max(1, math.floor(tonumber(ownerData.counters.nextBuildingID) or 1))
    ownerData.counters.nextProjectID = math.max(1, math.floor(tonumber(ownerData.counters.nextProjectID) or 1))
    ownerData.buildings = ensureArray(ownerData.buildings)
    for _, instance in ipairs(ownerData.buildings) do
        normalizeBuildingInstance(instance)
    end
    ownerData.projects = type(ownerData.projects) == "table" and ownerData.projects or {}
    Buildings.EnsureMapData(ownerData)
    return ownerData
end

local function rebuildRuntimeIndexes()
    Runtime.buildingToColonyID = {}
    Runtime.projectToColonyID = {}
    Runtime.plotToBuildingID = {}

    local registry = getRegistry()
    local index = registry and registry.GetData and registry.GetData() or nil
    for colonyID, colonySummary in pairs(index and index.colonies or {}) do
        local ownerData = normalizeOwnerData(
            colonySummary and colonySummary.ownerUsername or "local",
            ensureModDataTable(getShardKeyForColonyID(colonyID), buildEmptyOwnerShard(colonySummary and colonySummary.ownerUsername or "local"))
        )
        local plotMap = {}
        for _, instance in ipairs(ownerData.buildings or {}) do
            Runtime.buildingToColonyID[tostring(instance.buildingID or "")] = ownerData.colonyID
            plotMap[Buildings.GetPlotKey(instance.plotX, instance.plotY)] = tostring(instance.buildingID or "")
        end
        for projectID, _ in pairs(ownerData.projects or {}) do
            Runtime.projectToColonyID[tostring(projectID)] = ownerData.colonyID
        end
        Runtime.plotToBuildingID[ownerData.colonyID] = plotMap
    end
end

Internal.CopyDeep = copyDeep
Internal.EnsureArray = ensureArray
Internal.NormalizeBuildingInstance = normalizeBuildingInstance

function Buildings.Init()
    ensureModDataTable(getIndexKey(), buildEmptyIndex())
    rebuildRuntimeIndexes()
end

Events.OnInitGlobalModData.Add(Buildings.Init)

function Buildings.GetData()
    local data = ensureModDataTable(getIndexKey(), buildEmptyIndex())
    data.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    return data
end

function Buildings.Save(ownerUsername)
    if ownerUsername then
        local ownerData = Buildings.EnsureOwner(ownerUsername)
        ownerData.version = ownerData.version + 1
    end

    if GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
end

function Buildings.NextID(kind, ownerOrColonyID)
    local ownerData = Buildings.EnsureOwner(ownerOrColonyID)
    local key = kind == "building" and "nextBuildingID" or "nextProjectID"
    local prefix = kind == "building" and "building_" or "project_"
    local nextValue = math.max(1, math.floor(tonumber(ownerData.counters[key]) or 1))
    ownerData.counters[key] = nextValue + 1
    ownerData.version = ownerData.version + 1
    return prefix .. tostring(nextValue)
end

function Buildings.EnsureOwner(ownerUsername)
    local shardKey = getShardKey(ownerUsername)
    local ownerData = ensureModDataTable(shardKey, buildEmptyOwnerShard(ownerUsername))
    return normalizeOwnerData(ownerUsername, ownerData)
end

function Buildings.GetBuildingsForOwner(ownerUsername)
    return Buildings.EnsureOwner(ownerUsername).buildings
end

function Buildings.GetProjectsForOwner(ownerUsername)
    return Buildings.EnsureOwner(ownerUsername).projects
end

function Buildings.CreateBuildingInstance(ownerUsername, buildingType, level, plotX, plotY)
    local ownerData = Buildings.EnsureOwner(ownerUsername)
    local instance = {
        buildingID = Buildings.NextID("building", ownerUsername),
        buildingType = tostring(buildingType or ""),
        level = math.max(0, math.floor(tonumber(level) or 0)),
        plotX = math.floor(tonumber(plotX) or 0),
        plotY = math.floor(tonumber(plotY) or 0),
        installs = {}
    }

    normalizeBuildingInstance(instance)
    ownerData.buildings[#ownerData.buildings + 1] = instance
    ownerData.version = ownerData.version + 1
    Runtime.buildingToColonyID[instance.buildingID] = ownerData.colonyID
    Runtime.plotToBuildingID[ownerData.colonyID] = Runtime.plotToBuildingID[ownerData.colonyID] or {}
    Runtime.plotToBuildingID[ownerData.colonyID][Buildings.GetPlotKey(instance.plotX, instance.plotY)] = instance.buildingID
    return instance
end

function Buildings.FindBuildingForOwner(ownerUsername, buildingID)
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if instance.buildingID == buildingID then
            return instance
        end
    end
    return nil
end

function Buildings.FindBuildingAtPlot(ownerUsername, plotX, plotY)
    local ownerData = Buildings.EnsureOwner(ownerUsername)
    local wantedKey = Buildings.GetPlotKey(plotX, plotY)
    local plotMap = Runtime.plotToBuildingID[ownerData.colonyID]
    local buildingID = plotMap and plotMap[wantedKey] or nil
    if buildingID then
        local found = Buildings.FindBuildingForOwner(ownerUsername, buildingID)
        if found then
            return found
        end
    end

    for _, instance in ipairs(ownerData.buildings) do
        if Buildings.GetPlotKey(instance.plotX, instance.plotY) == wantedKey then
            return instance
        end
    end
    return nil
end

function Buildings.CopyOwnerData(ownerUsername)
    return copyDeep(Buildings.EnsureOwner(ownerUsername))
end

function Buildings.TouchOwnerVersion(ownerUsername)
    local ownerData = Buildings.EnsureOwner(ownerUsername)
    ownerData.version = ownerData.version + 1
    return ownerData.version
end

function Buildings.GetPlotRing(plotX, plotY)
    local x = math.abs(math.floor(tonumber(plotX) or 0))
    local y = math.abs(math.floor(tonumber(plotY) or 0))
    return math.max(x, y)
end

function Buildings.GetBuildingInstallCount(instance, installKey)
    if type(instance) ~= "table" then
        return 0
    end
    normalizeInstallCounts(instance)
    return math.max(0, math.floor(tonumber(instance.installs[tostring(installKey or "")]) or 0))
end

function Buildings.SetBuildingInstallCount(instance, installKey, count)
    if type(instance) ~= "table" then
        return 0
    end
    normalizeInstallCounts(instance)
    local normalizedKey = tostring(installKey or "")
    local safeCount = math.max(0, math.floor(tonumber(count) or 0))
    local maxCount = Config.GetInstallMaxCount and Config.GetInstallMaxCount(instance.buildingType, normalizedKey, instance.level) or nil
    if maxCount ~= nil then
        safeCount = math.min(safeCount, math.max(0, math.floor(tonumber(maxCount) or 0)))
    end
    instance.installs[normalizedKey] = safeCount
    return instance.installs[normalizedKey]
end

function Buildings.GetBuildingInstallCounts(instance)
    local counts = {}
    if type(instance) ~= "table" then
        return counts
    end
    normalizeInstallCounts(instance)
    for _, definition in ipairs(Config.GetInstallDefinitionList and Config.GetInstallDefinitionList(instance.buildingType) or {}) do
        local installKey = tostring(definition and definition.installKey or "")
        if installKey ~= "" then
            counts[installKey] = Buildings.GetBuildingInstallCount(instance, installKey)
        end
    end
    return counts
end

function Buildings.GetWarehouseBuildingCapacityContribution(instance)
    if not instance or tostring(instance.buildingType or "") ~= "Warehouse" then
        return 0
    end

    local total = 0
    local levelDefinition = Config.GetLevelDefinition("Warehouse", instance.level)
    total = total + math.max(0, math.floor(tonumber(levelDefinition and levelDefinition.effects and levelDefinition.effects.warehouseBaseBonus) or 0))

    for _, definition in ipairs(Config.GetInstallDefinitionList and Config.GetInstallDefinitionList("Warehouse") or {}) do
        local count = Buildings.GetBuildingInstallCount(instance, definition.installKey)
        local perInstall = math.max(0, math.floor(tonumber(definition and definition.effects and definition.effects.warehouseCapacityBonus) or 0))
        total = total + (count * perInstall)
    end

    return total
end

return Buildings
