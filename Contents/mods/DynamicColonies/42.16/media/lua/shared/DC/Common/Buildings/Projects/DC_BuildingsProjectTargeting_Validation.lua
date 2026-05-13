DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Buildings.Internal

-- Shared deferred-access helpers

local function getColonyConfig()
    return DC_Colony and DC_Colony.Config or {}
end

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getSkills()
    return DC_Colony and DC_Colony.Skills or nil
end

local function getOwnerUsername(playerOrUsername)
    local labourConfig = getColonyConfig()
    return labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(playerOrUsername) or tostring(playerOrUsername or "local")
end

local function getWorkerConstructionLevel(worker)
    local skills = getSkills()
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, "Construction") or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

-- Mode / definition helpers

local function normalizeMode(mode)
    local normalized = tostring(mode or "build")
    if normalized == "upgrade" or normalized == "install" then
        return normalized
    end
    return "build"
end

local function getProjectDefinition(buildingType, targetLevel, mode, installKey, plotX, plotY)
    if normalizeMode(mode) == "install" then
        return Config.GetInstallDefinition and Config.GetInstallDefinition(buildingType, installKey) or nil
    end
    if tostring(buildingType or "") == "Barricade"
        and Config.Frontier
        and Config.Frontier.GetBarricadeLevelDefinition then
        return Config.Frontier.GetBarricadeLevelDefinition(targetLevel, plotX, plotY)
    end
    return Config.GetLevelDefinition(buildingType, targetLevel)
end

-- Plot / project query helpers

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

local function findCompletedBuildingByType(ownerUsername, buildingType, excludedBuildingID)
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if tostring(instance.buildingType or "") == tostring(buildingType or "")
            and math.floor(tonumber(instance.level) or 0) > 0
            and tostring(instance.buildingID or "") ~= tostring(excludedBuildingID or "") then
            return instance
        end
    end
    return nil
end

local function findActiveBuildProjectByType(ownerUsername, buildingType)
    for _, project in pairs(Buildings.GetProjectsForOwner(ownerUsername)) do
        if tostring(project.status or "") == "Active"
            and tostring(project.buildingType or "") == tostring(buildingType or "")
            and normalizeMode(project.mode) == "build" then
            return project
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

local function hasCompletedOuterBarricade(ownerUsername, plotX, plotY)
    local owner = getOwnerUsername(ownerUsername)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)
    local ring = Buildings.GetPlotRing and Buildings.GetPlotRing(x, y) or 0
    local nextRingCoords = Buildings.GetRingCoordinates and Buildings.GetRingCoordinates(ring + 1) or {}

    for _, cell in ipairs(nextRingCoords) do
        local dx = math.abs(math.floor(tonumber(cell.x) or 0) - x)
        local dy = math.abs(math.floor(tonumber(cell.y) or 0) - y)
        if dx <= 1 and dy <= 1 then
            local instance = Buildings.FindBuildingAtPlot and Buildings.FindBuildingAtPlot(owner, cell.x, cell.y) or nil
            if instance
                and tostring(instance.buildingType or "") == "Barricade"
                and math.floor(tonumber(instance.level) or 0) > 0 then
                return true
            end
        end
    end

    return false
end

-- Internal exports (used by Preview)

Internal.NormalizeMode = normalizeMode
Internal.GetProjectDefinition = getProjectDefinition

-- Public API

function Buildings.ResolveProjectTarget(ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey)
    local owner = getOwnerUsername(ownerUsername)
    local normalizedBuildingType = tostring(buildingType or "")
    local normalizedMode = normalizeMode(mode)
    local definition = Config.GetDefinition(normalizedBuildingType)
    if not definition then
        return nil, "Unknown building."
    end

    if normalizedBuildingType == "Headquarters" and normalizedMode == "upgrade" then
        return nil, "Headquarters upgrades are not available yet."
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
            if findCompletedBuildingByType(owner, normalizedBuildingType, nil) then
                return nil, tostring(definition.displayName or normalizedBuildingType) .. " is unique per colony."
            end
            if findActiveBuildProjectByType(owner, normalizedBuildingType) then
                return nil, tostring(definition.displayName or normalizedBuildingType) .. " already has an active colony project."
            end
        end
        if normalizedBuildingType == "Warehouse" then
            local ring = Buildings.GetPlotRing(x, y)
            if findWarehouseInRing(owner, ring, nil) then
                return nil, "That ring already has a Warehouse."
            end
            if findWarehouseBuildProjectInRing(owner, ring) then
                return nil, "That ring already has a Warehouse project underway."
            end
        end
    end

    local levelDefinition = getProjectDefinition(normalizedBuildingType, 1, "build", nil, x, y)
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

function Buildings.CanReleaseBuilderFromProject(worker, project, options)
    options = type(options) == "table" and options or {}
    if not worker or not project then
        return false
    end
    if tostring(project.status or "") ~= "Active" then
        return false
    end
    if tostring(project.assignedBuilderID or "") ~= tostring(worker.workerID or "") then
        return false
    end

    local allowedProjectID = tostring(options.allowedProjectID or "")
    if allowedProjectID ~= "" and tostring(project.projectID or "") == allowedProjectID then
        return true
    end

    return tostring(project.materialState or "") == "Stalled"
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

function Buildings.CanWorkerBuild(worker, options)
    options = type(options) == "table" and options or {}
    local allowedProjectID = tostring(options.allowedProjectID or "")
    local allowProjectRelease = options.allowProjectRelease == true
    local labourConfig = getColonyConfig()
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
    local currentProject = Buildings.GetWorkerProject(worker.ownerUsername, worker.workerID)
    if currentProject and tostring(currentProject.projectID or "") ~= allowedProjectID then
        if not (allowProjectRelease and Buildings.CanReleaseBuilderFromProject and Buildings.CanReleaseBuilderFromProject(worker, currentProject, options)) then
            return false, "That builder already has an active project."
        end
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
    if tostring(building.buildingType or "") == "Barricade" then
        if not hasCompletedOuterBarricade(owner, x, y) then
            return false, "This barricade stays locked until the next ring has a completed barricade enclosing it from outside.", nil
        end
    end
    return true, nil, building
end
