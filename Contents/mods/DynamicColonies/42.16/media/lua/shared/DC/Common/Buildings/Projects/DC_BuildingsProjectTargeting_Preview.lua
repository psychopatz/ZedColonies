DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Buildings.Internal

-- Shared deferred-access helpers

local function getColonyConfig()
    return DC_Colony and DC_Colony.Config or {}
end

local function getOwnerUsername(playerOrUsername)
    local labourConfig = getColonyConfig()
    return labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(playerOrUsername) or tostring(playerOrUsername or "local")
end

-- Display helpers

local function getProjectDisplayName(buildingType, mode, installKey)
    if Internal.NormalizeMode(mode) == "install" then
        local installDefinition = Config.GetInstallDefinition and Config.GetInstallDefinition(buildingType, installKey) or nil
        return tostring(installDefinition and installDefinition.displayName or installKey or "Install")
    end

    local definition = Config.GetDefinition(buildingType)
    return tostring(definition and definition.displayName or buildingType or "Building")
end

local function getProjectIconPath(buildingType, mode, installKey)
    if Internal.NormalizeMode(mode) == "install" then
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
    if tostring(buildingType or "") == "WaterCollector" then
        return math.max(0, tonumber(effects.waterCollectionRateBonus) or 0)
    end
    return math.max(0, math.floor(tonumber(effects.warehouseCapacityBonus or effects.waterStorageBonus) or 0))
end

local function getInstallEffectLabel(buildingType)
    if tostring(buildingType or "") == "Infirmary" then
        return "Medical Slots Per Install"
    end
    if tostring(buildingType or "") == "WaterCollector" then
        return "Collection Rate Per Install"
    end
    return "Capacity Per Install"
end

local function buildBasePreview(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    local definition = Config.GetDefinition(buildingType)
    return {
        ownerUsername = owner,
        buildingType = tostring(buildingType or ""),
        displayName = getProjectDisplayName(buildingType, mode, installKey),
        iconPath = getProjectIconPath(buildingType, mode, installKey),
        mode = Internal.NormalizeMode(mode),
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

-- Public API

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
        label = Internal.NormalizeMode(project.mode) == "install"
            and getProjectDisplayName(project.buildingType, project.mode, project.installKey)
            or tostring(project.buildingType or "Project") .. " L" .. tostring(project.targetLevel or 1),
        materialState = tostring(project.materialState or ""),
        project = project
    }
end

function Buildings.GetRecipeAvailability(ownerUsername, buildingType, targetLevel, mode, installKey, sourcePlayer, availableCounts)
    local projectDefinition = Internal.GetProjectDefinition(buildingType, targetLevel, mode, installKey)
    return Internal.BuildRecipeAvailability(ownerUsername, projectDefinition and projectDefinition.recipe or {}, sourcePlayer, availableCounts)
end

function Buildings.BuildProjectPreview(ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey, sourcePlayer, availableCounts)
    local owner = getOwnerUsername(ownerUsername)
    local preview = buildBasePreview(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    local target, targetReason = Buildings.ResolveProjectTarget(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    if not target then
        preview.reason = targetReason or preview.reason
        return preview
    end

    local projectDefinition = Internal.GetProjectDefinition(
        buildingType,
        target.targetLevel,
        target.mode,
        target.installKey,
        target.plotX,
        target.plotY
    )
    if not projectDefinition or projectDefinition.enabled == false then
        preview.reason = "That level is not available yet."
        return preview
    end

    preview.available = true
    preview.currentLevel = math.max(0, math.floor(tonumber(target.currentLevel) or 0))
    preview.targetLevel = math.max(1, math.floor(tonumber(target.targetLevel) or 1))
    preview.buildingID = target.instance and target.instance.buildingID or preview.buildingID
    preview.installKey = tostring(target.installKey or preview.installKey or "")
    preview.installDisplayName = Internal.NormalizeMode(target.mode) == "install" and getProjectDisplayName(buildingType, target.mode, target.installKey) or nil
    preview.workPoints = math.max(1, math.floor(tonumber(projectDefinition.workPoints) or 1))
    preview.recipeAvailability = Internal.BuildRecipeAvailability(owner, projectDefinition.recipe, sourcePlayer, availableCounts)
    preview.effects = Internal.CopyDeep(projectDefinition.effects or {})
    preview.currentInstallCount = math.max(0, math.floor(tonumber(target.currentInstallCount) or 0))
    preview.maxInstallCount = math.max(0, math.floor(tonumber(target.maxInstallCount) or 0))
    preview.capacityPerInstall = getInstallCapacityGain(buildingType, projectDefinition)
    preview.canStart = preview.recipeAvailability.hasAll == true
    preview.reason = preview.canStart and nil or "Missing materials. The project can still be queued and will stall until supplied."
    return preview
end

function Buildings.BuildPlotBuildOptions(ownerUsername, plotX, plotY, sourcePlayer, availableCounts)
    local owner = getOwnerUsername(ownerUsername)
    local plot, state = Buildings.GetPlotWithState(owner, plotX, plotY)
    local options = {}

    if Buildings.IsFrontierPlot and Buildings.IsFrontierPlot(owner, plotX, plotY) then
        local definition = Config.GetDefinition and Config.GetDefinition("Barricade") or nil
        local preview = Buildings.BuildProjectPreview(owner, "Barricade", "build", plotX, plotY, nil, nil, sourcePlayer, availableCounts)
        local effectLines = {
            "Secures this active perimeter tile and uses 1 slot on the current frontier ring.",
            "Complete every barricade slot on the current ring to convert that wall line into safe colony tiles and reveal the next ring."
        }
        if preview.effects and preview.effects.ringDistance then
            effectLines[#effectLines + 1] = "Ring Distance: " .. tostring(preview.effects.ringDistance)
        end
        if preview.effects and preview.effects.barricadeHP then
            effectLines[#effectLines + 1] = "HP Placeholder: " .. tostring(preview.effects.barricadeHP)
        end

        options[#options + 1] = {
            buildingType = "Barricade",
            displayName = definition and definition.displayName or "Barricade",
            iconPath = definition and definition.iconPath or nil,
            enabled = preview.available == true,
            disabledReason = preview.available == true and nil or preview.reason,
            preview = preview,
            description = "Secures one slot on the active perimeter ring. Once the whole ring is finished, those barricade slots convert into safe buildable colony tiles.",
            effectLines = effectLines
        }

        return options
    end

    if tostring(state or "") ~= tostring(Buildings.MapConstants.PlotStates.Empty) or plot.unlocked ~= true then
        return options
    end

    for _, definition in ipairs(Config.GetDefinitionList and Config.GetDefinitionList() or {}) do
        if tostring(definition and definition.buildingType or "") ~= "Barricade" then
            local preview = Buildings.BuildProjectPreview(ownerUsername, definition.buildingType, "build", plotX, plotY, nil, nil, sourcePlayer, availableCounts)
            local descInfo = Internal.GetBuildOptionText(definition.buildingType, preview.effects)
            local description = descInfo.description
            local effectLines = descInfo.effectLines

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
    end
    return options
end

function Buildings.BuildBuildingInstallOptions(ownerUsername, plotX, plotY, buildingID, sourcePlayer, availableCounts)
    local owner = getOwnerUsername(ownerUsername)
    local instance = Buildings.FindBuildingAtPlot(owner, plotX, plotY)
    local options = {}
    if not instance or tostring(instance.buildingType or "") == "" then
        return options
    end

    for _, definition in ipairs(Config.GetInstallDefinitionList and Config.GetInstallDefinitionList(instance.buildingType) or {}) do
        local preview = Buildings.BuildProjectPreview(owner, instance.buildingType, "install", plotX, plotY, buildingID, definition.installKey, sourcePlayer, availableCounts)
        local currentCount = Buildings.GetBuildingInstallCount(instance, definition.installKey)
        local maxCount = Config.GetInstallMaxCount and Config.GetInstallMaxCount(instance.buildingType, definition.installKey, instance.level)
            or math.max(0, math.floor(tonumber(definition.maxCount) or 0))
        local capacityGain = getInstallCapacityGain(instance.buildingType, definition)
        local effectLabel = getInstallEffectLabel(instance.buildingType)
        local effectLines = {
            effectLabel .. ": +" .. tostring(capacityGain) .. (tostring(instance.buildingType or "") == "WaterCollector" and " / hour" or ""),
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
