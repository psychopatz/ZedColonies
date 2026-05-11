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
        0, 0, 320, 180,
        self.player,
        highlightColor,
        function(x1, y1, x2, y2, z)
            DC_ZoneData.addRect(zone, x1, y1, x2, y2, z)
            self:refreshDetailPanel()
            self:populateZoneList()
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
end
