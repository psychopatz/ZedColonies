DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Buildings.Internal

local function getColonyConfig()
    return DC_Colony and DC_Colony.Config or {}
end

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getSkills()
    return DC_Colony and DC_Colony.Skills or nil
end

local function getProjectDefinitionForTarget(buildingType, target)
    if target and target.mode == "install" then
        return Config.GetInstallDefinition(buildingType, target.installKey)
    end
    if tostring(buildingType or "") == "Barricade"
        and Config.Frontier
        and Config.Frontier.GetBarricadeLevelDefinition then
        return Config.Frontier.GetBarricadeLevelDefinition(target and target.targetLevel or 1, target and target.plotX or 0, target and target.plotY or 0)
    end
    return Config.GetLevelDefinition(buildingType, target and target.targetLevel or 1)
end

local function createProjectRecord(owner, worker, buildingType, target, projectDefinition)
    local labourConfig = getColonyConfig()
    return {
        projectID = "project_" .. tostring(Buildings.NextID("project")),
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

local function releaseWorkerFromCurrentProject(worker, options)
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

function Buildings.EnsureInitialHeadquartersProject(ownerUsername)
    local labourConfig = getColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    if Buildings.OwnerHasHeadquarters and Buildings.OwnerHasHeadquarters(owner) then
        return nil
    end

    local hasAnyCompletedBuilding = false
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(owner) or {}) do
        if math.floor(tonumber(instance and instance.level) or 0) > 0 then
            hasAnyCompletedBuilding = true
            break
        end
    end
    if hasAnyCompletedBuilding then
        return nil
    end

    for _, project in pairs(Buildings.GetProjectsForOwner(owner) or {}) do
        if tostring(project and project.status or "") == "Active" then
            return nil
        end
    end

    local plot, state = Buildings.GetPlotWithState(owner, 0, 0)
    local expectedState = Buildings.MapConstants
        and Buildings.MapConstants.PlotStates
        and Buildings.MapConstants.PlotStates.Empty
        or "Empty"
    local expectedKind = Buildings.MapConstants
        and Buildings.MapConstants.PlotKinds
        and Buildings.MapConstants.PlotKinds.HQOnly
        or "HQOnly"
    if not plot or tostring(state or "") ~= tostring(expectedState) then
        return nil
    end
    if plot.unlocked ~= true or tostring(plot.kind or "") ~= tostring(expectedKind) then
        return nil
    end

    local ok, _, project = Buildings.QueueProject(owner, "Headquarters", "build", 0, 0, nil, nil)
    if ok then
        return project
    end

    return nil
end

function Buildings.StartProject(ownerUsername, workerID, buildingType, mode, plotX, plotY, buildingID, installKey)
    local labourConfig = getColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local registry = getRegistry()
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

    local projectDefinition = getProjectDefinitionForTarget(buildingType, target)
    if not projectDefinition or projectDefinition.enabled == false then
        return false, "That level is not available yet.", nil
    end

    local ownerProjects = Buildings.GetProjectsForOwner(owner)
    releaseWorkerFromCurrentProject(worker)
    local project = createProjectRecord(owner, worker, buildingType, target, projectDefinition)
    ownerProjects[project.projectID] = project
    Buildings.RefreshProjectMaterialState(project)
    Buildings.Save()
    return true, nil, project
end

function Buildings.QueueProject(ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey)
    local labourConfig = getColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local target, targetReason = Buildings.ResolveProjectTarget(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    if not target then
        return false, targetReason, nil
    end

    local projectDefinition = getProjectDefinitionForTarget(buildingType, target)
    if not projectDefinition or projectDefinition.enabled == false then
        return false, "That level is not available yet.", nil
    end

    local ownerProjects = Buildings.GetProjectsForOwner(owner)
    local project = createProjectRecord(owner, nil, buildingType, target, projectDefinition)
    ownerProjects[project.projectID] = project
    Buildings.RefreshProjectMaterialState(project)
    Buildings.Save()
    return true, nil, project
end

function Buildings.ReassignProjectBuilder(ownerUsername, projectID, workerID)
    local labourConfig = getColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local project = Buildings.GetProjectByID and Buildings.GetProjectByID(owner, projectID) or nil
    if not project or tostring(project.status or "") ~= "Active" then
        return false, "That project is no longer active.", nil, nil, nil
    end

    local registry = getRegistry()
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

    releaseWorkerFromCurrentProject(nextWorker, {
        allowedProjectID = project.projectID
    })
    project.assignedBuilderID = nextWorker.workerID
    Buildings.Save()
    return true, nil, project, currentWorker, nextWorker
end

function Buildings.CompleteProject(project)
    if not project then
        return nil
    end

    local labourConfig = getColonyConfig()
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

function Buildings.ProcessWorkerProject(worker, currentHour, workableHours, speedMultiplier)
    local project = Buildings.GetProjectForWorker(worker)
    if not project or project.status ~= "Active" then
        return {
            hadProject = false,
            didWork = false,
            completed = false
        }
    end

    local materialStatus = Buildings.RefreshProjectMaterialState and Buildings.RefreshProjectMaterialState(project) or nil
    if materialStatus and materialStatus.hasAll ~= true then
        return {
            hadProject = true,
            didWork = false,
            completed = false,
            waitingForMaterials = true,
            materialStatus = materialStatus,
            project = project
        }
    end

    local progressGain = math.max(
        0,
        (math.max(0, tonumber(workableHours) or 0) * Config.GetBuilderBaseWorkPointsPerHour() * math.max(0.01, tonumber(speedMultiplier) or 1))
    )
    project.progressWorkPoints = math.max(0, tonumber(project.progressWorkPoints) or 0) + progressGain

    local result = {
        hadProject = true,
        didWork = progressGain > 0,
        completed = false,
        project = project
    }

    if project.progressWorkPoints + 0.0001 >= math.max(1, tonumber(project.requiredWorkPoints) or 1) then
        result.completed = true
        result.instance = Buildings.CompleteProject(project)

        local skills = getSkills()
        if skills and skills.GrantXP then
            result.xpResult = skills.GrantXP(worker, "Construction", project.xpReward or 0)
        end
    end

    return result
end

function Buildings.GetOwnerProjectList(ownerUsername)
    if Buildings.RefreshOwnerProjectMaterials then
        Buildings.RefreshOwnerProjectMaterials(ownerUsername)
    end

    local projects = {}
    for _, project in pairs(Buildings.GetProjectsForOwner(ownerUsername)) do
        if tostring(project.status or "") == "Active" then
            projects[#projects + 1] = project
        end
    end

    table.sort(projects, function(a, b)
        return tostring(a.projectID or "") < tostring(b.projectID or "")
    end)
    return projects
end

function Buildings.DestroyBuilding(ownerUsername, plotX, plotY, buildingID)
    local labourConfig = getColonyConfig()
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
