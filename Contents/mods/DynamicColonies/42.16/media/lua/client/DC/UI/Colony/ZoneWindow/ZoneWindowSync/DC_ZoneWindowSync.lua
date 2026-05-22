require "DC/Common/Zone/DC_ZoneDataStore"
require "DC/UI/Colony/ZoneWindow/ZoneWindowState/DC_ZoneWindowState"

DC_ZoneWindowSync = DC_ZoneWindowSync or {}

local Sync = DC_ZoneWindowSync

Sync.EventsAdded = Sync.EventsAdded or false
Sync.PendingByColony = Sync.PendingByColony or {}

local function getCommandModule()
    local config = DC_Colony and DC_Colony.Config or {}
    return config.COMMAND_MODULE or "DColony"
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

local function sendCommand(command, args)
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

local function getPending(colonyId)
    local pending = Sync.PendingByColony[colonyId]
    if not pending then
        pending = {
            inFlight = false,
            dirty = false
        }
        Sync.PendingByColony[colonyId] = pending
    end
    return pending
end

local function flushPendingSave(colonyId)
    local pending = getPending(colonyId)
    if pending.inFlight then
        return true
    end

    local snapshot = DC_ZoneDataStore.BuildSnapshot(colonyId)
    pending.inFlight = true
    pending.dirty = false
    pending.version = snapshot.version

    if sendCommand("SaveZonesSnapshot", {
        colonyId = colonyId,
        knownVersion = snapshot.version,
        snapshot = snapshot
    }) then
        return true
    end

    pending.inFlight = false
    if colonyId ~= "" then
        DC_ZoneDataStore.SaveSnapshot(colonyId, snapshot.zones, snapshot.version)
        return true
    end

    return false
end

function Sync.RequestSnapshot(window, options)
    local colonyId = tostring(window and window.colonyId or "")
    options = type(options) == "table" and options or {}
    if sendCommand("RequestZonesSnapshot", {
        colonyId = colonyId,
        knownVersion = DC_ZoneDataStore.GetColonyVersion(colonyId),
        refreshWoodcutZoneID = options.refreshWoodcutZoneID and tostring(options.refreshWoodcutZoneID) or nil,
    }) then
        return true
    end

    if window then
        DC_ZoneWindowState.RefreshWindow(window)
    end

    return false
end

function Sync.SaveSnapshot(window)
    local colonyId = tostring(window and window.colonyId or "")
    local pending = getPending(colonyId)
    pending.dirty = true

    if pending.inFlight then
        return true
    end

    return flushPendingSave(colonyId)
end

function Sync.ApplySnapshot(snapshot)
    if type(snapshot) ~= "table" then
        return
    end

    local colonyId = tostring(snapshot.colonyId or "")
    DC_ZoneDataStore.ApplySnapshot(colonyId, snapshot)
    local pending = Sync.PendingByColony[colonyId]
    if pending then
        pending.inFlight = false
        pending.version = snapshot.version
        if not pending.dirty then
            Sync.PendingByColony[colonyId] = nil
        end
    end

    local window = DC_ZoneWindow and DC_ZoneWindow.instance or nil
    if window and tostring(window.colonyId or "") == colonyId then
        DC_ZoneWindowState.RefreshWindow(window)
    elseif window and tostring(window.colonyId or "") == "" and colonyId ~= "" then
        window.colonyId = colonyId
        DC_ZoneWindowState.RefreshWindow(window)
    end
end

local function onServerCommand(module, command, args)
    if module ~= getCommandModule() then
        return
    end

    if command ~= "SyncZonesSnapshot" then
        return
    end

    local snapshot = args and args.snapshot or nil
    local colonyId = tostring((snapshot and snapshot.colonyId) or (args and args.colonyId) or "")
    local window = DC_ZoneWindow and DC_ZoneWindow.instance or nil
    local pendingKey = colonyId
    local pending = Sync.PendingByColony[pendingKey]
    if not pending and window then
        pendingKey = tostring(window.colonyId or "")
        pending = Sync.PendingByColony[pendingKey]
    end

    if pending and pending.dirty then
        if snapshot and snapshot.version then
            DC_ZoneDataStore.SetColonyVersion(colonyId, snapshot.version)
            pending.version = snapshot.version
        end
        pending.inFlight = false
        if pendingKey ~= colonyId then
            Sync.PendingByColony[colonyId] = pending
            Sync.PendingByColony[pendingKey] = nil
        end
        if window and tostring(window.colonyId or "") == "" and colonyId ~= "" then
            window.colonyId = colonyId
        end
        flushPendingSave(colonyId)
        return
    end

    Sync.ApplySnapshot(snapshot)
end

if not Sync.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    Sync.EventsAdded = true
end

return Sync
