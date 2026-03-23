DT_Buildings = DT_Buildings or {}

local Buildings = DT_Buildings
local Constants = Buildings.MapConstants

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

function Buildings.ExpandMapForHeadquartersUpgrade(ownerUsername)
    local mapData = Buildings.GetMapDataForOwner(ownerUsername)
    local ring = math.max(1, math.floor(tonumber(mapData.currentRing) or 1))
    local direction = Buildings.NormalizeDirection(mapData.nextUnlockDirection)
    local unlockedPlots = {}

    for _, cell in ipairs(Buildings.GetEdgeCoordinates(ring, direction)) do
        unlockedPlots[#unlockedPlots + 1] = Buildings.UnlockPlotForOwner(ownerUsername, cell.x, cell.y, Constants.PlotKinds.Standard)
    end

    local nextDirection = "Left"
    if direction == "Left" then
        nextDirection = "Top"
    elseif direction == "Top" then
        nextDirection = "Right"
    elseif direction == "Right" then
        nextDirection = "Bottom"
    else
        nextDirection = "Left"
        mapData.currentRing = ring + 1
    end

    mapData.nextUnlockDirection = nextDirection
    return {
        ring = ring,
        direction = direction,
        plots = unlockedPlots
    }
end

function Buildings.GetVisibleRing(ownerUsername)
    local mapData = Buildings.GetMapDataForOwner(ownerUsername)
    return math.max(1, math.floor(tonumber(mapData.currentRing) or 1))
end

return Buildings
