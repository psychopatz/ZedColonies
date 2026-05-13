require "ISUI/ISPanel"
require "DC/UI/Colony/Buildings/Map/Viewport/DC_BuildingsMapViewport"
require "DC/UI/Colony/Buildings/Map/Input/DC_BuildingsMapInput"
require "DC/UI/Colony/Buildings/Map/Render/DC_BuildingsMapRenderer"

DC_BuildingsMapPanel = ISPanel:derive("DC_BuildingsMapPanel")
local MapCanvasPanel = ISPanel:derive("DC_BuildingsMapCanvasPanel")

DC_BuildingsMapPanel.HEADER_HEIGHT = 36

function MapCanvasPanel:initialise()
    ISPanel.initialise(self)
end

function MapCanvasPanel:setMapState(snapshot, selectedPlotKey, viewportState)
    self.snapshot = snapshot
    self.selectedPlotKey = selectedPlotKey
    self.viewportState = viewportState
end

function MapCanvasPanel:prerender()
    ISPanel.prerender(self)
    DC_BuildingsMapRenderer.DrawTiles(self, self.snapshot or { map = { plots = {} } }, self.viewportState or {}, self.selectedPlotKey)
end

function MapCanvasPanel:onMouseDown(x, y)
    DC_BuildingsMapInput.BeginDrag(self, x, y)
    return true
end

function MapCanvasPanel:onMouseDownOutside(x, y)
    return self:onMouseDown(x, y)
end

function MapCanvasPanel:onMouseMove(dx, dy)
    local handled = DC_BuildingsMapInput.UpdateDrag(self, self.snapshot, dx, dy)
    if handled and self.ownerPanel then
        self.ownerPanel.viewportState = self.viewportState
    end
    return handled
end

function MapCanvasPanel:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function MapCanvasPanel:onMouseUp(x, y)
    local plot = DC_BuildingsMapInput.EndDrag(self, self.snapshot, self.width, self.height, x, y)
    if self.ownerPanel then
        self.ownerPanel.viewportState = self.viewportState
    end
    if plot and self.onPlotSelectedCallback then
        self.onPlotSelectedCallback(plot)
    end
    return true
end

function MapCanvasPanel:onMouseUpOutside(x, y)
    local plot = DC_BuildingsMapInput.EndDrag(self, self.snapshot, self.width, self.height, x, y)
    if self.ownerPanel then
        self.ownerPanel.viewportState = self.viewportState
    end
    if plot and self.onPlotSelectedCallback then
        self.onPlotSelectedCallback(plot)
    else
        DC_BuildingsMapInput.CancelDrag(self)
    end
    return true
end

function MapCanvasPanel:new(x, y, width, height, ownerPanel, onPlotSelectedCallback)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.snapshot = { map = { plots = {} } }
    o.viewportState = {
        tileSize = DC_BuildingsMapViewport.DEFAULT_TILE_SIZE,
        gap = DC_BuildingsMapViewport.DEFAULT_GAP,
        topInset = 0
    }
    o.ownerPanel = ownerPanel
    o.onPlotSelectedCallback = onPlotSelectedCallback
    return o
end

local function ensureCanvas(panel)
    if panel.canvasPanel then
        return
    end

    panel.canvasPanel = MapCanvasPanel:new(
        0,
        DC_BuildingsMapPanel.HEADER_HEIGHT,
        panel.width,
        math.max(0, panel.height - DC_BuildingsMapPanel.HEADER_HEIGHT),
        panel,
        panel.onPlotSelectedCallback
    )
    panel.canvasPanel:initialise()
    panel.canvasPanel:setAnchorLeft(true)
    panel.canvasPanel:setAnchorRight(true)
    panel.canvasPanel:setAnchorTop(true)
    panel.canvasPanel:setAnchorBottom(true)
    panel:addChild(panel.canvasPanel)
end

local function relayoutCanvas(panel)
    ensureCanvas(panel)

    panel.canvasPanel:setX(0)
    panel.canvasPanel:setY(DC_BuildingsMapPanel.HEADER_HEIGHT)
    panel.canvasPanel:setWidth(panel.width)
    panel.canvasPanel:setHeight(math.max(0, panel.height - DC_BuildingsMapPanel.HEADER_HEIGHT))
    panel.canvasPanel:setMapState(panel.snapshot, panel.selectedPlotKey, panel.viewportState)
end

function DC_BuildingsMapPanel:initialise()
    ISPanel.initialise(self)
    ensureCanvas(self)
    relayoutCanvas(self)
end

function DC_BuildingsMapPanel:setSnapshot(snapshot, selectedPlotKey)
    self.snapshot = snapshot
    self.selectedPlotKey = selectedPlotKey
    self.viewportState = DC_BuildingsMapViewport.EnsureState(self.viewportState, snapshot)
    self.viewportState.topInset = 0
    relayoutCanvas(self)
end

function DC_BuildingsMapPanel:prerender()
    ISPanel.prerender(self)
    DC_BuildingsMapRenderer.DrawHeader(self, self.snapshot and self.snapshot.map or {})
end

function DC_BuildingsMapPanel:onResize()
    ISPanel.onResize(self)
    relayoutCanvas(self)
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
        gap = DC_BuildingsMapViewport.DEFAULT_GAP,
        topInset = 0
    }
    o.onPlotSelectedCallback = onPlotSelectedCallback
    return o
end

return DC_BuildingsMapPanel
