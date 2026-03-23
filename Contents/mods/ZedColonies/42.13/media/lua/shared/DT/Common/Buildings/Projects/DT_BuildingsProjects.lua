DT_Buildings = DT_Buildings or {}
DT_Buildings.Internal = DT_Buildings.Internal or {}

local Buildings = DT_Buildings
local Config = Buildings.Config
local Internal = Buildings.Internal

local function getLabourConfig()
    return DT_Labour and DT_Labour.Config or {}
end

local function getRegistry()
    return DT_Labour and DT_Labour.Registry or nil
end

local function getSkills()
    return DT_Labour and DT_Labour.Skills or nil
end

function Buildings.StartProject(ownerUsername, workerID, buildingType, mode, plotX, plotY, buildingID, installKey)
    local labourConfig = getLabourConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    local registry = getRegistry()
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, workerID) or nil
    local canBuild, workerReason = Buildings.CanWorkerBuild(worker)
    if not canBuild then
        return false, workerReason, nil
    end

    local target, targetReason = Buildings.ResolveProjectTarget(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    if not target then
        return false, targetReason, nil
    end

    local projectDefinition = target.mode == "install"
        and Config.GetInstallDefinition(buildingType, target.installKey)
        or Config.GetLevelDefinition(buildingType, target.targetLevel)
    if not projectDefinition or projectDefinition.enabled == false then
        return false, "That level is not available yet.", nil
    end

    local ownerProjects = Buildings.GetProjectsForOwner(owner)
    local project = {
        projectID = "project_" .. tostring(Buildings.NextID("project")),
        ownerUsername = owner,
        buildingType = tostring(buildingType or ""),
        buildingID = target.instance and target.instance.buildingID or nil,
        installKey = target.installKey,
        currentLevel = math.max(0, math.floor(tonumber(target.currentLevel) or 0)),
        targetLevel = math.max(1, math.floor(tonumber(target.targetLevel) or 1)),
        assignedBuilderID = worker.workerID,
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
        startedWorldHours = (labourConfig.GetCurrentWorldHours and labourConfig.GetCurrentWorldHours()) or 0,
        failureReason = nil
    }
    ownerProjects[project.projectID] = project
    Buildings.RefreshProjectMaterialState(project)
    Buildings.Save()
    return true, nil, project
end

function Buildings.CompleteProject(project)
    if not project then
        return nil
    end

    local labourConfig = getLabourConfig()
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

        if tostring(project.buildingType or "") == "Headquarters" and tostring(project.mode or "") == "upgrade" then
            Buildings.ExpandMapForHeadquartersUpgrade(owner)
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
    local labourConfig = getLabourConfig()
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
