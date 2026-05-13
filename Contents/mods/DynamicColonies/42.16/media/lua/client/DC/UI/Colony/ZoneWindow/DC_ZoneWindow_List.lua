-- ============================================================================
-- DC_ZoneWindow_List.lua — Zone list panel logic
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}
require "DC/UI/Colony/ZoneWindow/ZoneWindowState/DC_ZoneWindowState"

local Formatters = DC_ZoneWindow.Internal.Formatters


--- Rebuild the zone list from self.zones.
function DC_ZoneWindow:populateZoneList()
    if not self.zoneList then return end

    self.zoneList:clear()

    for i, zone in ipairs(DC_ZoneWindowState.GetZones(self)) do
        local label = Formatters and Formatters.formatZoneLabel
            and Formatters.formatZoneLabel(zone)
            or (zone.name or "Zone " .. tostring(i))

        self.zoneList:addItem(label, zone)
    end

    -- Re-select current zone if still present
    local selectedZone = DC_ZoneWindowState.GetSelectedZone(self)
    if selectedZone then
        for i = 1, self.zoneList:size() do
            local item = self.zoneList.items[i]
            if item and item.item and item.item.id == selectedZone.id then
                self.zoneList.selected = i
                return
            end
        end
    end
end


--- Handle mouse-down on the zone list.
function DC_ZoneWindow:onZoneListMouseDown(item)
    if not item then return end

    local zone = item
    if type(item) == "table" and item.item then
        zone = item.item
    end

    self:onZoneSelected(zone)
end


--- Custom draw for zone list rows with type colour bar.
function DC_ZoneWindow:renderZoneListItem(index, item, y, alt)
    if not item then return end

    local zone = item.item
    if not zone then return end

    local list = self.zoneList
    local color = DC_ZoneData.getColor(zone)

    -- Type colour bar on the left edge
    list:drawRect(0, y, 4, list.itemheight, color.a or 0.6, color.r or 0.5, color.g or 0.5, color.b or 0.5)

    -- Highlight selected
    if index == list.selected then
        list:drawRect(4, y, list.width - 4, list.itemheight, 0.15, 0.9, 0.55, 0.1)
    elseif list.mouseoverselected == index then
        list:drawRect(4, y, list.width - 4, list.itemheight, 0.08, 1, 1, 1)
    end

    -- Zone name
    list:drawText(item.text or "", 12, y + 6, 0.9, 0.9, 0.9, 1, UIFont.Small)
end
