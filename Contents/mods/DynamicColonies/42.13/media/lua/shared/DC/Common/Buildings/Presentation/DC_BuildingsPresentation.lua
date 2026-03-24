DC_Buildings = DC_Buildings or {}

local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Buildings.Internal

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

local function getDisplayName(fullType)
    local registry = getRegistry()
    local internal = registry and registry.Internal or nil
    return internal and internal.GetDisplayNameForFullType and internal.GetDisplayNameForFullType(fullType) or tostring(fullType or "Unknown")
end

function Buildings.BuildOwnerSnapshot(ownerUsername, sourcePlayer)
    local owner = DC_Colony and DC_Colony.Config and DC_Colony.Config.GetOwnerUsername
        and DC_Colony.Config.GetOwnerUsername(ownerUsername)
        or tostring(ownerUsername or "local")
    local ownerData = Buildings.CopyOwnerData(owner)
    local warehouseApi = DC_Colony and DC_Colony.Warehouse or nil
    local housing = Buildings.BuildHousingAssignment(owner)
    local medical = Buildings.BuildInfirmaryAssignment and Buildings.BuildInfirmaryAssignment(owner) or nil
    local projectList = Buildings.GetOwnerProjectList(owner)
    local availableCounts = Internal and Internal.GetAvailableMaterialCounts and Internal.GetAvailableMaterialCounts(owner, sourcePlayer) or nil
    local buildings = {}

    for _, definition in ipairs(Config.GetDefinitionList and Config.GetDefinitionList() or {}) do
        local instances = {}
        local currentCount = 0
        for _, instance in ipairs(ownerData.buildings or {}) do
            if tostring(instance.buildingType or "") == tostring(definition.buildingType) then
                currentCount = currentCount + 1
                instances[#instances + 1] = {
                    buildingID = instance.buildingID,
                    buildingType = instance.buildingType,
                    level = math.max(0, math.floor(tonumber(instance.level) or 0)),
                    plotX = math.floor(tonumber(instance.plotX) or 0),
                    plotY = math.floor(tonumber(instance.plotY) or 0),
                    installs = Buildings.GetBuildingInstallCounts and Buildings.GetBuildingInstallCounts(instance) or {}
                }
            end
        end

        table.sort(instances, function(a, b)
            if tonumber(a.level) == tonumber(b.level) then
                return tostring(a.buildingID or "") < tostring(b.buildingID or "")
            end
            return tonumber(a.level) < tonumber(b.level)
        end)

        local levels = {}
        local highestLevel = 0
        for _, instance in ipairs(instances) do
            highestLevel = math.max(highestLevel, math.floor(tonumber(instance.level) or 0))
        end
        local previewLevelCap = definition.isInfinite == true and math.max(3, highestLevel + 1) or math.max(0, math.floor(tonumber(definition.maxLevel) or 0))

        for level = 1, previewLevelCap do
            local levelDefinition = Config.GetLevelDefinition(definition.buildingType, level)
            if levelDefinition then
                local recipe = {}
                for _, entry in ipairs(levelDefinition.recipe or {}) do
                    recipe[#recipe + 1] = {
                        fullType = entry.fullType,
                        displayName = getDisplayName(entry.fullType),
                        count = entry.count
                    }
                end
                levels[#levels + 1] = {
                    level = level,
                    enabled = levelDefinition.enabled == true,
                    workPoints = levelDefinition.workPoints,
                    recipe = recipe,
                    effects = shallowCopy(levelDefinition.effects)
                }
            end
        end

        buildings[#buildings + 1] = {
            buildingType = definition.buildingType,
            displayName = definition.displayName,
            iconPath = definition.iconPath,
            enabled = definition.enabled == true,
            isInfinite = definition.isInfinite == true,
            maxLevel = definition.maxLevel,
            currentCount = currentCount,
            instances = instances,
            levels = levels
        }
    end

    local activeProjects = {}
    for _, project in ipairs(projectList) do
        local materialStatus = Buildings.GetProjectMaterialStatus and Buildings.GetProjectMaterialStatus(project, sourcePlayer, availableCounts) or {
            hasAll = true,
            entries = {},
            progressRatio = 1
        }
        local workerName = nil
        local registry = getRegistry()
        local worker = registry and registry.GetWorkerForOwnerRaw and registry.GetWorkerForOwnerRaw(owner, project.assignedBuilderID)
            or registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, project.assignedBuilderID)
            or nil
        workerName = worker and worker.name or (project.assignedBuilderID and tostring(project.assignedBuilderID) or "Unassigned")
        local projectDisplayName = nil
        if tostring(project.mode or "") == "install" and Config.GetInstallDefinition then
            local installDefinition = Config.GetInstallDefinition(project.buildingType, project.installKey)
            projectDisplayName = installDefinition and installDefinition.displayName or project.installKey
        else
            local definition = Config.GetDefinition and Config.GetDefinition(project.buildingType) or nil
            projectDisplayName = definition and definition.displayName or project.buildingType
        end
        activeProjects[#activeProjects + 1] = {
            projectID = project.projectID,
            buildingType = project.buildingType,
            displayName = projectDisplayName or project.buildingType,
            buildingID = project.buildingID,
            installKey = project.installKey,
            currentLevel = project.currentLevel,
            targetLevel = project.targetLevel,
            assignedBuilderID = project.assignedBuilderID,
            assignedBuilderName = workerName,
            progressWorkPoints = project.progressWorkPoints,
            requiredWorkPoints = project.requiredWorkPoints,
            status = project.status,
            mode = project.mode,
            materialState = project.materialState,
            materialProgressRatio = materialStatus.progressRatio,
            materialEntries = materialStatus.entries,
            failureReason = project.failureReason,
            plotX = project.plotX,
            plotY = project.plotY
        }
    end

    return {
        ownerUsername = owner,
        buildings = buildings,
        activeProjects = activeProjects,
        warehouse = warehouseApi and warehouseApi.GetClientSummary and warehouseApi.GetClientSummary(owner) or nil,
        housing = {
            capacity = housing.capacity,
            housedCount = housing.housedCount,
            unhousedCount = housing.unhousedCount,
            livingWorkers = housing.livingWorkers,
            buildings = housing.buildings
        },
        medical = medical and {
            totalCapacity = medical.totalCapacity,
            assignedCount = medical.assignedCount,
            sleepingWorkers = medical.sleepingWorkers,
            doctorCount = medical.doctorCount,
            doctorCoverageSlots = medical.doctorCoverageSlots,
            doctorCoveredCount = medical.doctorCoveredCount,
            treatmentHourBudget = medical.treatmentHourBudget,
            hasMedicalSupplies = medical.hasMedicalSupplies,
            buildings = medical.buildings
        } or nil,
        map = Buildings.BuildMapSnapshot(owner, sourcePlayer)
    }
end

function Buildings.GetOwnerSummary(ownerUsername)
    local snapshot = Buildings.BuildOwnerSnapshot(ownerUsername)
    return {
        ownerUsername = snapshot.ownerUsername,
        housing = shallowCopy(snapshot.housing),
        medical = shallowCopy(snapshot.medical),
        activeProjectCount = #snapshot.activeProjects,
        buildingCounts = (function()
            local counts = {}
            for _, entry in ipairs(snapshot.buildings or {}) do
                counts[entry.buildingType] = entry.currentCount
            end
            return counts
        end)()
    }
end

function Buildings.ApplyWorkerState(worker)
    if not worker or not worker.workerID then
        return
    end

    local housing = Buildings.GetWorkerHousing(worker.ownerUsername, worker.workerID)
    local infirmary = Buildings.GetWorkerInfirmary and Buildings.GetWorkerInfirmary(worker.ownerUsername, worker.workerID) or nil
    worker.housingState = housing.housingState
    worker.housingBuildingID = housing.buildingID
    worker.housingBuildingType = housing.buildingType
    worker.housingBuildingLevel = housing.buildingLevel
    worker.housingRecoveryMultiplier = housing.recoveryMultiplier
    worker.infirmaryBuildingID = infirmary and infirmary.buildingID or nil
    worker.infirmaryBuildingType = infirmary and infirmary.buildingType or nil
    worker.infirmaryBuildingLevel = infirmary and infirmary.buildingLevel or 0
    worker.infirmaryBedAssigned = infirmary and infirmary.assigned == true or false
    worker.doctorCovered = infirmary and infirmary.doctorCovered == true or false

    if DC_Colony and DC_Colony.Energy and DC_Colony.Energy.SetRecoverySources then
        DC_Colony.Energy.SetRecoverySources(worker, {
            base = 1.0,
            housing = housing.recoveryMultiplier
        })
    end

    local project = Buildings.GetProjectForWorker(worker)
    if project then
        worker.assignedProjectID = project.projectID
        worker.assignedProjectBuildingType = project.buildingType
        worker.assignedProjectBuildingID = project.buildingID
        worker.assignedProjectTargetLevel = project.targetLevel
        worker.assignedProjectMaterialState = project.materialState
        worker.assignedProjectProgress = project.progressWorkPoints
        worker.assignedProjectRequired = project.requiredWorkPoints
        worker.workProgress = project.progressWorkPoints
        worker.workTarget = project.requiredWorkPoints
        worker.workCycleHours = project.requiredWorkPoints
    else
        worker.assignedProjectID = nil
        worker.assignedProjectBuildingType = nil
        worker.assignedProjectBuildingID = nil
        worker.assignedProjectTargetLevel = nil
        worker.assignedProjectMaterialState = nil
        worker.assignedProjectProgress = nil
        worker.assignedProjectRequired = nil
    end
end

return Buildings
