DT_Buildings = DT_Buildings or {}

local Buildings = DT_Buildings
local Config = Buildings.Config
local Constants = Buildings.MapConstants

function Buildings.GetHeadquartersInstance(ownerUsername)
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if tostring(instance.buildingType or "") == "Headquarters" and math.floor(tonumber(instance.level) or 0) > 0 then
            return instance
        end
    end
    return nil
end

function Buildings.OwnerHasHeadquarters(ownerUsername)
    return Buildings.GetHeadquartersInstance(ownerUsername) ~= nil
end

function Buildings.GetActiveProjectAtPlot(ownerUsername, plotX, plotY)
    local wantedX = math.floor(tonumber(plotX) or 0)
    local wantedY = math.floor(tonumber(plotY) or 0)
    for _, project in pairs(Buildings.GetProjectsForOwner(ownerUsername)) do
        if tostring(project.status or "") == "Active"
            and math.floor(tonumber(project.plotX) or 0) == wantedX
            and math.floor(tonumber(project.plotY) or 0) == wantedY then
            return project
        end
    end
    return nil
end

function Buildings.GetPlotWithState(ownerUsername, plotX, plotY)
    local plot = Buildings.BuildVisiblePlot(ownerUsername, plotX, plotY)
    local building = Buildings.FindBuildingAtPlot(ownerUsername, plotX, plotY)
    local project = Buildings.GetActiveProjectAtPlot(ownerUsername, plotX, plotY)
    local state = Constants.PlotStates.Locked

    if plot.unlocked == true then
        state = Constants.PlotStates.Empty
        if building and math.floor(tonumber(building.level) or 0) > 0 then
            state = Constants.PlotStates.Built
        end
        if project then
            state = Constants.PlotStates.Reserved
        end
    end

    return plot, state, building, project
end

function Buildings.CanUpgradeBuilding(instance)
    if not instance then
        return false
    end
    local nextLevel = math.max(1, math.floor(tonumber(instance.level) or 0) + 1)
    local nextDefinition = Config.GetLevelDefinition(instance.buildingType, nextLevel)
    return nextDefinition and nextDefinition.enabled == true or false
end

return Buildings
