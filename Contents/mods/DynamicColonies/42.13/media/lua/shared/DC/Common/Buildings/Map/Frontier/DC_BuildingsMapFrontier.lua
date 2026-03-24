DC_Buildings = DC_Buildings or {}

local Buildings = DC_Buildings
local Config = Buildings.Config

local function getOwnerUsername(ownerUsername)
    local colonyConfig = DC_Colony and DC_Colony.Config or nil
    return colonyConfig and colonyConfig.GetOwnerUsername and colonyConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

local function sortPlotsByPosition(plots)
    table.sort(plots, function(a, b)
        if tonumber(a.y) == tonumber(b.y) then
            return tonumber(a.x) < tonumber(b.x)
        end
        return tonumber(a.y) < tonumber(b.y)
    end)
end

local function getCardinalDirections()
    local frontierConfig = Config and Config.Frontier or nil
    return frontierConfig and frontierConfig.CARDINAL_DIRECTIONS or {
        { x = -1, y = 0 },
        { x = 1, y = 0 },
        { x = 0, y = -1 },
        { x = 0, y = 1 }
    }
end

local function hasCompletedBarricadeAt(ownerUsername, plotX, plotY)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)
    local instance = Buildings.FindBuildingAtPlot and Buildings.FindBuildingAtPlot(ownerUsername, x, y) or nil
    return instance
        and tostring(instance.buildingType or "") == "Barricade"
        and math.floor(tonumber(instance.level) or 0) > 0
        or false
end

local function isRingSecured(ownerUsername, ring)
    local safeRing = math.max(1, math.floor(tonumber(ring) or 1))
    local ringCoords = Buildings.GetRingCoordinates and Buildings.GetRingCoordinates(safeRing) or {}
    for _, cell in ipairs(ringCoords) do
        if not hasCompletedBarricadeAt(ownerUsername, cell.x, cell.y) then
            return false
        end
    end
    return #ringCoords > 0
end

local function retireBarricadeBuildingsForRing(ownerUsername, ring)
    local safeOwner = getOwnerUsername(ownerUsername)
    local safeRing = math.max(1, math.floor(tonumber(ring) or 1))
    local buildings = Buildings.GetBuildingsForOwner(safeOwner) or {}
    local removed = 0

    for index = #buildings, 1, -1 do
        local instance = buildings[index]
        if tostring(instance and instance.buildingType or "") == "Barricade"
            and Buildings.GetPlotRing
            and Buildings.GetPlotRing(instance.plotX, instance.plotY) == safeRing
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            table.remove(buildings, index)
            removed = removed + 1
        end
    end

    return removed
end

local function computeLegacySecuredRing(ownerUsername)
    local safeOwner = getOwnerUsername(ownerUsername)
    local ring = 1
    local highestSecured = 0

    while isRingSecured(safeOwner, ring) do
        highestSecured = ring
        ring = ring + 1
    end

    return highestSecured
end

local function getSecuredPerimeterRing(ownerUsername)
    local safeOwner = getOwnerUsername(ownerUsername)
    local mapData = Buildings.GetMapDataForOwner and Buildings.GetMapDataForOwner(safeOwner) or nil
    local storedRing = mapData and mapData.securedRing

    if storedRing ~= nil then
        return math.max(0, math.floor(tonumber(storedRing) or 0))
    end

    local computedRing = computeLegacySecuredRing(safeOwner)
    if mapData then
        mapData.securedRing = computedRing
    end

    if computedRing > 0 then
        for ring = 1, computedRing do
            retireBarricadeBuildingsForRing(safeOwner, ring)
        end
        Buildings.Save()
    end

    return computedRing
end

local function hasUnlockedSupportingNeighbor(ownerUsername, plotX, plotY)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)

    for _, direction in ipairs(getCardinalDirections()) do
        local neighborX = x + direction.x
        local neighborY = y + direction.y
        local neighbor = Buildings.GetStoredPlotForOwner(ownerUsername, neighborX, neighborY)
        if neighbor and neighbor.unlocked == true then
            return true
        end
    end

    return false
end

local function getActiveFrontierRing(ownerUsername)
    return getSecuredPerimeterRing(ownerUsername) + 1
end

function Buildings.GetActiveFrontierRing(ownerUsername)
    return getActiveFrontierRing(ownerUsername)
end

function Buildings.GetSecuredPerimeterRing(ownerUsername)
    return getSecuredPerimeterRing(ownerUsername)
end

function Buildings.TryFinalizeBarricadeRing(ownerUsername, ring)
    local safeOwner = getOwnerUsername(ownerUsername)
    local safeRing = math.max(1, math.floor(tonumber(ring) or 1))
    local currentSecuredRing = getSecuredPerimeterRing(safeOwner)

    if safeRing ~= (currentSecuredRing + 1) then
        return false, 0
    end
    if not isRingSecured(safeOwner, safeRing) then
        return false, 0
    end

    local removed = retireBarricadeBuildingsForRing(safeOwner, safeRing)
    local mapData = Buildings.GetMapDataForOwner and Buildings.GetMapDataForOwner(safeOwner) or nil
    if mapData then
        mapData.securedRing = safeRing
    end
    Buildings.Save()
    return true, removed
end

function Buildings.GetUnlockedPlotEntries(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local mapData = Buildings.GetMapDataForOwner(owner)
    local plots = {}

    for _, plot in pairs(mapData and mapData.plots or {}) do
        if plot and plot.unlocked == true then
            plots[#plots + 1] = Buildings.BuildVirtualPlot(plot.x, plot.y, true, plot.kind)
        end
    end

    sortPlotsByPosition(plots)
    return plots
end

function Buildings.GetHeadquartersLevel(ownerUsername)
    local headquarters = Buildings.GetHeadquartersInstance and Buildings.GetHeadquartersInstance(ownerUsername) or nil
    return math.max(0, math.floor(tonumber(headquarters and headquarters.level) or 0))
end

function Buildings.GetMaxActiveBarricades(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local frontierConfig = Config and Config.Frontier or nil
    local currentRing = getActiveFrontierRing(owner)
    local ringCap = frontierConfig and frontierConfig.GetRingBarricadeCapacity and frontierConfig.GetRingBarricadeCapacity(currentRing) or 0
    return ringCap
end

function Buildings.GetActiveBarricadeCount(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local currentRing = getActiveFrontierRing(owner)
    local count = 0

    for _, instance in ipairs(Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Barricade"
            and Buildings.GetPlotRing
            and Buildings.GetPlotRing(instance.plotX, instance.plotY) == currentRing
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            count = count + 1
        end
    end

    for _, project in pairs(Buildings.GetProjectsForOwner(owner) or {}) do
        if tostring(project and project.status or "") == "Active"
            and Buildings.GetPlotRing
            and Buildings.GetPlotRing(project.plotX, project.plotY) == currentRing
            and tostring(project and project.buildingType or "") == "Barricade" then
            count = count + 1
        end
    end

    return count
end

function Buildings.IsFrontierPlot(ownerUsername, plotX, plotY)
    local owner = getOwnerUsername(ownerUsername)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)
    local targetRing = getActiveFrontierRing(owner)
    local plot, state, building, project = Buildings.GetPlotWithState(owner, x, y)

    if not plot or tostring(plot.kind or "") ~= tostring(Buildings.MapConstants.PlotKinds.Standard) then
        return false
    end
    if Buildings.GetPlotRing and Buildings.GetPlotRing(x, y) ~= targetRing then
        return false
    end
    if tostring(state or "") ~= tostring(Buildings.MapConstants.PlotStates.Locked)
        and tostring(state or "") ~= tostring(Buildings.MapConstants.PlotStates.Empty) then
        return false
    end
    if building or project then
        return false
    end

    return hasUnlockedSupportingNeighbor(owner, x, y)
end

function Buildings.GetFrontierCandidatePlots(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local targetRing = getActiveFrontierRing(owner)
    local candidates = {}
    local seen = {}

    for _, plot in ipairs(Buildings.GetUnlockedPlotEntries(owner)) do
        for _, direction in ipairs(getCardinalDirections()) do
            local nextX = math.floor(tonumber(plot.x) or 0) + direction.x
            local nextY = math.floor(tonumber(plot.y) or 0) + direction.y
            local key = Buildings.GetPlotKey(nextX, nextY)
            if not seen[key]
                and Buildings.GetPlotRing
                and Buildings.GetPlotRing(nextX, nextY) == targetRing
                and Buildings.IsFrontierPlot(owner, nextX, nextY) then
                seen[key] = true
                local candidate = Buildings.BuildVisiblePlot(owner, nextX, nextY)
                candidate.frontierCandidate = true
                candidates[#candidates + 1] = candidate
            end
        end
    end

    sortPlotsByPosition(candidates)
    return candidates
end

function Buildings.GetTerritorySummary(ownerUsername)
    local owner = getOwnerUsername(ownerUsername)
    local unlockedPlots = Buildings.GetUnlockedPlotEntries(owner)
    local headquartersLevel = Buildings.GetHeadquartersLevel(owner)
    local securedPerimeterRing = getSecuredPerimeterRing(owner)
    local currentFrontierRing = getActiveFrontierRing(owner)
    local activeBarricades = Buildings.GetActiveBarricadeCount(owner)
    local maxBarricades = Buildings.GetMaxActiveBarricades(owner)

    return {
        ownerUsername = owner,
        headquartersLevel = headquartersLevel,
        securedPerimeterRing = securedPerimeterRing,
        currentFrontierRing = currentFrontierRing,
        unlockedPlotCount = #unlockedPlots,
        activeBarricadeCount = activeBarricades,
        maxActiveBarricades = maxBarricades
    }
end

function Buildings.BuildVisibleBounds(plots)
    local bounds = {
        minX = 0,
        maxX = 0,
        minY = 0,
        maxY = 0
    }
    local seeded = false

    for _, plot in ipairs(plots or {}) do
        local x = math.floor(tonumber(plot and plot.x) or 0)
        local y = math.floor(tonumber(plot and plot.y) or 0)
        if not seeded then
            bounds.minX = x
            bounds.maxX = x
            bounds.minY = y
            bounds.maxY = y
            seeded = true
        else
            bounds.minX = math.min(bounds.minX, x)
            bounds.maxX = math.max(bounds.maxX, x)
            bounds.minY = math.min(bounds.minY, y)
            bounds.maxY = math.max(bounds.maxY, y)
        end
    end

    return bounds
end

return Buildings
