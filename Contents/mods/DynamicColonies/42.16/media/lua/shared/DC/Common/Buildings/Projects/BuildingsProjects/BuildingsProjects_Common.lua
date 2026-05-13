DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Projects = Internal.Projects or {}

Internal.Projects = Projects

function Projects.GetColonyConfig()
    return DC_Colony and DC_Colony.Config or {}
end

function Projects.GetRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

function Projects.GetSkills()
    return DC_Colony and DC_Colony.Skills or nil
end

function Projects.GetProjectDefinitionForTarget(buildingType, target)
    local config = Projects.Config or Buildings.Config
    if target and target.mode == "install" then
        return config.GetInstallDefinition(buildingType, target.installKey)
    end
    if tostring(buildingType or "") == "Barricade"
        and config.Frontier
        and config.Frontier.GetBarricadeLevelDefinition then
        return config.Frontier.GetBarricadeLevelDefinition(target and target.targetLevel or 1, target and target.plotX or 0, target and target.plotY or 0)
    end
    return config.GetLevelDefinition(buildingType, target and target.targetLevel or 1)
end

function Projects.CreateProjectRecord(owner, worker, buildingType, target, projectDefinition)
    local labourConfig = Projects.GetColonyConfig()
    return {
        projectID = Buildings.NextID("project", owner),
        ownerUsername = owner,
        buildingType = tostring(buildingType or ""),
        buildingID = target.instance and target.instance.buildingID or nil,
        installKey = target.installKey,
        currentLevel = math.max(0, math.floor(tonumber(target.currentLevel) or 0)),
        targetLevel = math.max(1, math.floor(tonumber(target.targetLevel) or 1)),
        assignedBuilderID = worker and worker.workerID or nil,
        progressWorkPoints = 0,
        requiredWorkPoints = math.max(1, math.floor(tonumber(projectDefinition.workPoints) or 1)),
        recipe = Internal.CopyDeep(projectDefinition.recipe or {}),
        xpReward = math.max(0, math.floor(tonumber(projectDefinition.xpReward) or 0)),
        status = "Active",
        mode = tostring(target.mode or "build"),
        materialTrackingVersion = 1,
        materialCounts = {},
        materialState = "Stalled",
        materialProgressRatio = 0,
        plotX = math.floor(tonumber(target.plotX) or 0),
        plotY = math.floor(tonumber(target.plotY) or 0),
        startedWorldHours = (labourConfig.GetCurrentWorldHours and labourConfig.GetCurrentWorldHours()) or (labourConfig.GetCurrentHour and labourConfig.GetCurrentHour()) or 0,
        failureReason = nil
    }
end

function Projects.ReleaseWorkerFromCurrentProject(worker, options)
    options = type(options) == "table" and options or {}
    if not worker or not worker.workerID then
        return nil
    end

    local currentProject = Buildings.GetProjectForWorker and Buildings.GetProjectForWorker(worker) or nil
    if not currentProject then
        return nil
    end
    if not (Buildings.CanReleaseBuilderFromProject and Buildings.CanReleaseBuilderFromProject(worker, currentProject, options)) then
        return nil
    end

    currentProject.assignedBuilderID = nil
    return currentProject
end

function Projects.GetProjectSequence(project)
    local suffix = tostring(project and project.projectID or ""):match("(%d+)$")
    return math.max(0, math.floor(tonumber(suffix) or 0))
end

return Buildings