DC_Buildings = DC_Buildings or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal or {}
local Constants = Buildings.MapConstants
local CARDINAL_DIRECTIONS = {
    { x = -1, y = 0 },
    { x = 1, y = 0 },
    { x = 0, y = -1 },
    { x = 0, y = 1 }
}

local function isCardinalSeed(ring, x, y)
    local safeRing = math.max(1, math.floor(tonumber(ring) or 1))
    local plotX = math.floor(tonumber(x) or 0)
    local plotY = math.floor(tonumber(y) or 0)
    return (math.abs(plotX) == safeRing and plotY == 0)
        or (math.abs(plotY) == safeRing and plotX == 0)
end

local function getOwnerDataForFrontier(ownerUsername)
    if Internal.GetOwnerDataIfNormalizing then
        local ownerData = Internal.GetOwnerDataIfNormalizing(ownerUsername)
        if ownerData then
            return ownerData
        end
    end

    return Buildings.EnsureOwner and Buildings.EnsureOwner(ownerUsername) or nil
end

local function buildCompletedBarricadePlotMap(ownerData)
    local completedBarricades = {}

    for _, instance in ipairs(ownerData and ownerData.buildings or {}) do
        if tostring(instance and instance.buildingType or "") == "Barricade"
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            completedBarricades[Buildings.GetPlotKey(instance.plotX, instance.plotY)] = true
        end
    end

    return completedBarricades
end

local function hasCompletedBarricadeAt(completedBarricades, plotX, plotY)
    return completedBarricades[Buildings.GetPlotKey(plotX, plotY)] == true
end

local function hasCompletedFrontierNeighbor(completedBarricades, ring, plotX, plotY)
    local safeRing = math.max(1, math.floor(tonumber(ring) or 1))
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)

    for _, direction in ipairs(CARDINAL_DIRECTIONS) do
        local neighborX = x + direction.x
        local neighborY = y + direction.y
        if Buildings.GetPlotRing
            and Buildings.GetPlotRing(neighborX, neighborY) == safeRing
            and hasCompletedBarricadeAt(completedBarricades, neighborX, neighborY) then
            return true
        end
    end

    return false
end

local function addDesiredPlot(desiredPlots, x, y, kind)
    local plotX = math.floor(tonumber(x) or 0)
    local plotY = math.floor(tonumber(y) or 0)
    desiredPlots[Buildings.GetPlotKey(plotX, plotY)] = {
        x = plotX,
        y = plotY,
        kind = kind or Constants.PlotKinds.Standard
    }
end

local function buildEdge(ring, direction)
    local coords = {}
    local size = math.max(1, math.floor(tonumber(ring) or 1))
    if direction == "Left" then
        for y = -size, size do
            coords[#coords + 1] = { x = -size, y = y }
        end
    elseif direction == "Top" then
        for x = -size, size do
            coords[#coords + 1] = { x = x, y = -size }
        end
    elseif direction == "Right" then
        for y = -size, size do
            coords[#coords + 1] = { x = size, y = y }
        end
    else
        for x = -size, size do
            coords[#coords + 1] = { x = x, y = size }
        end
    end
    return coords
end

function Buildings.GetEdgeCoordinates(ring, direction)
    return buildEdge(math.max(1, math.floor(tonumber(ring) or 1)), Buildings.NormalizeDirection(direction))
end

function Buildings.GetRingCoordinates(ring)
    local coords = {}
    local seen = {}
    local size = math.max(1, math.floor(tonumber(ring) or 1))

    for _, direction in ipairs(Constants.Directions) do
        for _, cell in ipairs(buildEdge(size, direction)) do
            local key = Buildings.GetPlotKey(cell.x, cell.y)
            if not seen[key] then
                seen[key] = true
                coords[#coords + 1] = cell
            end
        end
    end

    return coords
end

function Buildings.UnlockRingFully(ownerUsername, ring)
    for _, direction in ipairs(Constants.Directions) do
        for _, cell in ipairs(Buildings.GetEdgeCoordinates(ring, direction)) do
            Buildings.UnlockPlotForOwner(ownerUsername, cell.x, cell.y, Constants.PlotKinds.Standard)
        end
    end
end

function Buildings.NormalizeFrontierUnlocks(ownerUsername)
    local mapData = Buildings.GetMapDataForOwner(ownerUsername)
    local ownerData = getOwnerDataForFrontier(ownerUsername)
    local completedBarricades = buildCompletedBarricadePlotMap(ownerData)
    local desiredPlots = {}
    local securedRing = Buildings.GetSecuredPerimeterRing and Buildings.GetSecuredPerimeterRing(ownerUsername) or 0
    local activeRing = Buildings.GetActiveFrontierRing and Buildings.GetActiveFrontierRing(ownerUsername) or 0
    local changed = false

    addDesiredPlot(desiredPlots, 0, 0, Constants.PlotKinds.HQOnly)

    for ring = 1, math.max(0, securedRing) do
        for _, cell in ipairs(Buildings.GetRingCoordinates and Buildings.GetRingCoordinates(ring) or {}) do
            addDesiredPlot(desiredPlots, cell.x, cell.y, Constants.PlotKinds.Standard)
        end
    end

    for _, instance in ipairs(ownerData and ownerData.buildings or {}) do
        if math.floor(tonumber(instance and instance.level) or 0) > 0 then
            addDesiredPlot(
                desiredPlots,
                instance.plotX,
                instance.plotY,
                math.floor(tonumber(instance.plotX) or 0) == 0 and math.floor(tonumber(instance.plotY) or 0) == 0
                    and Constants.PlotKinds.HQOnly
                    or Constants.PlotKinds.Standard
            )
        end
    end

    if activeRing > 0 then
        for _, cell in ipairs(Buildings.GetRingCoordinates and Buildings.GetRingCoordinates(activeRing) or {}) do
            if isCardinalSeed(activeRing, cell.x, cell.y)
                or hasCompletedFrontierNeighbor(completedBarricades, activeRing, cell.x, cell.y)
                or hasCompletedBarricadeAt(completedBarricades, cell.x, cell.y) then
                addDesiredPlot(desiredPlots, cell.x, cell.y, Constants.PlotKinds.Standard)
            end
        end
    end

    for key, desired in pairs(desiredPlots) do
        local plot = Buildings.GetOrCreatePlotForOwner(ownerUsername, desired.x, desired.y, desired.kind)
        if plot.unlocked ~= true then
            plot.unlocked = true
            changed = true
        end
        if tostring(plot.kind or "") ~= tostring(desired.kind or plot.kind or Constants.PlotKinds.Standard) then
            plot.kind = desired.kind
            changed = true
        end
    end

    for key, plot in pairs(mapData and mapData.plots or {}) do
        local desired = desiredPlots[key]
        local shouldUnlock = desired ~= nil
        if plot.unlocked ~= shouldUnlock then
            plot.unlocked = shouldUnlock
            changed = true
        end
        if desired and tostring(plot.kind or "") ~= tostring(desired.kind or plot.kind or Constants.PlotKinds.Standard) then
            plot.kind = desired.kind
            changed = true
        end
    end

    return changed
end

function Buildings.ExpandMapForHeadquartersUpgrade(ownerUsername)
    local ring = Buildings.GetActiveFrontierRing and Buildings.GetActiveFrontierRing(ownerUsername) or 0
    local unlockedPlots = {}

    if Buildings.NormalizeFrontierUnlocks then
        Buildings.NormalizeFrontierUnlocks(ownerUsername)
    end

    if ring > 0 then
        for _, cell in ipairs(Buildings.GetRingCoordinates and Buildings.GetRingCoordinates(ring) or {}) do
            if isCardinalSeed(ring, cell.x, cell.y) then
                local plot = Buildings.GetStoredPlotForOwner and Buildings.GetStoredPlotForOwner(ownerUsername, cell.x, cell.y) or nil
                if plot and plot.unlocked == true then
                    unlockedPlots[#unlockedPlots + 1] = Buildings.BuildVirtualPlot(plot.x, plot.y, true, plot.kind)
                end
            end
        end
    end

    return {
        ring = ring,
        plots = unlockedPlots
    }
end

function Buildings.GetVisibleRing(ownerUsername)
    local mapData = Buildings.GetMapDataForOwner(ownerUsername)
    return math.max(1, math.floor(tonumber(mapData.currentRing) or 1))
end

return Buildings
