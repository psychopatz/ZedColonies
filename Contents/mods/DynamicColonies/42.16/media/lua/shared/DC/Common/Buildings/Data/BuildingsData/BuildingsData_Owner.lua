DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Runtime = Internal.Runtime or {}

Runtime.ownerNormalizationGuards = Runtime.ownerNormalizationGuards or {}
Runtime.ownerNormalizationContextByInput = Runtime.ownerNormalizationContextByInput or {}
Runtime.ownerNormalizationContextByShard = Runtime.ownerNormalizationContextByShard or {}
Runtime.ownerNormalizationContextByColonyID = Runtime.ownerNormalizationContextByColonyID or {}
Runtime.ownerNormalizationContextByAuthorityOwner = Runtime.ownerNormalizationContextByAuthorityOwner or {}
Internal.Runtime = Runtime

local function buildShardKeyFromSuffix(value)
    return tostring((Buildings.Config and Buildings.Config.MOD_DATA_PREFIX) or "DColony_Buildings_") .. tostring(value or "")
end

local function beginOwnerNormalizationContext(ownerUsername, ownerData)
    local inputKey = tostring(ownerUsername or "local")
    local shardKey = Internal.GetShardKey(ownerUsername)
    local colonyID = tostring(ownerData and ownerData.colonyID or Internal.GetOwnerKey(ownerUsername))
    local authorityOwner = tostring(ownerData and ownerData.ownerUsername or Internal.GetAuthorityOwner(ownerUsername))

    Runtime.ownerNormalizationGuards[shardKey] = ownerData
    Runtime.ownerNormalizationContextByInput[inputKey] = ownerData
    Runtime.ownerNormalizationContextByShard[shardKey] = ownerData
    Runtime.ownerNormalizationContextByColonyID[colonyID] = ownerData
    Runtime.ownerNormalizationContextByAuthorityOwner[authorityOwner] = ownerData

    return {
        inputKey = inputKey,
        shardKey = shardKey,
        colonyID = colonyID,
        authorityOwner = authorityOwner,
    }
end

local function endOwnerNormalizationContext(context)
    if not context then
        return
    end

    Runtime.ownerNormalizationGuards[context.shardKey] = nil
    Runtime.ownerNormalizationContextByInput[context.inputKey] = nil
    Runtime.ownerNormalizationContextByShard[context.shardKey] = nil
    Runtime.ownerNormalizationContextByColonyID[context.colonyID] = nil
    Runtime.ownerNormalizationContextByAuthorityOwner[context.authorityOwner] = nil
end

function Internal.GetOwnerDataIfNormalizing(ownerUsername)
    local inputKey = tostring(ownerUsername or "local")
    local ownerData = Runtime.ownerNormalizationContextByInput[inputKey]
    if ownerData then
        return ownerData
    end

    local authorityOwner = tostring(Internal.GetAuthorityOwner(ownerUsername))
    ownerData = Runtime.ownerNormalizationContextByAuthorityOwner[authorityOwner]
    if ownerData then
        return ownerData
    end

    return Runtime.ownerNormalizationContextByColonyID[inputKey]
end

function Internal.GetExistingOwnerData(ownerUsername)
    local ownerData = Internal.GetOwnerDataIfNormalizing(ownerUsername)
    if ownerData then
        return ownerData
    end

    local authorityOwner = tostring(Internal.GetAuthorityOwner(ownerUsername))
    local inputKey = tostring(ownerUsername or "local")
    local triedShardKeys = {}

    local function tryShard(shardKey, normalizeOwner)
        if shardKey == nil or triedShardKeys[shardKey] then
            return nil
        end
        triedShardKeys[shardKey] = true

        if not ModData or not ModData.exists or not ModData.exists(shardKey) then
            return nil
        end

        local data = ModData.get(shardKey)
        if type(data) ~= "table" then
            return nil
        end

        return Internal.NormalizeOwnerData(normalizeOwner or ownerUsername, data)
    end

    ownerData = tryShard(buildShardKeyFromSuffix(inputKey), ownerUsername)
    if ownerData then
        return ownerData
    end

    local registry = Internal.GetRegistry and Internal.GetRegistry() or nil
    local colonyID = registry and registry.GetColonyIDForOwner and registry.GetColonyIDForOwner(ownerUsername, false) or nil
    if colonyID ~= nil then
        ownerData = tryShard(Internal.GetShardKeyForColonyID(colonyID), authorityOwner)
        if ownerData then
            return ownerData
        end
    end

    return tryShard(buildShardKeyFromSuffix(authorityOwner), authorityOwner)
end

function Buildings.GetData()
    local data = Internal.EnsureModDataTable(Internal.GetIndexKey(), Internal.BuildEmptyIndex())
    data.schemaVersion = Buildings.Config.MOD_DATA_SCHEMA_VERSION or 3
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
    local shardKey = Internal.GetShardKey(ownerUsername)
    local ownerData = Internal.EnsureModDataTable(shardKey, Internal.BuildEmptyOwnerShard(ownerUsername))
    if Runtime.ownerNormalizationGuards[shardKey] == ownerData then
        return ownerData
    end

    local context = beginOwnerNormalizationContext(ownerUsername, ownerData)

    local ok, normalizedOrError = pcall(Internal.NormalizeOwnerData, ownerUsername, ownerData)
    endOwnerNormalizationContext(context)

    if not ok then
        error(normalizedOrError)
    end

    return normalizedOrError
end

function Buildings.GetBuildingsForOwner(ownerUsername)
    local ownerData = Internal.GetExistingOwnerData(ownerUsername) or Buildings.EnsureOwner(ownerUsername)
    return ownerData.buildings
end

function Buildings.GetProjectsForOwner(ownerUsername)
    local ownerData = Internal.GetExistingOwnerData(ownerUsername) or Buildings.EnsureOwner(ownerUsername)
    return ownerData.projects
end

function Buildings.CopyOwnerData(ownerUsername)
    return Internal.CopyDeep(Buildings.EnsureOwner(ownerUsername))
end

function Buildings.TouchOwnerVersion(ownerUsername)
    local ownerData = Buildings.EnsureOwner(ownerUsername)
    ownerData.version = ownerData.version + 1
    return ownerData.version
end

return Buildings