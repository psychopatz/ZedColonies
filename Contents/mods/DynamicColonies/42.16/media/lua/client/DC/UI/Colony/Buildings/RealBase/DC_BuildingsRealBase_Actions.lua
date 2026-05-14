DC_BuildingsRealBaseUI = DC_BuildingsRealBaseUI or {}

local UI = DC_BuildingsRealBaseUI

local function getCommandModule()
    return ((DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony")
end

local function getLocalPlayer()
    if getSpecificPlayer then
        return getSpecificPlayer(0)
    end
    if getPlayer then
        return getPlayer()
    end
    return nil
end

function UI.SendCommand(command, args)
    local player = getLocalPlayer()
    if not player then
        return false
    end

    if isClient() and not isServer() then
        sendClientCommand(player, getCommandModule(), command, args or {})
        return true
    end

    if DC_Colony and DC_Colony.Network and DC_Colony.Network.HandleCommand then
        DC_Colony.Network.HandleCommand(player, command, args or {})
        return true
    end

    return false
end

function UI.CanOpenBaseZone(snapshot)
    local map = snapshot and snapshot.map or {}
    return math.max(0, math.floor(tonumber(map.headquartersLevel) or 0)) > 0
end

function UI.BuildZoneContext(window)
    local snapshot = window and window.snapshot or {}
    local map = snapshot and snapshot.map or {}
    local unlockedPlots = math.max(0, math.floor(tonumber(map.unlockedPlotCount) or 0))
    local completedBarricades = math.max(0, math.floor(tonumber(map.completedBarricadeCount) or tonumber(map.activeBarricadeCount) or 0))
    local tilesPerBarricade = DC_Colony and DC_Colony.Config and DC_Colony.Config.GetBaseTilesPerBarricade and DC_Colony.Config.GetBaseTilesPerBarricade() or 30
    return {
        colonyId = tostring(snapshot.colonyId or map.colonyId or snapshot.ownerUsername or "local"),
        ownerUsername = tostring(snapshot.ownerUsername or "local"),
        activeBarricadeCount = math.max(0, math.floor(tonumber(map.activeBarricadeCount) or 0)),
        completedBarricadeCount = completedBarricades,
        unlockedPlotCount = unlockedPlots,
        headquartersLevel = math.max(0, math.floor(tonumber(map.headquartersLevel) or 0)),
        allowedBaseTiles = unlockedPlots * math.max(0, math.floor(tonumber(tilesPerBarricade) or 30))
    }
end

function UI.OpenBaseZone(window)
    if not window or not UI.CanOpenBaseZone(window.snapshot) then
        if window and window.getOwnerWindow and window:getOwnerWindow() and window:getOwnerWindow().updateStatus then
            window:getOwnerWindow():updateStatus("Build Headquarters first to unlock Base Zone editing.")
        end
        return
    end

    local player = getLocalPlayer()
    if not player or not DC_ZoneWindow or not DC_ZoneWindow.OpenRealBase then
        return
    end

    local context = UI.BuildZoneContext(window)
    DC_ZoneWindow.OpenRealBase(player, context.colonyId, context)
end

return UI
