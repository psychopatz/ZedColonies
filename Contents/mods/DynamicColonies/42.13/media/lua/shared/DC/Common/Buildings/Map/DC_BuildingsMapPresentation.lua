DC_Buildings = DC_Buildings or {}

local Buildings = DC_Buildings
local Config = Buildings.Config

local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function summarizeProject(project, sourcePlayer)
    if not project then
        return nil
    end
    local registry = getRegistry()
    local projectDefinition = tostring(project.mode or "") == "install"
        and Config.GetInstallDefinition and Config.GetInstallDefinition(project.buildingType, project.installKey)
        or Config.GetDefinition and Config.GetDefinition(project.buildingType)
        or nil
    local buildingDefinition = Config.GetDefinition and Config.GetDefinition(project.buildingType) or nil
    local worker = registry and registry.GetWorkerForOwnerRaw and registry.GetWorkerForOwnerRaw(project.ownerUsername, project.assignedBuilderID)
        or registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(project.ownerUsername, project.assignedBuilderID)
        or nil
    local progress = math.max(0, tonumber(project.progressWorkPoints) or 0)
    local required = math.max(1, tonumber(project.requiredWorkPoints) or 1)
    local materialStatus = Buildings.GetProjectMaterialStatus and Buildings.GetProjectMaterialStatus(project, sourcePlayer) or {
        hasAll = true,
        entries = {},
        progressRatio = 1
    }
    return {
        projectID = project.projectID,
        buildingType = project.buildingType,
        displayName = projectDefinition and projectDefinition.displayName or tostring(project.buildingType or "Building"),
        iconPath = projectDefinition and projectDefinition.iconPath or buildingDefinition and buildingDefinition.iconPath or nil,
        buildingID = project.buildingID,
        installKey = project.installKey,
        currentLevel = project.currentLevel,
        targetLevel = project.targetLevel,
        assignedBuilderID = project.assignedBuilderID,
        assignedBuilderName = worker and worker.name or (project.assignedBuilderID and tostring(project.assignedBuilderID) or "Unassigned"),
        progressWorkPoints = progress,
        requiredWorkPoints = required,
        progressRatio = math.max(0, math.min(1, progress / required)),
        materialState = project.materialState,
        materialProgressRatio = materialStatus.progressRatio,
        materialEntries = materialStatus.entries,
        status = project.status,
        mode = project.mode,
        plotX = project.plotX,
        plotY = project.plotY,
        failureReason = project.failureReason
    }
end

function Buildings.BuildMapSnapshot(ownerUsername, sourcePlayer)
    local owner = DC_Colony and DC_Colony.Config and DC_Colony.Config.GetOwnerUsername
        and DC_Colony.Config.GetOwnerUsername(ownerUsername)
        or tostring(ownerUsername or "local")
    local visibleRing = Buildings.GetVisibleRing(owner)
    local housing = Buildings.BuildHousingAssignment(owner)
    local occupantsByBuildingID = {}
    for _, summary in ipairs(housing.buildings or {}) do
        occupantsByBuildingID[tostring(summary.buildingID or "")] = summary.occupants or {}
    end

    local activeProjects = Buildings.GetOwnerProjectList(owner)
    local projectsByPlotKey = {}
    for _, project in ipairs(activeProjects) do
        projectsByPlotKey[Buildings.GetPlotKey(project.plotX, project.plotY)] = summarizeProject(project, sourcePlayer)
    end

    local plots = {}
    for y = -visibleRing, visibleRing do
        for x = -visibleRing, visibleRing do
            local plot, state, building = Buildings.GetPlotWithState(owner, x, y)
            local key = Buildings.GetPlotKey(x, y)
            local definition = building and Config.GetDefinition(building.buildingType) or nil
            local project = projectsByPlotKey[key]

            local plotEntry = {
                key = key,
                x = x,
                y = y,
                kind = plot.kind,
                unlocked = plot.unlocked == true,
                state = state,
                availableActions = {
                    canBuild = state == Buildings.MapConstants.PlotStates.Empty and plot.unlocked == true,
                    canInspect = building ~= nil,
                    canUpgrade = false,
                    canInstall = false
                },
                buildOptions = {},
                building = nil,
                project = project
            }

            if state == Buildings.MapConstants.PlotStates.Empty and plot.unlocked == true then
                plotEntry.buildOptions = Buildings.BuildPlotBuildOptions(owner, x, y, sourcePlayer)
            end

            if building then
                local upgradePreview = Buildings.BuildProjectPreview(owner, building.buildingType, "upgrade", x, y, building.buildingID, nil, sourcePlayer)
                local installOptions = Buildings.BuildBuildingInstallOptions and Buildings.BuildBuildingInstallOptions(owner, x, y, building.buildingID, sourcePlayer) or {}
                local canDestroy, destroyReason = Buildings.CanDestroyBuilding(owner, x, y, building.buildingID)
                plotEntry.availableActions.canUpgrade = upgradePreview.available == true
                plotEntry.availableActions.canInstall = #installOptions > 0
                plotEntry.availableActions.canDestroy = canDestroy == true
                plotEntry.building = {
                    buildingID = building.buildingID,
                    buildingType = building.buildingType,
                    displayName = definition and definition.displayName or building.buildingType,
                    iconPath = definition and definition.iconPath or nil,
                    level = math.max(0, math.floor(tonumber(building.level) or 0)),
                    plotX = x,
                    plotY = y,
                    isInfinite = definition and definition.isInfinite == true or false,
                    maxLevel = definition and definition.maxLevel or 0,
                    installs = Buildings.GetBuildingInstallCounts and Buildings.GetBuildingInstallCounts(building) or {},
                    installOptions = installOptions,
                    warehouseCapacityContribution = Buildings.GetWarehouseBuildingCapacityContribution and Buildings.GetWarehouseBuildingCapacityContribution(building) or 0,
                    occupants = occupantsByBuildingID[tostring(building.buildingID or "")] or {},
                    upgradePreview = upgradePreview,
                    canDestroy = canDestroy == true,
                    destroyReason = destroyReason
                }
            end

            plots[#plots + 1] = plotEntry
        end
    end

    return {
        bounds = {
            minX = -visibleRing,
            maxX = visibleRing,
            minY = -visibleRing,
            maxY = visibleRing
        },
        visibleRing = visibleRing,
        currentRing = math.max(1, math.floor(tonumber(Buildings.GetMapDataForOwner(owner).currentRing) or 1)),
        nextUnlockDirection = Buildings.GetMapDataForOwner(owner).nextUnlockDirection,
        plots = plots
    }
end

return Buildings
