-- ============================================================================
-- DC_ZoneWindowActions_Selection.lua — Zone and rect selection + area management
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}


--- Handle zone selection from the list.
function DC_ZoneWindow:onZoneSelected(zone)
    if not zone then return end

    self.selectedZone = zone
    self.selectedRect = nil
    self:refreshDetailPanel()
    if self.mapPanel and self.mapPanel.refreshZones then
        self.mapPanel:refreshZones(self.zones, self.selectedZone)
    end
end


--- Open the 3D area selector to add a new rect to the selected zone.
function DC_ZoneWindow:onAddArea()
    if not self.selectedZone then return end

    local zone = self.selectedZone
    local color = DC_ZoneData.getColor(zone)
    local highlightColor = {
        r = color.r or 0.2,
        g = color.g or 0.8,
        b = color.b or 0.2,
        a = 0.5,
    }

    local selector = DC_ZoneSelector:new(
        0, 0, 340, 260,
        self.player,
        highlightColor,
        function(x1, y1, x2, y2, z)
            DC_ZoneData.addRect(zone, x1, y1, x2, y2, z)
            self:refreshDetailPanel()
            self:populateZoneList()
            self:commitZonesSnapshot()
        end,
        zone.name
    )
    selector:initialise()
    selector:addToUIManager()
end


--- Delete the currently selected rect from the selected zone.
function DC_ZoneWindow:onDeleteArea()
    if not self.selectedZone or not self.selectedRect then return end

    DC_ZoneData.removeRect(self.selectedZone, self.selectedRect)
    self.selectedRect = nil
    self:refreshDetailPanel()
    self:populateZoneList()
    self:commitZonesSnapshot()
end


--- Show the selected rect highlighted in the 3D world for a few seconds.
function DC_ZoneWindow:onShowArea()
    if not self.selectedZone or not self.selectedRect then return end

    local zone = self.selectedZone
    local rect = zone.rects and zone.rects[self.selectedRect]
    if not rect then return end

    local color = DC_ZoneData.getColor(zone)
    local x1 = math.min(rect[1], rect[3])
    local y1 = math.min(rect[2], rect[4])
    local x2 = math.max(rect[1], rect[3])
    local y2 = math.max(rect[2], rect[4])
    local z  = rect[5] or self.player:getZ()

    -- Flash highlight for ~5 seconds via repeated calls
    -- (addAreaHighlightForPlayer lasts one frame, so we schedule it)
    self._showAreaTicks = 0
    self._showAreaMax = 300  -- ~5 seconds at 60fps
    self._showAreaData = { x1 = x1, y1 = y1, x2 = x2 + 1, y2 = y2 + 1, z = z,
        r = color.r or 0.5, g = color.g or 0.5, b = color.b or 0.5, a = 0.6 }
end


--- Called each frame from prerender to keep the area highlighted.
function DC_ZoneWindow:tickShowArea()
    if not self._showAreaData or not self._showAreaTicks then return end
    if self._showAreaTicks >= self._showAreaMax then
        self._showAreaData = nil
        self._showAreaTicks = nil
        return
    end

    local d = self._showAreaData
    addAreaHighlightForPlayer(self.player:getPlayerNum(), d.x1, d.y1, d.x2, d.y2, d.z, d.r, d.g, d.b, d.a)
    self._showAreaTicks = self._showAreaTicks + 1
end


--- Edit the selected rect: opens selector pre-loaded, then replaces the rect.
function DC_ZoneWindow:onEditArea()
    if not self.selectedZone or not self.selectedRect then return end

    local zone = self.selectedZone
    local rectIdx = self.selectedRect
    local rect = zone.rects and zone.rects[rectIdx]
    if not rect then return end

    local color = DC_ZoneData.getColor(zone)
    local highlightColor = {
        r = color.r or 0.2,
        g = color.g or 0.8,
        b = color.b or 0.2,
        a = 0.5,
    }

    local selector = DC_ZoneSelector:new(
        0, 0, 340, 260,
        self.player,
        highlightColor,
        function(x1, y1, x2, y2, z)
            -- Replace the existing rect
            local rx1 = math.min(x1, x2)
            local ry1 = math.min(y1, y2)
            local rx2 = math.max(x1, x2)
            local ry2 = math.max(y1, y2)
            zone.rects[rectIdx] = { rx1, ry1, rx2, ry2, z or 0 }
            self:refreshDetailPanel()
            self:populateZoneList()
            self:commitZonesSnapshot()
        end,
        zone.name .. " (Edit)"
    )
    selector:initialise()
    selector:addToUIManager()
end


--- Nudge the selected rect.
function DC_ZoneWindow:onNudgeRect(dx, dy)
    if not self.selectedZone or not self.selectedRect then return end
    local rect = self.selectedZone.rects[self.selectedRect]
    if not rect then return end

    DC_ZoneData.nudgeRect(rect, dx, dy)
    self:refreshDetailPanel()
    self:commitZonesSnapshot()
end


--- Scale the selected rect.
function DC_ZoneWindow:onScaleRect(edge, amount)
    if not self.selectedZone or not self.selectedRect then return end
    local rect = self.selectedZone.rects[self.selectedRect]
    if not rect then return end

    DC_ZoneData.scaleRect(rect, edge, amount)
    self:refreshDetailPanel()
    self:commitZonesSnapshot()
end
