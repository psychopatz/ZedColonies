DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal

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
    return Internal.NormalizeOwnerData(ownerUsername, ownerData)
end

function Buildings.GetBuildingsForOwner(ownerUsername)
    return Buildings.EnsureOwner(ownerUsername).buildings
end

function Buildings.GetProjectsForOwner(ownerUsername)
    return Buildings.EnsureOwner(ownerUsername).projects
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