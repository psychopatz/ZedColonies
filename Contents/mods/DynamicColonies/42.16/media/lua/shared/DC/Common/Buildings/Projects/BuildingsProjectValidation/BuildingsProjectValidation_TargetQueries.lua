DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Validation = Internal.ProjectValidation or {}

Internal.ProjectValidation = Validation

function Validation.FindWarehouseInRing(ownerUsername, ring, excludedBuildingID)
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if tostring(instance.buildingType or "") == "Warehouse"
            and math.floor(tonumber(instance.level) or 0) > 0
            and Buildings.GetPlotRing(instance.plotX, instance.plotY) == ring
            and tostring(instance.buildingID or "") ~= tostring(excludedBuildingID or "") then
            return instance
        end
    end
    return nil
end

function Validation.FindCompletedBuildingByType(ownerUsername, buildingType, excludedBuildingID)
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if tostring(instance.buildingType or "") == tostring(buildingType or "")
            and math.floor(tonumber(instance.level) or 0) > 0
            and tostring(instance.buildingID or "") ~= tostring(excludedBuildingID or "") then
            return instance
        end
    end
    return nil
end

function Validation.FindActiveBuildProjectByType(ownerUsername, buildingType)
    for _, project in pairs(Buildings.GetProjectsForOwner(ownerUsername)) do
        if tostring(project.status or "") == "Active"
            and tostring(project.buildingType or "") == tostring(buildingType or "")
            and Validation.NormalizeMode(project.mode) == "build" then
            return project
        end
    end
    return nil
end

function Validation.FindWarehouseBuildProjectInRing(ownerUsername, ring)
    for _, project in pairs(Buildings.GetProjectsForOwner(ownerUsername)) do
        if tostring(project.status or "") == "Active"
            and tostring(project.buildingType or "") == "Warehouse"
            and Validation.NormalizeMode(project.mode) == "build"
            and Buildings.GetPlotRing(project.plotX, project.plotY) == ring then
            return project
        end
    end
    return nil
end

function Validation.HasCompletedOuterBarricade(ownerUsername, plotX, plotY)
    local owner = Validation.GetOwnerUsername(ownerUsername)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)
    local ring = Buildings.GetPlotRing and Buildings.GetPlotRing(x, y) or 0
    local nextRingCoords = Buildings.GetRingCoordinates and Buildings.GetRingCoordinates(ring + 1) or {}

    for _, cell in ipairs(nextRingCoords) do
        local dx = math.abs(math.floor(tonumber(cell.x) or 0) - x)
        local dy = math.abs(math.floor(tonumber(cell.y) or 0) - y)
        if dx <= 1 and dy <= 1 then
            local instance = Buildings.FindBuildingAtPlot and Buildings.FindBuildingAtPlot(owner, cell.x, cell.y) or nil
            if instance
                and tostring(instance.buildingType or "") == "Barricade"
                and math.floor(tonumber(instance.level) or 0) > 0 then
                return true
            end
        end
    end

    return false
end

return Buildings