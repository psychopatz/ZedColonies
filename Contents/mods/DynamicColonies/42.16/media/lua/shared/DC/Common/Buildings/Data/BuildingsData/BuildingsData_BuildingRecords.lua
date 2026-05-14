DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Runtime = Internal.Runtime

function Buildings.CreateBuildingInstance(ownerUsername, buildingType, level, plotX, plotY)
    local ownerData = Buildings.EnsureOwner(ownerUsername)
    local instance = {
        buildingID = Buildings.NextID("building", ownerUsername),
        buildingType = tostring(buildingType or ""),
        level = math.max(0, math.floor(tonumber(level) or 0)),
        plotX = math.floor(tonumber(plotX) or 0),
        plotY = math.floor(tonumber(plotY) or 0),
        customName = nil,
        installs = {}
    }

    Internal.NormalizeBuildingInstance(instance)
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
    local ownerData = Internal.GetExistingOwnerData and Internal.GetExistingOwnerData(ownerUsername)
        or Buildings.EnsureOwner(ownerUsername)
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

function Buildings.GetPlotRing(plotX, plotY)
    local x = math.abs(math.floor(tonumber(plotX) or 0))
    local y = math.abs(math.floor(tonumber(plotY) or 0))
    return math.max(x, y)
end

return Buildings
