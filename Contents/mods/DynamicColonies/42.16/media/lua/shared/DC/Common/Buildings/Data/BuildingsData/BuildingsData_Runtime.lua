DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal

Internal.Runtime = Internal.Runtime or {}

local Runtime = Internal.Runtime

local function rebuildRuntimeIndexes()
    Runtime.buildingToColonyID = {}
    Runtime.projectToColonyID = {}
    Runtime.plotToBuildingID = {}

    local registry = Internal.GetRegistry and Internal.GetRegistry() or nil
    local index = registry and registry.GetData and registry.GetData() or nil
    for colonyID, colonySummary in pairs(index and index.colonies or {}) do
        local ownerData = Internal.NormalizeOwnerData(
            colonySummary and colonySummary.ownerUsername or "local",
            Internal.EnsureModDataTable(
                Internal.GetShardKeyForColonyID(colonyID),
                Internal.BuildEmptyOwnerShard(colonySummary and colonySummary.ownerUsername or "local")
            )
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

Internal.RebuildRuntimeIndexes = rebuildRuntimeIndexes

function Buildings.Init()
    Internal.EnsureModDataTable(Internal.GetIndexKey(), Internal.BuildEmptyIndex())
    rebuildRuntimeIndexes()
end

Events.OnInitGlobalModData.Add(Buildings.Init)

return Runtime