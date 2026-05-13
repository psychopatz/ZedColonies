DC_BuildingsMapViewport = DC_BuildingsMapViewport or {}

local Viewport = DC_BuildingsMapViewport

Viewport.DEFAULT_TILE_SIZE = 96
Viewport.DEFAULT_GAP = 10
Viewport.DEFAULT_BOUNDS_PADDING = 2
Viewport.DEFAULT_TOP_INSET = 28

local function getSnapshotBounds(snapshot)
    return snapshot and snapshot.map and snapshot.map.bounds or snapshot and snapshot.bounds or {
        minX = 0,
        maxX = 0,
        minY = 0,
        maxY = 0
    }
end

local function getDefaultCenter(snapshot)
    local plots = snapshot and snapshot.map and snapshot.map.plots or {}
    for _, plot in ipairs(plots) do
        if math.floor(tonumber(plot.x) or 0) == 0 and math.floor(tonumber(plot.y) or 0) == 0 then
            return 0, 0
        end
    end

    local bounds = getSnapshotBounds(snapshot)
    return (tonumber(bounds.minX) + tonumber(bounds.maxX)) / 2, (tonumber(bounds.minY) + tonumber(bounds.maxY)) / 2
end

function Viewport.EnsureState(state, snapshot)
    state = type(state) == "table" and state or {}
    state.tileSize = math.max(64, math.floor(tonumber(state.tileSize) or Viewport.DEFAULT_TILE_SIZE))
    state.gap = math.max(4, math.floor(tonumber(state.gap) or Viewport.DEFAULT_GAP))
    state.topInset = math.max(0, math.floor(tonumber(state.topInset) or Viewport.DEFAULT_TOP_INSET))

    if state.centerX == nil or state.centerY == nil then
        state.centerX, state.centerY = getDefaultCenter(snapshot)
    end

    return Viewport.ClampState(state, snapshot)
end

function Viewport.ClampState(state, snapshot)
    local bounds = getSnapshotBounds(snapshot)
    local padding = Viewport.DEFAULT_BOUNDS_PADDING

    local minX = math.floor(tonumber(bounds.minX) or 0) - padding
    local maxX = math.floor(tonumber(bounds.maxX) or 0) + padding
    local minY = math.floor(tonumber(bounds.minY) or 0) - padding
    local maxY = math.floor(tonumber(bounds.maxY) or 0) + padding

    state.centerX = math.max(minX, math.min(maxX, tonumber(state.centerX) or 0))
    state.centerY = math.max(minY, math.min(maxY, tonumber(state.centerY) or 0))
    return state
end

function Viewport.GetLayout(width, height, state)
    local tile = math.max(64, math.floor(tonumber(state and state.tileSize) or Viewport.DEFAULT_TILE_SIZE))
    local gap = math.max(4, math.floor(tonumber(state and state.gap) or Viewport.DEFAULT_GAP))
    local topInset = math.max(0, math.floor(tonumber(state and state.topInset) or Viewport.DEFAULT_TOP_INSET))
    return {
        tile = tile,
        gap = gap,
        step = tile + gap,
        centerX = math.floor((tonumber(width) or 0) / 2),
        centerY = math.floor(((tonumber(height) or 0) + topInset) / 2)
    }
end

function Viewport.GetPlotRect(plot, state, width, height)
    local layout = Viewport.GetLayout(width, height, state)
    local plotX = math.floor(tonumber(plot and plot.x) or 0)
    local plotY = math.floor(tonumber(plot and plot.y) or 0)
    local drawX = layout.centerX + ((plotX - (tonumber(state and state.centerX) or 0)) * layout.step) - math.floor(layout.tile / 2)
    local drawY = layout.centerY + ((plotY - (tonumber(state and state.centerY) or 0)) * layout.step) - math.floor(layout.tile / 2)
    return {
        x = drawX,
        y = drawY,
        width = layout.tile,
        height = layout.tile
    }
end

function Viewport.IsRectVisible(rect, width, height)
    if not rect then
        return false
    end
    return rect.x + rect.width >= 0
        and rect.y + rect.height >= 24
        and rect.x <= width
        and rect.y <= height
end

function Viewport.PanByPixels(state, snapshot, deltaX, deltaY)
    local layout = Viewport.GetLayout(0, 0, state)
    if layout.step <= 0 then
        return state
    end

    state.centerX = (tonumber(state.centerX) or 0) - ((tonumber(deltaX) or 0) / layout.step)
    state.centerY = (tonumber(state.centerY) or 0) - ((tonumber(deltaY) or 0) / layout.step)
    return Viewport.ClampState(state, snapshot)
end

function Viewport.PickPlot(snapshot, state, width, height, mouseX, mouseY)
    for index = #(snapshot and snapshot.map and snapshot.map.plots or {}), 1, -1 do
        local plot = snapshot.map.plots[index]
        local rect = Viewport.GetPlotRect(plot, state, width, height)
        if rect
            and mouseX >= rect.x
            and mouseX <= (rect.x + rect.width)
            and mouseY >= rect.y
            and mouseY <= (rect.y + rect.height) then
            return plot
        end
    end
    return nil
end

return Viewport
