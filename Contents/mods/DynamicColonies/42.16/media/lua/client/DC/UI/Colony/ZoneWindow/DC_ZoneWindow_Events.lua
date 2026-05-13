-- ============================================================================
-- DC_ZoneWindow_Events.lua — Event hooks for DC_ZoneWindow
--
-- For the PoC this is a placeholder. Future versions will hook into
-- colony data change events, EveryTenMinutes for auto-refresh, etc.
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
require "DC/UI/Colony/ZoneWindow/ZoneWindowState/DC_ZoneWindowState"
require "DC/Common/Zone/DC_ZoneDataStore"
require "DC/UI/Colony/ZoneWindow/ZoneWindowSync/DC_ZoneWindowSync"


--- Refresh all zone data in the window.
--- Called externally when colony data changes.
function DC_ZoneWindow:refreshFromColonyData()
    if DC_ZoneWindowSync and DC_ZoneWindowSync.RequestSnapshot then
        DC_ZoneWindowSync.RequestSnapshot(self)
    end
    DC_ZoneWindowState.RefreshWindow(self)
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

if not DC_ZoneWindow.EventsAdded then
    Events.OnReceiveGlobalModData.Add(function(key, data)
        if key ~= DC_ZoneDataStore.MOD_DATA_KEY then
            return
        end

        if DC_ZoneWindow.instance then
            DC_ZoneWindowState.RefreshWindow(DC_ZoneWindow.instance)
        end
    end)
    DC_ZoneWindow.EventsAdded = true
end
