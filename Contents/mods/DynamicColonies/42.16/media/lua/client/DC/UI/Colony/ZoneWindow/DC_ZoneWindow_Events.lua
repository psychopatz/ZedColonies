-- ============================================================================
-- DC_ZoneWindow_Events.lua — Event hooks for DC_ZoneWindow
--
-- For the PoC this is a placeholder. Future versions will hook into
-- colony data change events, EveryTenMinutes for auto-refresh, etc.
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}


--- Refresh all zone data in the window.
--- Called externally when colony data changes.
function DC_ZoneWindow:refreshFromColonyData()
    -- TODO: In the future, pull zones from colony mod data
    -- For now, zones are stored locally in self.zones
    self:populateZoneList()
    self:refreshDetailPanel()
end


--- Debug slash command to open zone window.
--- Usage in PZ console:  DC_ZoneWindow.DebugOpen()
function DC_ZoneWindow.DebugOpen()
    local player = getPlayer()
    if not player then
        print("[DC_ZoneWindow] No player found for debug open.")
        return
    end
    DC_ZoneWindow.Open(player, "debug_colony")
end

--- Add debug context menu option
function DC_ZoneWindow.OnFillWorldObjectContextMenu(player, context, worldobjects, test)
    if getCore():getDebug() then
        context:addOption("Debug: Zone Management", player, function()
            DC_ZoneWindow.DebugOpen()
        end)
    end
end

Events.OnFillWorldObjectContextMenu.Add(DC_ZoneWindow.OnFillWorldObjectContextMenu)
