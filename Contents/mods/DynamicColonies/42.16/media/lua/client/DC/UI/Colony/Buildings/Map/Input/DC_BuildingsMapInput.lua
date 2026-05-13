require "DC/UI/Colony/Buildings/Map/Viewport/DC_BuildingsMapViewport"

DC_BuildingsMapInput = DC_BuildingsMapInput or {}

local Input = DC_BuildingsMapInput

Input.DRAG_THRESHOLD = Input.DRAG_THRESHOLD or 6

function Input.BeginDrag(panel)
    panel.dragActive = true
    panel.dragMoved = false
    panel.dragDistance = 0
end

function Input.UpdateDrag(panel, snapshot, dx, dy)
    if not panel.dragActive then
        return false
    end

    panel.dragDistance = (tonumber(panel.dragDistance) or 0) + math.abs(tonumber(dx) or 0) + math.abs(tonumber(dy) or 0)
    if panel.dragDistance > Input.DRAG_THRESHOLD then
        panel.dragMoved = true
    end

    if panel.dragMoved then
        panel.viewportState = DC_BuildingsMapViewport.PanByPixels(panel.viewportState or {}, snapshot, dx, dy)
    end
    return true
end

function Input.EndDrag(panel, snapshot, width, height, x, y)
    local shouldSelect = panel.dragActive == true and panel.dragMoved ~= true
    panel.dragActive = false

    if not shouldSelect then
        return nil
    end

    return DC_BuildingsMapViewport.PickPlot(snapshot or { map = { plots = {} } }, panel.viewportState or {}, width, height, x, y)
end

function Input.CancelDrag(panel)
    panel.dragActive = false
end

return Input