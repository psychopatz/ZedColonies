DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Validation = Internal.ProjectValidation or {}

Internal.ProjectValidation = Validation

function Buildings.ResolveProjectTarget(ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey)
    local owner = Validation.GetOwnerUsername(ownerUsername)
    local config = Validation.Config or Buildings.Config
    local normalizedBuildingType = tostring(buildingType or "")
    local normalizedMode = Validation.NormalizeMode(mode)
    local definition = config.GetDefinition(normalizedBuildingType)
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

        local installDefinition = config.GetInstallDefinition and config.GetInstallDefinition(normalizedBuildingType, installKey) or nil
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
        local maxInstallCount = config.GetInstallMaxCount and config.GetInstallMaxCount(normalizedBuildingType, installDefinition.installKey, currentLevel)
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
        local nextLevelDefinition = config.GetLevelDefinition(normalizedBuildingType, nextLevel)
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

    if normalizedBuildingType == "Barricade" then
        if normalizedMode ~= "build" then
            return nil, "Barricades cannot be upgraded or installed."
        end
        if not Buildings.OwnerHasHeadquarters(owner) then
            return nil, "Build Headquarters first."
        end

        local activeBarricades = Buildings.GetActiveBarricadeCount and Buildings.GetActiveBarricadeCount(owner) or 0
        local maxBarricades = Buildings.GetMaxActiveBarricades and Buildings.GetMaxActiveBarricades(owner) or 0
        local frontierRing = Buildings.GetActiveFrontierRing and Buildings.GetActiveFrontierRing(owner) or 0
        if frontierRing <= 0 and Buildings.GetNextFrontierRing then
            frontierRing = Buildings.GetNextFrontierRing(owner)
        end
        if maxBarricades <= 0 then
            return nil, "Upgrade Headquarters to level " .. tostring(frontierRing) .. " to unlock frontier ring " .. tostring(frontierRing) .. "."
        end
        if not Buildings.IsFrontierPlot or not Buildings.IsFrontierPlot(owner, x, y) then
            return nil, "Barricades can only be built on the active frontier perimeter."
        end
        if activeBarricades >= maxBarricades then
            return nil, "Frontier ring " .. tostring(frontierRing) .. " is at capacity."
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
        if definition.enabled ~= true then
            return nil, "That building is only a placeholder right now."
        end
        if definition.uniquePerColony == true then
            if Validation.FindCompletedBuildingByType(owner, normalizedBuildingType, nil) then
                return nil, tostring(definition.displayName or normalizedBuildingType) .. " is unique per colony."
            end
            if Validation.FindActiveBuildProjectByType(owner, normalizedBuildingType) then
                return nil, tostring(definition.displayName or normalizedBuildingType) .. " already has an active colony project."
            end
        end
        if normalizedBuildingType == "Warehouse" then
            local ring = Buildings.GetPlotRing(x, y)
            if Validation.FindWarehouseInRing(owner, ring, nil) then
                return nil, "That ring already has a Warehouse."
            end
            if Validation.FindWarehouseBuildProjectInRing(owner, ring) then
                return nil, "That ring already has a Warehouse project underway."
            end
        end
    end

    local levelDefinition = Validation.GetProjectDefinition(normalizedBuildingType, 1, "build", nil, x, y)
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

return Buildings