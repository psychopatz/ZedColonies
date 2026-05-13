DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Projects = Internal.Projects or {}

Internal.Projects = Projects

function Buildings.StartProject(ownerUsername, workerID, buildingType, mode, plotX, plotY, buildingID, installKey)
    local labourConfig = Projects.GetColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local registry = Projects.GetRegistry()
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, workerID) or nil
    local canBuild, workerReason = Buildings.CanWorkerBuild(worker, {
        allowProjectRelease = true
    })
    if not canBuild then
        return false, workerReason, nil
    end

    local target, targetReason = Buildings.ResolveProjectTarget(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    if not target then
        return false, targetReason, nil
    end

    local projectDefinition = Projects.GetProjectDefinitionForTarget(buildingType, target)
    if not projectDefinition or projectDefinition.enabled == false then
        return false, "That level is not available yet.", nil
    end

    local ownerProjects = Buildings.GetProjectsForOwner(owner)
    Projects.ReleaseWorkerFromCurrentProject(worker)
    local project = Projects.CreateProjectRecord(owner, worker, buildingType, target, projectDefinition)
    ownerProjects[project.projectID] = project
    Buildings.RefreshProjectMaterialState(project)
    Buildings.Save()
    return true, nil, project
end

function Buildings.QueueProject(ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey)
    local labourConfig = Projects.GetColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local target, targetReason = Buildings.ResolveProjectTarget(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    if not target then
        return false, targetReason, nil
    end

    local projectDefinition = Projects.GetProjectDefinitionForTarget(buildingType, target)
    if not projectDefinition or projectDefinition.enabled == false then
        return false, "That level is not available yet.", nil
    end

    local ownerProjects = Buildings.GetProjectsForOwner(owner)
    local project = Projects.CreateProjectRecord(owner, nil, buildingType, target, projectDefinition)
    ownerProjects[project.projectID] = project
    Buildings.RefreshProjectMaterialState(project)
    Buildings.Save()
    return true, nil, project
end

function Buildings.ReassignProjectBuilder(ownerUsername, projectID, workerID)
    local labourConfig = Projects.GetColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local project = Buildings.GetProjectByID and Buildings.GetProjectByID(owner, projectID) or nil
    if not project or tostring(project.status or "") ~= "Active" then
        return false, "That project is no longer active.", nil, nil, nil
    end

    local registry = Projects.GetRegistry()
    local currentWorker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, project.assignedBuilderID) or nil
    local nextWorker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, workerID) or nil
    local canBuild, workerReason = Buildings.CanWorkerBuild(nextWorker, {
        allowedProjectID = project.projectID,
        allowProjectRelease = true
    })
    if not canBuild then
        return false, workerReason, project, currentWorker, nextWorker
    end

    if tostring(project.assignedBuilderID or "") == tostring(nextWorker.workerID or "") then
        return true, nil, project, currentWorker, nextWorker
    end

    Projects.ReleaseWorkerFromCurrentProject(nextWorker, {
        allowedProjectID = project.projectID
    })
    project.assignedBuilderID = nextWorker.workerID
    Buildings.Save()
    return true, nil, project, currentWorker, nextWorker
end

return Buildings