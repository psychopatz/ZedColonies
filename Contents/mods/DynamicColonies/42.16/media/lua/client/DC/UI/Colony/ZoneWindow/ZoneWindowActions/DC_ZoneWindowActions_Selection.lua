-- ============================================================================
-- DC_ZoneWindowActions_Selection.lua — Zone and rect selection + area management
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
require "DC/UI/Colony/ZoneWindow/ZoneWindowState/DC_ZoneWindowState"


--- Handle zone selection from the list.
function DC_ZoneWindow:onZoneSelected(zone)
    if not zone then return end

    DC_ZoneWindowState.SelectZone(self, zone)
end


--- Handle mouse-down on the rect list.
function DC_ZoneWindow:onRectListMouseDown(item)
    if not item then return end

    local data = item
    if type(item) == "table" and item.item then
        data = item.item
    end

    if data and data.index then
        DC_ZoneWindowState.SetSelectedRect(self, data.index)
    end
end


--- Open the 3D area selector to add a new rect to the selected zone.
function DC_ZoneWindow:onAddArea()
    local selectedZone = DC_ZoneWindowState.GetSelectedZone(self)
    if not selectedZone then return end

    local color = DC_ZoneData.getColor(selectedZone)
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
            DC_ZoneData.addRect(selectedZone, x1, y1, x2, y2, z)
            self:refreshDetailPanel()
            self:populateZoneList()
            DC_ZoneWindowState.MarkDirty(self)
        end,
        selectedZone.name
    )
    selector:initialise()
    selector:addToUIManager()
end


--- Delete the currently selected rect from the selected zone.
function DC_ZoneWindow:onDeleteArea()
    local selectedZone = DC_ZoneWindowState.GetSelectedZone(self)
    local selectedRect = DC_ZoneWindowState.GetSelectedRect(self)
    if not selectedZone or not selectedRect then return end

    DC_ZoneData.removeRect(selectedZone, selectedRect)
    DC_ZoneWindowState.SetSelectedRect(self, nil)
    self:refreshDetailPanel()
    self:populateZoneList()
    DC_ZoneWindowState.MarkDirty(self)
end


--- Show the selected rect highlighted in the 3D world for a few seconds.
function DC_ZoneWindow:onShowArea()
    local selectedZone = DC_ZoneWindowState.GetSelectedZone(self)
    local selectedRect = DC_ZoneWindowState.GetSelectedRect(self)
    if not selectedZone or not selectedRect then return end

    local rect = selectedZone.rects and selectedZone.rects[selectedRect]
    if not rect then return end

    local color = DC_ZoneData.getColor(selectedZone)
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
    local selectedZone = DC_ZoneWindowState.GetSelectedZone(self)
    local selectedRect = DC_ZoneWindowState.GetSelectedRect(self)
    if not selectedZone or not selectedRect then return end

    local rect = selectedZone.rects and selectedZone.rects[selectedRect]
    if not rect then return end

    local color = DC_ZoneData.getColor(selectedZone)
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
            selectedZone.rects[selectedRect] = { rx1, ry1, rx2, ry2, z or 0 }
            self:refreshDetailPanel()
            self:populateZoneList()
            DC_ZoneWindowState.MarkDirty(self)
        end,
        selectedZone.name .. " (Edit)",
        rect
    )
    selector:initialise()
    selector:addToUIManager()
end


--- Nudge the selected rect.
function DC_ZoneWindow:onNudgeRect(dx, dy)
    local selectedZone = DC_ZoneWindowState.GetSelectedZone(self)
    local selectedRect = DC_ZoneWindowState.GetSelectedRect(self)
    if not selectedZone or not selectedRect then return end

    local rect = selectedZone.rects[selectedRect]
    if not rect then return end

    DC_ZoneData.nudgeRect(rect, dx, dy)
    self:refreshDetailPanel()
    DC_ZoneWindowState.MarkDirty(self)
end


--- Scale the selected rect.
function DC_ZoneWindow:onScaleRect(edge, amount)
    local selectedZone = DC_ZoneWindowState.GetSelectedZone(self)
    local selectedRect = DC_ZoneWindowState.GetSelectedRect(self)
    if not selectedZone or not selectedRect then return end

    local rect = selectedZone.rects[selectedRect]
    if not rect then return end

    DC_ZoneData.scaleRect(rect, edge, amount)
    self:refreshDetailPanel()
    DC_ZoneWindowState.MarkDirty(self)
end
