-- ============================================================================
-- DC_ZoneWindowActions_CRUD.lua — Create / Delete / Rename zone operations
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}


--- Add a new zone. Prompts for name via a modal dialog.
function DC_ZoneWindow:onAddZone()
    local modal = ISTextBox:new(0, 0, 280, 120, "Zone Name:", "",
        self, DC_ZoneWindow.onAddZoneConfirm, nil)
    modal:initialise()
    modal:addToUIManager()
    modal:setVisible(true)
    modal.entry:focus()
end


--- Callback when user confirms the zone name.
function DC_ZoneWindow:onAddZoneConfirm(button, _, _)
    if button.internal ~= "OK" then return end

    local name = button.parent.entry:getText()
    if not name or name == "" then
        name = "Zone " .. tostring(#self.zones + 1)
    end

    local zone = DC_ZoneData.createZone(name, "roaming", self.colonyId)
    table.insert(self.zones, zone)

    self:populateZoneList()

    -- Auto-select the new zone
    self.selectedZone = zone
    self.selectedRect = nil
    self.zoneList.selected = #self.zones
    self:refreshDetailPanel()
end


--- Delete the currently selected zone.
function DC_ZoneWindow:onDeleteZone()
    if not self.selectedZone then return end

    local modal = ISModalDialog:new(0, 0, 300, 120,
        "Delete zone '" .. tostring(self.selectedZone.name) .. "'?",
        true, self, DC_ZoneWindow.onDeleteZoneConfirm)
    modal:initialise()
    modal:addToUIManager()
end


--- Callback for delete confirmation.
function DC_ZoneWindow:onDeleteZoneConfirm(button)
    if button.internal ~= "YES" then return end

    -- Find and remove
    for i, zone in ipairs(self.zones) do
        if zone.id == self.selectedZone.id then
            table.remove(self.zones, i)
            break
        end
    end

    self.selectedZone = nil
    self.selectedRect = nil
    self:populateZoneList()
    self:refreshDetailPanel()
end
