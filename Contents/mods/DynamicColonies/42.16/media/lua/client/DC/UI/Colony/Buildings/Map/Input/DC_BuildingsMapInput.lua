require "DC/UI/Colony/Buildings/Map/Viewport/DC_BuildingsMapViewport"

DC_BuildingsMapInput = DC_BuildingsMapInput or {}

local Input = DC_BuildingsMapInput

Input.DRAG_THRESHOLD = Input.DRAG_THRESHOLD or 6

local function pickPlotAtCoordinates(panel, snapshot, width, height, mouseX, mouseY)
    local plotsSnapshot = snapshot or { map = { plots = {} } }
    local viewportState = panel.viewportState or {}

    local plot = DC_BuildingsMapViewport.PickPlot(plotsSnapshot, viewportState, width, height, mouseX, mouseY)
    if plot then
        return plot
    end

    local panelX = 0
    local panelY = 0
    if panel and panel.getAbsoluteX then
        panelX = tonumber(panel:getAbsoluteX()) or 0
    elseif panel then
        panelX = tonumber(panel.x) or 0
    end
    if panel and panel.getAbsoluteY then
        panelY = tonumber(panel:getAbsoluteY()) or 0
    elseif panel then
        panelY = tonumber(panel.y) or 0
    end
    if panelX ~= 0 or panelY ~= 0 then
        plot = DC_BuildingsMapViewport.PickPlot(plotsSnapshot, viewportState, width, height, mouseX - panelX, mouseY - panelY)
        if plot then
            return plot
        end
    end

    return nil
end

function Input.BeginDrag(panel, x, y)
    panel.dragActive = true
    panel.dragMoved = false
    panel.dragDistance = 0
    panel.dragStartX = x
    panel.dragStartY = y
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
    local dragStartX = panel.dragStartX
    local dragStartY = panel.dragStartY
    panel.dragActive = false
    panel.dragStartX = nil
    panel.dragStartY = nil

    if not shouldSelect then
        return nil
    end

    local plot = pickPlotAtCoordinates(panel, snapshot, width, height, x, y)
    if plot then
        return plot
    end

    if dragStartX ~= nil and dragStartY ~= nil then
        plot = pickPlotAtCoordinates(panel, snapshot, width, height, dragStartX, dragStartY)
        if plot then
            return plot
        end
    end

    return nil
end

function Input.CancelDrag(panel)
    panel.dragActive = false
    panel.dragStartX = nil
    panel.dragStartY = nil
end

return Input