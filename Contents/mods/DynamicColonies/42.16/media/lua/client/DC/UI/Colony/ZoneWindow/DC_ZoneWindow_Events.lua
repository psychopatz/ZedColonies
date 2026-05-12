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
    self:requestBaseSnapshot()
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

local function onServerCommand(module, command, args)
    local expectedModule = ((DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony")
    if module ~= expectedModule then
        return
    end

    if command ~= "SyncBaseSnapshot" then
        return
    end

    if DC_ZoneWindow.instance and args and args.snapshot then
        DC_ZoneWindow.instance:applyBaseSnapshot(args.snapshot, args.version)
    end
end

if not DC_ZoneWindow.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    DC_ZoneWindow.EventsAdded = true
end
