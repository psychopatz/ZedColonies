DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Projects = Internal.Projects or {}

Internal.Projects = Projects

function Buildings.CompleteProject(project)
    if not project then
        return nil
    end

    local labourConfig = Projects.GetColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(project.ownerUsername) or tostring(project.ownerUsername or "local")
    local instance = project.buildingID and Buildings.FindBuildingForOwner(owner, project.buildingID) or nil
    if tostring(project.mode or "") == "install" then
        if not instance then
            project.status = "Failed"
            project.failureReason = "The target building no longer exists."
            Buildings.Save()
            return nil
        end

        local installKey = tostring(project.installKey or "")
        Buildings.SetBuildingInstallCount(instance, installKey, Buildings.GetBuildingInstallCount(instance, installKey) + 1)
    else
        if not instance then
            instance = Buildings.CreateBuildingInstance(owner, project.buildingType, 0, project.plotX, project.plotY)
            project.buildingID = instance.buildingID
        end

        instance.level = math.max(0, math.floor(tonumber(project.targetLevel) or tonumber(instance.level) or 0))
        instance.plotX = math.floor(tonumber(project.plotX) or 0)
        instance.plotY = math.floor(tonumber(project.plotY) or 0)
        Buildings.UnlockPlotForOwner(owner, instance.plotX, instance.plotY, instance.plotX == 0 and instance.plotY == 0 and Buildings.MapConstants.PlotKinds.HQOnly or Buildings.MapConstants.PlotKinds.Standard)

        if tostring(project.buildingType or "") == "Headquarters"
            and Buildings.ExpandMapForHeadquartersUpgrade then
            Buildings.ExpandMapForHeadquartersUpgrade(owner)
        end

        if tostring(project.buildingType or "") == "Barricade"
            and Buildings.TryFinalizeBarricadeRing
            and Buildings.GetPlotRing then
            Buildings.TryFinalizeBarricadeRing(owner, Buildings.GetPlotRing(instance.plotX, instance.plotY))
        end
    end

    project.status = "Completed"
    Buildings.Save()
    return instance
end

function Buildings.FailProject(project, reason)
    if not project then
        return
    end
    project.status = "Failed"
    project.failureReason = tostring(reason or "Unknown")
    Buildings.Save()
end

function Buildings.DestroyBuilding(ownerUsername, plotX, plotY, buildingID)
    local labourConfig = Projects.GetColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local ok, reason, building = Buildings.CanDestroyBuilding(owner, plotX, plotY, buildingID)
    if not ok then
        return false, reason, nil
    end

    local buildings = Buildings.GetBuildingsForOwner(owner)
    for index = #buildings, 1, -1 do
        local instance = buildings[index]
        if tostring(instance.buildingID or "") == tostring(building.buildingID or "") then
            table.remove(buildings, index)
            Buildings.Save()
            return true, nil, building
        end
    end

    return false, "That building could not be found anymore.", nil
end

return Buildings