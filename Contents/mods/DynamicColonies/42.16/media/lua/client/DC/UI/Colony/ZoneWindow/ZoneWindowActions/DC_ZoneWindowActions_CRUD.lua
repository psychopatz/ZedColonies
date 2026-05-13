-- ============================================================================
-- DC_ZoneWindowActions_CRUD.lua — Create / Delete / Rename zone operations
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
require "DC/UI/Colony/ZoneWindow/ZoneWindowState/DC_ZoneWindowState"


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
        name = "Zone " .. tostring(#DC_ZoneWindowState.GetZones(self) + 1)
    end

    local zone = DC_ZoneData.createZone(name, "roaming", self.colonyId)
    DC_ZoneWindowState.AddZone(self, zone)
end


--- Delete the currently selected zone.
function DC_ZoneWindow:onDeleteZone()
    local selectedZone = DC_ZoneWindowState.GetSelectedZone(self)
    if not selectedZone then return end

    local modal = ISModalDialog:new(0, 0, 300, 120,
        "Delete zone '" .. tostring(selectedZone.name) .. "'?",
        true, self, DC_ZoneWindow.onDeleteZoneConfirm)
    modal:initialise()
    modal:addToUIManager()
end


--- Callback for delete confirmation.
function DC_ZoneWindow:onDeleteZoneConfirm(button)
    if button.internal ~= "YES" then return end

    DC_ZoneWindowState.RemoveZone(self, DC_ZoneWindowState.GetSelectedZone(self))
end
