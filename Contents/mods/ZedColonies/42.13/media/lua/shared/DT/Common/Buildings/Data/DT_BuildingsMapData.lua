DT_Buildings = DT_Buildings or {}
DT_Buildings.Internal = DT_Buildings.Internal or {}

local Buildings = DT_Buildings
local Internal = Buildings.Internal

Buildings.MapConstants = Buildings.MapConstants or {
    PlotKinds = {
        HQOnly = "HQOnly",
        Standard = "Standard"
    },
    PlotStates = {
        Locked = "Locked",
        Empty = "Empty",
        Reserved = "Reserved",
        Built = "Built"
    },
    Directions = { "Left", "Top", "Right", "Bottom" }
}

local Constants = Buildings.MapConstants

local function normalizePlotKind(kind, x, y)
    if math.floor(tonumber(x) or 0) == 0 and math.floor(tonumber(y) or 0) == 0 then
        return Constants.PlotKinds.HQOnly
    end
    if tostring(kind or "") == Constants.PlotKinds.HQOnly then
        return Constants.PlotKinds.HQOnly
    end
    return Constants.PlotKinds.Standard
end

function Buildings.NormalizeDirection(direction)
    local wanted = tostring(direction or "")
    for _, entry in ipairs(Constants.Directions) do
        if entry == wanted then
            return entry
        end
    end
    return Constants.Directions[1]
end

function Buildings.GetPlotKey(x, y)
    return tostring(math.floor(tonumber(x) or 0)) .. ":" .. tostring(math.floor(tonumber(y) or 0))
end

function Buildings.BuildVirtualPlot(x, y, unlocked, kind)
    local px = math.floor(tonumber(x) or 0)
    local py = math.floor(tonumber(y) or 0)
    return {
        x = px,
        y = py,
        kind = normalizePlotKind(kind, px, py),
        unlocked = unlocked == true
    }
end

function Buildings.EnsureMapData(ownerData)
    ownerData.map = type(ownerData.map) == "table" and ownerData.map or {}
    ownerData.map.plots = type(ownerData.map.plots) == "table" and ownerData.map.plots or {}
    ownerData.map.currentRing = math.max(1, math.floor(tonumber(ownerData.map.currentRing) or 1))
    ownerData.map.nextUnlockDirection = Buildings.NormalizeDirection(ownerData.map.nextUnlockDirection)

    local centerKey = Buildings.GetPlotKey(0, 0)
    if not ownerData.map.plots[centerKey] then
        ownerData.map.plots[centerKey] = Buildings.BuildVirtualPlot(0, 0, true, Constants.PlotKinds.HQOnly)
    else
        local center = ownerData.map.plots[centerKey]
        center.x = 0
        center.y = 0
        center.kind = Constants.PlotKinds.HQOnly
        center.unlocked = true
    end

    return ownerData.map
end

function Internal.GetOrCreatePlotInMap(mapData, x, y, kind)
    local key = Buildings.GetPlotKey(x, y)
    if not mapData.plots[key] then
        mapData.plots[key] = Buildings.BuildVirtualPlot(x, y, false, kind)
    end

    local plot = mapData.plots[key]
    plot.x = math.floor(tonumber(x) or 0)
    plot.y = math.floor(tonumber(y) or 0)
    plot.kind = normalizePlotKind(kind or plot.kind, plot.x, plot.y)
    plot.unlocked = plot.unlocked == true or (plot.x == 0 and plot.y == 0)
    return plot
end

function Internal.UnlockPlotInMap(mapData, x, y, kind)
    local plot = Internal.GetOrCreatePlotInMap(mapData, x, y, kind)
    plot.unlocked = true
    return plot
end

function Buildings.GetMapDataForOwner(ownerUsername)
    return Buildings.EnsureMapData(Buildings.EnsureOwner(ownerUsername))
end

function Buildings.GetStoredPlotForOwner(ownerUsername, x, y)
    local mapData = Buildings.GetMapDataForOwner(ownerUsername)
    return mapData.plots[Buildings.GetPlotKey(x, y)]
end

function Buildings.GetOrCreatePlotForOwner(ownerUsername, x, y, kind)
    local mapData = Buildings.GetMapDataForOwner(ownerUsername)
    return Internal.GetOrCreatePlotInMap(mapData, x, y, kind)
end

function Buildings.UnlockPlotForOwner(ownerUsername, x, y, kind)
    local plot = Buildings.GetOrCreatePlotForOwner(ownerUsername, x, y, kind)
    plot.unlocked = true
    return plot
end

function Buildings.BuildVisiblePlot(ownerUsername, x, y)
    local stored = Buildings.GetStoredPlotForOwner(ownerUsername, x, y)
    if stored then
        return Buildings.BuildVirtualPlot(stored.x, stored.y, stored.unlocked == true, stored.kind)
    end
    return Buildings.BuildVirtualPlot(x, y, false, nil)
end

return Buildings
