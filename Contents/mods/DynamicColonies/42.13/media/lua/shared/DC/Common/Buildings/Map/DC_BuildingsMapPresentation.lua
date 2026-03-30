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

local function summarizeProject(project, sourcePlayer, availableCounts)
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
    local materialStatus = Buildings.GetProjectMaterialStatus and Buildings.GetProjectMaterialStatus(project, sourcePlayer, availableCounts) or {
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
    local housing = Buildings.BuildHousingAssignment(owner)
    local territory = Buildings.GetTerritorySummary and Buildings.GetTerritorySummary(owner) or {
        headquartersLevel = 0,
        securedPerimeterRing = 0,
        currentFrontierRing = 1,
        nextFrontierRing = 1,
        frontierExpansionAvailable = false,
        frontierRequiredHQLevel = 1,
        unlockedPlotCount = 0,
        activeBarricadeCount = 0,
        maxActiveBarricades = 0
    }
    local occupantsByBuildingID = {}
    for _, summary in ipairs(housing.buildings or {}) do
        occupantsByBuildingID[tostring(summary.buildingID or "")] = summary.occupants or {}
    end

    local activeProjects = Buildings.GetOwnerProjectList(owner)
    local availableCounts = Internal and Internal.GetAvailableMaterialCounts and Internal.GetAvailableMaterialCounts(owner, sourcePlayer) or nil
    local projectsByPlotKey = {}
    local visiblePlotKeys = {}
    for _, project in ipairs(activeProjects) do
        projectsByPlotKey[Buildings.GetPlotKey(project.plotX, project.plotY)] = summarizeProject(project, sourcePlayer, availableCounts)
        visiblePlotKeys[Buildings.GetPlotKey(project.plotX, project.plotY)] = {
            x = math.floor(tonumber(project.plotX) or 0),
            y = math.floor(tonumber(project.plotY) or 0)
        }
    end

    for _, plot in ipairs(Buildings.GetUnlockedPlotEntries and Buildings.GetUnlockedPlotEntries(owner) or {}) do
        visiblePlotKeys[Buildings.GetPlotKey(plot.x, plot.y)] = {
            x = math.floor(tonumber(plot.x) or 0),
            y = math.floor(tonumber(plot.y) or 0)
        }
    end

    for _, plot in ipairs(Buildings.GetFrontierCandidatePlots and Buildings.GetFrontierCandidatePlots(owner) or {}) do
        visiblePlotKeys[Buildings.GetPlotKey(plot.x, plot.y)] = {
            x = math.floor(tonumber(plot.x) or 0),
            y = math.floor(tonumber(plot.y) or 0)
        }
    end

    local plots = {}
    for _, entry in pairs(visiblePlotKeys) do
        local x = math.floor(tonumber(entry and entry.x) or 0)
        local y = math.floor(tonumber(entry and entry.y) or 0)
        local plot, state, building = Buildings.GetPlotWithState(owner, x, y)
        local key = Buildings.GetPlotKey(x, y)
        local definition = building and Config.GetDefinition(building.buildingType) or nil
        local project = projectsByPlotKey[key]
        local plotRing = Buildings.GetPlotRing and Buildings.GetPlotRing(x, y) or 0
        local isFrontierPlot = Buildings.IsFrontierPlot and Buildings.IsFrontierPlot(owner, x, y) or false
        local isSafeTile = plot.unlocked == true
            and project == nil
            and building == nil
            and tostring(plot.kind or "") == tostring(Buildings.MapConstants.PlotKinds.Standard)
            and plotRing <= math.max(0, tonumber(territory.securedPerimeterRing) or 0)
        local canEvaluateBuildOptions = (tostring(state or "") == tostring(Buildings.MapConstants.PlotStates.Empty) and plot.unlocked == true)
            or (tostring(state or "") == tostring(Buildings.MapConstants.PlotStates.Locked) and isFrontierPlot)
        local buildOptions = canEvaluateBuildOptions and Buildings.BuildPlotBuildOptions and Buildings.BuildPlotBuildOptions(owner, x, y, sourcePlayer, availableCounts) or {}

        local plotEntry = {
            key = key,
            x = x,
            y = y,
            ring = plotRing,
            kind = plot.kind,
            unlocked = plot.unlocked == true,
            safeTile = isSafeTile,
            frontierCandidate = isFrontierPlot,
            territory = shallowCopy(territory),
            state = state,
            availableActions = {
                canBuild = canEvaluateBuildOptions and #buildOptions > 0,
                canInspect = building ~= nil or project ~= nil,
                canUpgrade = false,
                canInstall = false
            },
            buildOptions = buildOptions,
            building = nil,
            project = project
        }

        if building then
            local upgradePreview = Buildings.BuildProjectPreview(owner, building.buildingType, "upgrade", x, y, building.buildingID, nil, sourcePlayer, availableCounts)
            local installOptions = Buildings.BuildBuildingInstallOptions and Buildings.BuildBuildingInstallOptions(owner, x, y, building.buildingID, sourcePlayer, availableCounts) or {}
            local canDestroy, destroyReason = Buildings.CanDestroyBuilding(owner, x, y, building.buildingID)
            local currentLevelDefinition = Config.GetLevelDefinition and Config.GetLevelDefinition(building.buildingType, building.level) or nil
            local resourcesApi = DC_Colony and DC_Colony.Resources or nil
            local buildingMetrics = resourcesApi and resourcesApi.GetBuildingMetrics and resourcesApi.GetBuildingMetrics(owner, building) or {}
            if tostring(building.buildingType or "") == "Barricade"
                and Config.Frontier
                and Config.Frontier.GetBarricadeLevelDefinition then
                currentLevelDefinition = Config.Frontier.GetBarricadeLevelDefinition(building.level, x, y)
            end
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
                barricadeHP = currentLevelDefinition and currentLevelDefinition.effects and currentLevelDefinition.effects.barricadeHP or nil,
                occupants = occupantsByBuildingID[tostring(building.buildingID or "")] or {},
                upgradePreview = upgradePreview,
                canDestroy = canDestroy == true,
                destroyReason = destroyReason
            }
            for key, value in pairs(buildingMetrics or {}) do
                plotEntry.building[key] = value
            end
        end

        plots[#plots + 1] = plotEntry
    end

    table.sort(plots, function(a, b)
        if tonumber(a.y) == tonumber(b.y) then
            return tonumber(a.x) < tonumber(b.x)
        end
        return tonumber(a.y) < tonumber(b.y)
    end)

    local bounds = Buildings.BuildVisibleBounds and Buildings.BuildVisibleBounds(plots) or {
        minX = 0,
        maxX = 0,
        minY = 0,
        maxY = 0
    }

    return {
        bounds = bounds,
        unlockedBounds = bounds,
        headquartersLevel = territory.headquartersLevel,
        securedPerimeterRing = territory.securedPerimeterRing,
        currentFrontierRing = territory.currentFrontierRing,
        nextFrontierRing = territory.nextFrontierRing,
        frontierExpansionAvailable = territory.frontierExpansionAvailable,
        frontierRequiredHQLevel = territory.frontierRequiredHQLevel,
        unlockedPlotCount = territory.unlockedPlotCount,
        activeBarricadeCount = territory.activeBarricadeCount,
        maxActiveBarricades = territory.maxActiveBarricades,
        plots = plots
    }
end

return Buildings
