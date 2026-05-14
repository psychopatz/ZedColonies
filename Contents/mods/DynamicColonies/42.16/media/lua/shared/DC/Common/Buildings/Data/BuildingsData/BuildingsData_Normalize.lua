DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Buildings.Internal

local function ensureOwnerMapData(ownerData)
    Buildings.EnsureMapData(ownerData)
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
    if instance.customName ~= nil and tostring(instance.customName) ~= "" then
        instance.customName = tostring(instance.customName)
    else
        instance.customName = nil
    end
    normalizeInstallCounts(instance)
    return instance
end

local function buildEmptyIndex()
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    }
end

local function buildEmptyOwnerShard(ownerUsername)
    local colonyID = Internal.GetOwnerKey(ownerUsername)
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        colonyID = colonyID,
        ownerUsername = Internal.GetAuthorityOwner(ownerUsername),
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
    ownerData.colonyID = tostring(ownerData.colonyID or Internal.GetOwnerKey(ownerUsername))
    ownerData.ownerUsername = Internal.GetAuthorityOwner(ownerUsername or ownerData.ownerUsername)
    ownerData.version = math.max(1, math.floor(tonumber(ownerData.version) or 1))
    ownerData.counters = type(ownerData.counters) == "table" and ownerData.counters or {}
    ownerData.counters.nextBuildingID = math.max(1, math.floor(tonumber(ownerData.counters.nextBuildingID) or 1))
    ownerData.counters.nextProjectID = math.max(1, math.floor(tonumber(ownerData.counters.nextProjectID) or 1))
    ensureOwnerMapData(ownerData)
    ownerData.buildings = Internal.EnsureArray(ownerData.buildings)
    for _, instance in ipairs(ownerData.buildings) do
        normalizeBuildingInstance(instance)
    end
    ownerData.projects = type(ownerData.projects) == "table" and ownerData.projects or {}
    return ownerData
end

Internal.EnsureModDataTable = ensureModDataTable
Internal.NormalizeInstallCounts = normalizeInstallCounts
Internal.NormalizeBuildingInstance = normalizeBuildingInstance
Internal.BuildEmptyIndex = buildEmptyIndex
Internal.BuildEmptyOwnerShard = buildEmptyOwnerShard
Internal.NormalizeOwnerData = normalizeOwnerData

return Internal
