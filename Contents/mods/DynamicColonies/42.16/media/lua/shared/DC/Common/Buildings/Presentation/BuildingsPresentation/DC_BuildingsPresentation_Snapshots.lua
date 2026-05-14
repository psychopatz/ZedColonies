DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Buildings.Internal
local Presentation = Buildings.Internal.Presentation or {}
local modules = Presentation.Modules or {}
local helpers = Presentation.Helpers or {}

Buildings.Internal.Presentation = Presentation
Presentation.Modules = modules
Presentation.Helpers = helpers

if modules.Snapshots then
    return
end

modules.Snapshots = true

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
    local colonyId = ownerData and ownerData.colonyID or owner

    for _, definition in ipairs(Config.GetDefinitionList and Config.GetDefinitionList() or {}) do
        local instances = {}
        local currentCount = 0
        for _, instance in ipairs(ownerData.buildings or {}) do
            if tostring(instance.buildingType or "") == tostring(definition.buildingType) then
                currentCount = currentCount + 1
                instances[#instances + 1] = {
                    buildingID = instance.buildingID,
                    buildingType = instance.buildingType,
                    customName = instance.customName,
                    displayName = Buildings.RealBase and Buildings.RealBase.GetInstanceDisplayName and Buildings.RealBase.GetInstanceDisplayName(instance) or definition.displayName,
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
                        displayName = helpers.GetDisplayName(entry.fullType),
                        count = entry.count
                    }
                end
                levels[#levels + 1] = {
                    level = level,
                    enabled = levelDefinition.enabled == true,
                    workPoints = levelDefinition.workPoints,
                    recipe = recipe,
                    effects = helpers.ShallowCopy(levelDefinition.effects)
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
        local registry = helpers.GetRegistry()
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
        colonyId = colonyId,
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
