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

local function getWarehouse()
    return DT_Labour and DT_Labour.Warehouse or nil
end

local function getSkills()
    return DT_Labour and DT_Labour.Skills or nil
end

local function getWorkerConstructionLevel(worker)
    local skills = getSkills()
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, "Construction") or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

local function getDisplayName(fullType)
    local registry = getRegistry()
    local internal = registry and registry.Internal or nil
    return internal and internal.GetDisplayNameForFullType and internal.GetDisplayNameForFullType(fullType) or tostring(fullType or "Unknown")
end

local function getOwnerUsername(playerOrUsername)
    local labourConfig = getLabourConfig()
    return labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(playerOrUsername) or tostring(playerOrUsername or "local")
end

local function buildRecipeMap(recipe)
    local required = {}
    for _, entry in ipairs(recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local count = math.max(0, math.floor(tonumber(entry.count) or 0))
        if fullType ~= "" and count > 0 then
            required[fullType] = (required[fullType] or 0) + count
        end
    end
    return required
end

local function hasRecipeEntries(required)
    for _, _ in pairs(required or {}) do
        return true
    end
    return false
end

local function getWarehouseOutputCounts(ownerUsername)
    local warehouseApi = getWarehouse()
    local warehouse = warehouseApi and warehouseApi.GetOwnerWarehouse and warehouseApi.GetOwnerWarehouse(ownerUsername) or nil
    local counts = {}
    for _, entry in ipairs(warehouse and warehouse.ledgers and warehouse.ledgers.output or {}) do
        local fullType = tostring(entry.fullType or "")
        local qty = math.max(0, math.floor(tonumber(entry.qty) or 0))
        if fullType ~= "" and qty > 0 then
            counts[fullType] = (counts[fullType] or 0) + qty
        end
    end
    return counts
end

local function buildRecipeAvailability(ownerUsername, recipe)
    local availableCounts = getWarehouseOutputCounts(ownerUsername)
    local entries = {}
    local hasAll = true

    for _, entry in ipairs(recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local required = math.max(0, math.floor(tonumber(entry.count) or 0))
        local available = availableCounts[fullType] or 0
        local recipeEntry = {
            fullType = fullType,
            displayName = getDisplayName(fullType),
            count = required,
            available = available,
            satisfied = available >= required
        }
        if recipeEntry.satisfied ~= true then
            hasAll = false
        end
        entries[#entries + 1] = recipeEntry
    end

    return {
        hasAll = hasAll,
        entries = entries
    }
end

local function normalizeMaterialCountMap(value)
    local counts = type(value) == "table" and value or {}
    local normalized = {}
    for fullType, count in pairs(counts) do
        local key = tostring(fullType or "")
        if key ~= "" then
            normalized[key] = math.max(0, math.floor(tonumber(count) or 0))
        end
    end
    return normalized
end

local function countRecipeUnits(recipe)
    local total = 0
    for _, entry in ipairs(recipe or {}) do
        total = total + math.max(0, math.floor(tonumber(entry.count) or 0))
    end
    return total
end

local function countSuppliedRecipeUnits(recipe, suppliedCounts)
    local total = 0
    for _, entry in ipairs(recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local required = math.max(0, math.floor(tonumber(entry.count) or 0))
        total = total + math.min(required, math.max(0, tonumber(suppliedCounts and suppliedCounts[fullType]) or 0))
    end
    return total
end

local function ensureProjectMaterialTracking(project)
    if type(project) ~= "table" then
        return nil
    end

    project.materialTrackingVersion = math.max(0, math.floor(tonumber(project.materialTrackingVersion) or 0))
    project.materialCounts = normalizeMaterialCountMap(project.materialCounts)

    if project.materialTrackingVersion <= 0 then
        project.materialTrackingVersion = 1
        project.materialCounts = buildRecipeMap(project.recipe)
        project.materialState = "Ready"
    end

    return project
end

local function pullProjectMaterialsFromWarehouse(project)
    local warehouseApi = getWarehouse()
    local owner = project and getOwnerUsername(project.ownerUsername) or nil
    local warehouse = owner and warehouseApi and warehouseApi.GetOwnerWarehouse and warehouseApi.GetOwnerWarehouse(owner) or nil
    if not project or not warehouse then
        return 0
    end

    ensureProjectMaterialTracking(project)

    local required = buildRecipeMap(project.recipe)
    if not hasRecipeEntries(required) then
        return 0
    end

    local moved = 0
    local outputLedger = warehouse.ledgers and warehouse.ledgers.output or {}
    for index = #outputLedger, 1, -1 do
        local entry = outputLedger[index]
        local fullType = tostring(entry and entry.fullType or "")
        local needed = math.max(0, (required[fullType] or 0) - (project.materialCounts[fullType] or 0))
        if fullType ~= "" and needed > 0 and entry then
            local qty = math.max(0, math.floor(tonumber(entry.qty) or 0))
            local toTake = math.min(qty, needed)
            if toTake > 0 then
                project.materialCounts[fullType] = math.max(0, tonumber(project.materialCounts[fullType]) or 0) + toTake
                qty = qty - toTake
                moved = moved + toTake
                if qty <= 0 then
                    table.remove(outputLedger, index)
                else
                    entry.qty = qty
                end
            end
        end
    end

    if moved > 0 and warehouseApi and warehouseApi.Recalculate then
        warehouseApi.Recalculate(warehouse)
    end

    return moved
end

local function buildProjectMaterialStatus(project)
    ensureProjectMaterialTracking(project)

    local owner = project and getOwnerUsername(project.ownerUsername) or nil
    local warehouseCounts = owner and getWarehouseOutputCounts(owner) or {}
    local entries = {}
    local hasAll = true
    local totalRequired = countRecipeUnits(project and project.recipe or {})
    local totalSupplied = countSuppliedRecipeUnits(project and project.recipe or {}, project and project.materialCounts or nil)

    for _, entry in ipairs(project and project.recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local required = math.max(0, math.floor(tonumber(entry.count) or 0))
        local supplied = math.min(required, math.max(0, tonumber(project and project.materialCounts and project.materialCounts[fullType]) or 0))
        local warehouseAvailable = math.max(0, warehouseCounts[fullType] or 0)
        local remaining = math.max(0, required - supplied)
        local recipeEntry = {
            fullType = fullType,
            displayName = getDisplayName(fullType),
            count = required,
            available = warehouseAvailable,
            supplied = supplied,
            remaining = remaining,
            satisfied = remaining <= 0
        }
        if recipeEntry.satisfied ~= true then
            hasAll = false
        end
        entries[#entries + 1] = recipeEntry
    end

    return {
        hasAll = hasAll,
        entries = entries,
        totalRequired = totalRequired,
        totalSupplied = totalSupplied,
        progressRatio = totalRequired > 0 and math.max(0, math.min(1, totalSupplied / totalRequired)) or 1
    }
end

local function consumeRecipe(ownerUsername, recipe)
    local warehouseApi = getWarehouse()
    local warehouse = warehouseApi and warehouseApi.GetOwnerWarehouse and warehouseApi.GetOwnerWarehouse(ownerUsername) or nil
    if not warehouse then
        return false
    end

    local required = buildRecipeMap(recipe)
    if not hasRecipeEntries(required) then
        return true
    end

    local outputLedger = warehouse.ledgers and warehouse.ledgers.output or {}

    for fullType, needed in pairs(required) do
        local available = 0
        for _, entry in ipairs(outputLedger) do
            if entry.fullType == fullType then
                available = available + math.max(0, math.floor(tonumber(entry.qty) or 0))
            end
        end
        if available < needed then
            return false
        end
    end

    for index = #outputLedger, 1, -1 do
        local entry = outputLedger[index]
        local fullType = tostring(entry and entry.fullType or "")
        local needed = required[fullType]
        if needed and needed > 0 and entry then
            local qty = math.max(0, math.floor(tonumber(entry.qty) or 0))
            local toTake = math.min(qty, needed)
            qty = qty - toTake
            required[fullType] = needed - toTake
            if qty <= 0 then
                table.remove(outputLedger, index)
            else
                entry.qty = qty
            end
        end
    end

    if warehouseApi and warehouseApi.Recalculate then
        warehouseApi.Recalculate(warehouse)
    end
    return true
end

local function normalizeMode(mode)
    local normalized = tostring(mode or "build")
    if normalized == "upgrade" or normalized == "install" then
        return normalized
    end
    return "build"
end

local function getProjectDefinition(buildingType, targetLevel, mode, installKey)
    if normalizeMode(mode) == "install" then
        return Config.GetInstallDefinition and Config.GetInstallDefinition(buildingType, installKey) or nil
    end
    return Config.GetLevelDefinition(buildingType, targetLevel)
end

local function getProjectDisplayName(buildingType, mode, installKey)
    if normalizeMode(mode) == "install" then
        local installDefinition = Config.GetInstallDefinition and Config.GetInstallDefinition(buildingType, installKey) or nil
        return tostring(installDefinition and installDefinition.displayName or installKey or "Install")
    end

    local definition = Config.GetDefinition(buildingType)
    return tostring(definition and definition.displayName or buildingType or "Building")
end

local function getProjectIconPath(buildingType, mode, installKey)
    if normalizeMode(mode) == "install" then
        local installDefinition = Config.GetInstallDefinition and Config.GetInstallDefinition(buildingType, installKey) or nil
        if installDefinition and installDefinition.iconPath then
            return installDefinition.iconPath
        end
    end

    local definition = Config.GetDefinition(buildingType)
    return definition and definition.iconPath or nil
end

local function getInstallCapacityGain(buildingType, definition)
    local effects = definition and definition.effects or {}
    if tostring(buildingType or "") == "Infirmary" then
        return math.max(0, math.floor(tonumber(effects.infirmaryCapacityBonus) or 0))
    end
    return math.max(0, math.floor(tonumber(effects.warehouseCapacityBonus) or 0))
end

local function findWarehouseInRing(ownerUsername, ring, excludedBuildingID)
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if tostring(instance.buildingType or "") == "Warehouse"
            and math.floor(tonumber(instance.level) or 0) > 0
            and Buildings.GetPlotRing(instance.plotX, instance.plotY) == ring
            and tostring(instance.buildingID or "") ~= tostring(excludedBuildingID or "") then
            return instance
        end
    end
    return nil
end

local function findWarehouseBuildProjectInRing(ownerUsername, ring)
    for _, project in pairs(Buildings.GetProjectsForOwner(ownerUsername)) do
        if tostring(project.status or "") == "Active"
            and tostring(project.buildingType or "") == "Warehouse"
            and normalizeMode(project.mode) == "build"
            and Buildings.GetPlotRing(project.plotX, project.plotY) == ring then
            return project
        end
    end
    return nil
end

local function buildBasePreview(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    local definition = Config.GetDefinition(buildingType)
    return {
        ownerUsername = owner,
        buildingType = tostring(buildingType or ""),
        displayName = getProjectDisplayName(buildingType, mode, installKey),
        iconPath = getProjectIconPath(buildingType, mode, installKey),
        mode = normalizeMode(mode),
        plotX = math.floor(tonumber(plotX) or 0),
        plotY = math.floor(tonumber(plotY) or 0),
        buildingID = buildingID,
        installKey = tostring(installKey or ""),
        installDisplayName = nil,
        available = false,
        canStart = false,
        reason = "Unavailable.",
        currentLevel = 0,
        targetLevel = 0,
        workPoints = 0,
        recipeAvailability = {
            hasAll = false,
            entries = {}
        },
        effects = {},
        currentInstallCount = 0,
        maxInstallCount = 0,
        capacityPerInstall = 0
    }
end

function Buildings.ResolveProjectTarget(ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey)
    local owner = getOwnerUsername(ownerUsername)
    local normalizedBuildingType = tostring(buildingType or "")
    local normalizedMode = normalizeMode(mode)
    local definition = Config.GetDefinition(normalizedBuildingType)
    if not definition then
        return nil, "Unknown building."
    end

    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)
    local plot, state, instance, activeProject = Buildings.GetPlotWithState(owner, x, y)

    if normalizedMode == "install" then
        if not instance or math.floor(tonumber(instance.level) or 0) <= 0 then
            return nil, "There is no completed building to install on for that plot."
        end
        if tostring(instance.buildingType or "") ~= normalizedBuildingType then
            return nil, "That plot contains a different building."
        end
        if buildingID and tostring(instance.buildingID or "") ~= tostring(buildingID) then
            return nil, "That building no longer matches the selected plot."
        end
        if activeProject then
            return nil, "That plot already has an active project."
        end

        local installDefinition = Config.GetInstallDefinition and Config.GetInstallDefinition(normalizedBuildingType, installKey) or nil
        if not installDefinition then
            return nil, "Unknown installation."
        end

        local currentLevel = math.max(0, math.floor(tonumber(instance.level) or 0))
        local requiredLevel = math.max(1, math.floor(tonumber(installDefinition.requiredLevel) or 1))
        if currentLevel < requiredLevel then
            return nil, tostring(installDefinition.displayName or "This installation")
                .. " requires "
                .. tostring(definition.displayName or normalizedBuildingType or "this building")
                .. " level "
                .. tostring(requiredLevel)
                .. "."
        end

        local currentInstallCount = Buildings.GetBuildingInstallCount(instance, installDefinition.installKey)
        local maxInstallCount = Config.GetInstallMaxCount and Config.GetInstallMaxCount(normalizedBuildingType, installDefinition.installKey, currentLevel)
            or math.max(0, math.floor(tonumber(installDefinition.maxCount) or 0))
        if maxInstallCount > 0 and currentInstallCount >= maxInstallCount then
            return nil, tostring(installDefinition.displayName or "This installation")
                .. " is already maxed for this "
                .. string.lower(tostring(definition.displayName or normalizedBuildingType or "building"))
                .. "."
        end

        return {
            ownerUsername = owner,
            instance = instance,
            plot = plot,
            currentLevel = currentLevel,
            targetLevel = currentLevel,
            mode = "install",
            plotX = x,
            plotY = y,
            installKey = tostring(installDefinition.installKey or installKey or ""),
            currentInstallCount = currentInstallCount,
            maxInstallCount = maxInstallCount
        }, nil
    elseif normalizedMode == "upgrade" then
        if not instance then
            return nil, "There is no building to upgrade on that plot."
        end
        if tostring(instance.buildingType or "") ~= normalizedBuildingType then
            return nil, "That plot contains a different building."
        end
        if buildingID and tostring(instance.buildingID or "") ~= tostring(buildingID) then
            return nil, "That building no longer matches the selected plot."
        end
        if activeProject then
            return nil, "That plot already has an active project."
        end

        local nextLevel = math.max(1, math.floor(tonumber(instance.level) or 0) + 1)
        local nextLevelDefinition = Config.GetLevelDefinition(normalizedBuildingType, nextLevel)
        if not nextLevelDefinition or nextLevelDefinition.enabled ~= true then
            return nil, "That building cannot be upgraded further."
        end

        return {
            ownerUsername = owner,
            instance = instance,
            plot = plot,
            currentLevel = math.max(0, math.floor(tonumber(instance.level) or 0)),
            targetLevel = nextLevel,
            mode = "upgrade",
            plotX = x,
            plotY = y
        }, nil
    end

    if activeProject then
        return nil, "That plot already has an active project."
    end
    if state ~= Buildings.MapConstants.PlotStates.Empty then
        return nil, "That plot is not empty."
    end
    if plot.unlocked ~= true then
        return nil, "That plot is locked."
    end

    if normalizedBuildingType == "Headquarters" then
        if plot.kind ~= Buildings.MapConstants.PlotKinds.HQOnly or x ~= 0 or y ~= 0 then
            return nil, "Headquarters can only be built on the center plot."
        end
        if Buildings.OwnerHasHeadquarters(owner) then
            return nil, "Headquarters is already built."
        end
    else
        if plot.kind ~= Buildings.MapConstants.PlotKinds.Standard then
            return nil, "Only Headquarters can be built on this plot."
        end
        if normalizedBuildingType == "Warehouse" then
            local ring = Buildings.GetPlotRing(x, y)
            if findWarehouseInRing(owner, ring, nil) then
                return nil, "That ring already has a Warehouse."
            end
            if findWarehouseBuildProjectInRing(owner, ring) then
                return nil, "That ring already has a Warehouse project underway."
            end
        elseif normalizedBuildingType ~= "Barracks" and normalizedBuildingType ~= "Infirmary" then
            return nil, "That building is only a placeholder right now."
        end
    end

    local levelDefinition = Config.GetLevelDefinition(normalizedBuildingType, 1)
    if not levelDefinition or levelDefinition.enabled ~= true then
        return nil, "That building is not available yet."
    end

    return {
        ownerUsername = owner,
        instance = nil,
        plot = plot,
        currentLevel = 0,
        targetLevel = 1,
        mode = "build",
        plotX = x,
        plotY = y
    }, nil
end

function Buildings.GetWorkerProject(ownerUsername, workerID)
    for _, project in pairs(Buildings.GetProjectsForOwner(ownerUsername)) do
        if project.status == "Active" and tostring(project.assignedBuilderID or "") == tostring(workerID or "") then
            return project
        end
    end
    return nil
end

function Buildings.GetProjectForWorker(worker)
    if not worker or not worker.workerID then
        return nil
    end
    return Buildings.GetWorkerProject(worker.ownerUsername, worker.workerID)
end

function Buildings.GetProjectByID(ownerUsername, projectID)
    local owner = getOwnerUsername(ownerUsername)
    local wanted = tostring(projectID or "")
    if wanted == "" then
        return nil
    end

    for _, project in pairs(Buildings.GetProjectsForOwner(owner)) do
        if tostring(project and project.projectID or "") == wanted then
            return project
        end
    end

    return nil
end

function Buildings.GetProjectMaterialStatus(project)
    return buildProjectMaterialStatus(project)
end

function Buildings.RefreshProjectMaterialState(project)
    if not project or tostring(project.status or "") ~= "Active" then
        return buildProjectMaterialStatus(project)
    end

    ensureProjectMaterialTracking(project)
    pullProjectMaterialsFromWarehouse(project)

    local materialStatus = buildProjectMaterialStatus(project)
    project.materialState = materialStatus.hasAll and "Ready" or "Stalled"
    project.materialProgressRatio = materialStatus.progressRatio
    return materialStatus
end

function Buildings.RefreshOwnerProjectMaterials(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local changed = false

    for _, project in pairs(Buildings.GetProjectsForOwner(owner)) do
        if tostring(project.status or "") == "Active" then
            local beforeState = tostring(project.materialState or "")
            local beforeRatio = tonumber(project.materialProgressRatio) or -1
            local beforeCounts = normalizeMaterialCountMap(project.materialCounts)
            local beforeTotal = 0
            for _, count in pairs(beforeCounts) do
                beforeTotal = beforeTotal + count
            end

            local materialStatus = Buildings.RefreshProjectMaterialState(project)
            local afterTotal = 0
            for _, count in pairs(project.materialCounts or {}) do
                afterTotal = afterTotal + (tonumber(count) or 0)
            end

            if beforeState ~= tostring(project.materialState or "")
                or math.abs(beforeRatio - (tonumber(project.materialProgressRatio) or 0)) > 0.0001
                or beforeTotal ~= afterTotal
                or (materialStatus and materialStatus.hasAll and beforeState ~= "Ready") then
                changed = true
            end
        end
    end

    if changed then
        Buildings.Save()
    end

    return changed
end

function Buildings.GetProjectDisplayState(ownerUsername, workerID)
    local project = Buildings.GetWorkerProject(ownerUsername, workerID)
    if not project then
        return {
            hasProject = false,
            label = "No Project"
        }
    end

    return {
        hasProject = true,
        label = normalizeMode(project.mode) == "install"
            and getProjectDisplayName(project.buildingType, project.mode, project.installKey)
            or tostring(project.buildingType or "Project") .. " L" .. tostring(project.targetLevel or 1),
        materialState = tostring(project.materialState or ""),
        project = project
    }
end

function Buildings.GetRecipeAvailability(ownerUsername, buildingType, targetLevel, mode, installKey)
    local projectDefinition = getProjectDefinition(buildingType, targetLevel, mode, installKey)
    return buildRecipeAvailability(ownerUsername, projectDefinition and projectDefinition.recipe or {})
end

function Buildings.BuildProjectPreview(ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey)
    local owner = getOwnerUsername(ownerUsername)
    local preview = buildBasePreview(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    local target, targetReason = Buildings.ResolveProjectTarget(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    if not target then
        preview.reason = targetReason or preview.reason
        return preview
    end

    local projectDefinition = getProjectDefinition(buildingType, target.targetLevel, target.mode, target.installKey)
    if not projectDefinition or projectDefinition.enabled == false then
        preview.reason = "That level is not available yet."
        return preview
    end

    preview.available = true
    preview.currentLevel = math.max(0, math.floor(tonumber(target.currentLevel) or 0))
    preview.targetLevel = math.max(1, math.floor(tonumber(target.targetLevel) or 1))
    preview.buildingID = target.instance and target.instance.buildingID or preview.buildingID
    preview.installKey = tostring(target.installKey or preview.installKey or "")
    preview.installDisplayName = normalizeMode(target.mode) == "install" and getProjectDisplayName(buildingType, target.mode, target.installKey) or nil
    preview.workPoints = math.max(1, math.floor(tonumber(projectDefinition.workPoints) or 1))
    preview.recipeAvailability = buildRecipeAvailability(owner, projectDefinition.recipe)
    preview.effects = Internal.CopyDeep(projectDefinition.effects or {})
    preview.currentInstallCount = math.max(0, math.floor(tonumber(target.currentInstallCount) or 0))
    preview.maxInstallCount = math.max(0, math.floor(tonumber(target.maxInstallCount) or 0))
    preview.capacityPerInstall = getInstallCapacityGain(buildingType, projectDefinition)
    preview.canStart = preview.recipeAvailability.hasAll == true
    preview.reason = preview.canStart and nil or "Missing materials. The project can still be queued and will stall until supplied."
    return preview
end

function Buildings.BuildPlotBuildOptions(ownerUsername, plotX, plotY)
    local options = {}
    for _, definition in ipairs(Config.GetDefinitionList and Config.GetDefinitionList() or {}) do
        local preview = Buildings.BuildProjectPreview(ownerUsername, definition.buildingType, "build", plotX, plotY, nil)
        local description = "Placeholder building."
        local effectLines = {}

        if definition.buildingType == "Headquarters" then
            description = "Establishes the settlement core. Upgrading Headquarters unlocks new outer plots around your base."
            if preview.targetLevel and preview.targetLevel > 1 then
                effectLines[#effectLines + 1] = "Unlocks the next Headquarters border expansion."
            else
                effectLines[#effectLines + 1] = "Required to begin settlement expansion."
            end
        elseif definition.buildingType == "Barracks" then
            description = "Provides housing for your workers and improves recovery for the occupants living inside."
            if preview.effects and preview.effects.housingSlots then
                effectLines[#effectLines + 1] = "Housing Slots: " .. tostring(preview.effects.housingSlots)
            end
            if preview.effects and preview.effects.recoveryMultiplier then
                effectLines[#effectLines + 1] = "Recovery Multiplier: x" .. tostring(preview.effects.recoveryMultiplier)
            end
        elseif definition.buildingType == "Warehouse" then
            description = "Expands total warehouse storage for your settlement. Higher levels unlock extra storage installations."
            if preview.effects and preview.effects.warehouseBaseBonus then
                effectLines[#effectLines + 1] = "Base Capacity Bonus: +" .. tostring(preview.effects.warehouseBaseBonus)
            end
            effectLines[#effectLines + 1] = "Only one Warehouse can exist in each ring band."
        elseif definition.buildingType == "Infirmary" then
            description = "Treats injured workers while they sleep. Beds expand capacity, and Doctors can use medical provisions to speed recovery."
            if preview.effects and preview.effects.infirmaryBaseCapacity then
                effectLines[#effectLines + 1] = "Base Medical Slots: +" .. tostring(preview.effects.infirmaryBaseCapacity)
            end
            if preview.effects and preview.effects.infirmaryCapacityCap then
                effectLines[#effectLines + 1] = "Medical Slot Cap: " .. tostring(preview.effects.infirmaryCapacityCap)
            end
        else
            description = "Planned for a future update. This building is shown as a placeholder for expansion."
            effectLines[#effectLines + 1] = "Currently unavailable in this build."
        end

        options[#options + 1] = {
            buildingType = definition.buildingType,
            displayName = definition.displayName,
            iconPath = definition.iconPath,
            enabled = preview.available == true,
            disabledReason = preview.available == true and nil or preview.reason,
            preview = preview,
            description = description,
            effectLines = effectLines
        }
    end
    return options
end

function Buildings.BuildBuildingInstallOptions(ownerUsername, plotX, plotY, buildingID)
    local owner = getOwnerUsername(ownerUsername)
    local instance = Buildings.FindBuildingAtPlot(owner, plotX, plotY)
    local options = {}
    if not instance or tostring(instance.buildingType or "") == "" then
        return options
    end

    for _, definition in ipairs(Config.GetInstallDefinitionList and Config.GetInstallDefinitionList(instance.buildingType) or {}) do
        local preview = Buildings.BuildProjectPreview(owner, instance.buildingType, "install", plotX, plotY, buildingID, definition.installKey)
        local currentCount = Buildings.GetBuildingInstallCount(instance, definition.installKey)
        local maxCount = Config.GetInstallMaxCount and Config.GetInstallMaxCount(instance.buildingType, definition.installKey, instance.level)
            or math.max(0, math.floor(tonumber(definition.maxCount) or 0))
        local capacityGain = getInstallCapacityGain(instance.buildingType, definition)
        local effectLabel = tostring(instance.buildingType or "") == "Infirmary" and "Medical Slots Per Install" or "Capacity Per Install"
        local effectLines = {
            effectLabel .. ": +" .. tostring(capacityGain),
            "Installed: " .. tostring(currentCount) .. " / " .. tostring(maxCount)
        }

        options[#options + 1] = {
            installKey = definition.installKey,
            buildingType = instance.buildingType,
            displayName = tostring(definition.displayName or definition.installKey or "Install"),
            iconPath = definition.iconPath or getProjectIconPath(instance.buildingType, "install", definition.installKey),
            enabled = preview.available == true,
            disabledReason = preview.available == true and nil or preview.reason,
            preview = preview,
            description = tostring(definition.description or "Installation option."),
            effectLines = effectLines,
            currentCount = currentCount,
            maxCount = maxCount,
            capacityGain = capacityGain
        }
    end

    return options
end

function Buildings.CanWorkerBuild(worker)
    local labourConfig = getLabourConfig()
    if not worker or not worker.workerID then
        return false, "Builder not found."
    end
    if tostring(worker.state or "") == tostring(labourConfig.States and labourConfig.States.Dead or "Dead") then
        return false, "That worker is dead."
    end
    if labourConfig.NormalizeJobType and labourConfig.NormalizeJobType(worker.jobType) ~= tostring(labourConfig.JobTypes and labourConfig.JobTypes.Builder or "Builder") then
        return false, "That worker is not assigned to Builder."
    end
    if getWorkerConstructionLevel(worker) <= 0 then
        return false, "That worker has no Construction skill."
    end
    if Buildings.GetWorkerProject(worker.ownerUsername, worker.workerID) then
        return false, "That builder already has an active project."
    end
    local registry = getRegistry()
    if registry and registry.WorkerHasRequiredTools and not registry.WorkerHasRequiredTools(worker) then
        return false, "That builder is missing required tools."
    end
    return true, nil
end

function Buildings.CanDestroyBuilding(ownerUsername, plotX, plotY, buildingID)
    local owner = getOwnerUsername(ownerUsername)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)
    local building = Buildings.FindBuildingAtPlot(owner, x, y)
    if not building or math.floor(tonumber(building.level) or 0) <= 0 then
        return false, "There is no completed building on that plot.", nil
    end
    if buildingID and tostring(building.buildingID or "") ~= tostring(buildingID) then
        return false, "That building no longer matches the selected plot.", nil
    end
    if tostring(building.buildingType or "") == "Headquarters" then
        return false, "Headquarters cannot be destroyed.", nil
    end
    if Buildings.GetActiveProjectAtPlot(owner, x, y) then
        return false, "You cannot destroy a building while a project is active on that plot.", nil
    end
    return true, nil, building
end

Internal.BuildingsConsumeRecipe = consumeRecipe

return Buildings
