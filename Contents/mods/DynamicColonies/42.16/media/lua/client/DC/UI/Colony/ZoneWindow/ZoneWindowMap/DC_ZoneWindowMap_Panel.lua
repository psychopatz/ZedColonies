-- ============================================================================
-- DC_ZoneWindowMap_Panel.lua — Container panel that hosts ISWorldMap + overlay
--
-- This panel is shown when the "Map" tab is active. It creates a PZ map
-- widget inside itself and attaches the zone overlay for rendering.
-- ============================================================================

require "ISUI/ISPanel"

DC_ZoneWindowMapPanel = ISPanel:derive("DC_ZoneWindowMapPanel")

local MapOverlay = DC_ZoneWindow and DC_ZoneWindow.Internal and DC_ZoneWindow.Internal.MapOverlay


function DC_ZoneWindowMapPanel:initialise()
    ISPanel.initialise(self)
end


function DC_ZoneWindowMapPanel:createChildren()
    ISPanel.createChildren(self)

    -- Create the PZ map widget
    local mapX = 0
    local mapY = 0
    local mapW = self.width
    local mapH = self.height

    self.mapWidget = ISWorldMap:new(mapX, mapY, mapW, mapH)
    self.mapWidget:initialise()
    self.mapWidget:setAnchorRight(true)
    self.mapWidget:setAnchorBottom(true)
    self:addChild(self.mapWidget)

    -- Center the map on the player
    if self.ownerWindow and self.ownerWindow.player then
        local player = self.ownerWindow.player
        local px = player:getX()
        local py = player:getY()
        if self.mapWidget.mapAPI then
            self.mapWidget.mapAPI:centerOn(px, py)
        end
    end

    -- Create the map overlay
    if MapOverlay then
        self.overlay = MapOverlay:new(self.mapWidget)
        self.overlay:hookMapWidget()
    end
end


--- Refresh zone data on the overlay.
function DC_ZoneWindowMapPanel:refreshZones(zones, selectedZone, selectedRectIdx)
    if not self.overlay then return end

    self.overlay:setZones(zones or {})
    if selectedZone then
        self.overlay:setSelected(selectedZone.id, selectedRectIdx)
    else
        self.overlay:setSelected(nil, nil)
    end
end


function DC_ZoneWindowMapPanel:prerender()
    ISPanel.prerender(self)

    -- Resize map widget to fill panel
    if self.mapWidget then
        self.mapWidget:setWidth(self.width)
        self.mapWidget:setHeight(self.height)
    end
end


function DC_ZoneWindowMapPanel:new(x, y, width, height, ownerWindow)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.05, g = 0.05, b = 0.08, a = 1 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
    o.ownerWindow = ownerWindow
    return o
end


return DC_ZoneWindowMapPanel
