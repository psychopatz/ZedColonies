require "ISUI/ISPanel"
require "DC/UI/Colony/Buildings/Map/Viewport/DC_BuildingsMapViewport"
require "DC/UI/Colony/Buildings/Map/Input/DC_BuildingsMapInput"
require "DC/UI/Colony/Buildings/Map/Render/DC_BuildingsMapRenderer"

DC_BuildingsMapPanel = ISPanel:derive("DC_BuildingsMapPanel")

function DC_BuildingsMapPanel:initialise()
    ISPanel.initialise(self)
end

function DC_BuildingsMapPanel:setSnapshot(snapshot, selectedPlotKey)
    self.snapshot = snapshot
    self.selectedPlotKey = selectedPlotKey
    self.viewportState = DC_BuildingsMapViewport.EnsureState(self.viewportState, snapshot)
end

function DC_BuildingsMapPanel:prerender()
    ISPanel.prerender(self)
    DC_BuildingsMapRenderer.Draw(self, self.snapshot or { map = { plots = {} } }, self.viewportState or {}, self.selectedPlotKey)
end

function DC_BuildingsMapPanel:onMouseDown(x, y)
    DC_BuildingsMapInput.BeginDrag(self)
    return true
end

function DC_BuildingsMapPanel:onMouseMove(dx, dy)
    return DC_BuildingsMapInput.UpdateDrag(self, self.snapshot, dx, dy)
end

function DC_BuildingsMapPanel:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function DC_BuildingsMapPanel:onMouseUp(x, y)
    local plot = DC_BuildingsMapInput.EndDrag(self, self.snapshot, self.viewportState or {}, self.width, self.height, x, y)
    if plot and self.onPlotSelectedCallback then
        self.onPlotSelectedCallback(plot)
    end
    return true
end

function DC_BuildingsMapPanel:onMouseUpOutside(x, y)
    DC_BuildingsMapInput.CancelDrag(self)
    return true
end

function DC_BuildingsMapPanel:new(x, y, width, height, onPlotSelectedCallback)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    o.snapshot = { map = { plots = {} } }
    o.viewportState = {
        tileSize = DC_BuildingsMapViewport.DEFAULT_TILE_SIZE,
        gap = DC_BuildingsMapViewport.DEFAULT_GAP
    }
    o.onPlotSelectedCallback = onPlotSelectedCallback
    return o
end

return DC_BuildingsMapPanel
