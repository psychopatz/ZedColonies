require "DC/Common/Colony/DebugArchive/DC_ColonyDebugArchive"

DC_DebugArchiveClientBridge = DC_DebugArchiveClientBridge or {}

local Bridge = DC_DebugArchiveClientBridge

Bridge.cachedIndexSnapshot = Bridge.cachedIndexSnapshot or nil
Bridge.cachedIndexVersion = Bridge.cachedIndexVersion or nil
Bridge.cachedColonies = Bridge.cachedColonies or {}
Bridge.cachedColonyVersions = Bridge.cachedColonyVersions or {}
Bridge.listeners = Bridge.listeners or {}
Bridge.EventsAdded = Bridge.EventsAdded or false

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

local function notifyListeners(eventName, payload)
    for key, callback in pairs(Bridge.listeners or {}) do
        if key and type(callback) == "function" then
            local ok, err = pcall(callback, eventName, payload or {})
            if not ok then
                if DynamicTrading and DynamicTrading.LogWarn then
                    DynamicTrading.LogWarn("DynamicColonies", "DebugArchive", "Listener", "Debug archive bridge listener failed: " .. tostring(err))
                elseif DynamicTrading and DynamicTrading.Log then
                    DynamicTrading.Log("DynamicColonies", "Warn", "DebugArchive", "Debug archive bridge listener failed: " .. tostring(err))
                end
            end
        end
    end
end

function Bridge.AddListener(key, callback)
    if not key or type(callback) ~= "function" then
        return
    end
    Bridge.listeners[key] = callback
end

function Bridge.RemoveListener(key)
    if key then
        Bridge.listeners[key] = nil
    end
end

function Bridge.SendCommand(command, args)
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

function Bridge.RequestIndex(knownVersion)
    return Bridge.SendCommand("RequestDebugArchiveIndex", {
        knownVersion = knownVersion or Bridge.cachedIndexVersion
    })
end

function Bridge.RequestColony(ownerUsername, knownVersion)
    if not ownerUsername or tostring(ownerUsername) == "" then
        return false
    end

    return Bridge.SendCommand("RequestDebugArchiveColony", {
        ownerUsername = tostring(ownerUsername),
        knownVersion = knownVersion or Bridge.cachedColonyVersions[tostring(ownerUsername)],
    })
end

function Bridge.UpdateIndexSnapshot(snapshot, version, unchanged)
    if unchanged == true then
        notifyListeners("debug_archive_index_unchanged", {
            snapshot = Bridge.cachedIndexSnapshot,
            version = Bridge.cachedIndexVersion,
        })
        return
    end

    Bridge.cachedIndexSnapshot = snapshot or nil
    Bridge.cachedIndexVersion = version or nil
    notifyListeners("debug_archive_index", {
        snapshot = Bridge.cachedIndexSnapshot,
        version = Bridge.cachedIndexVersion,
    })
end

function Bridge.UpdateColonySnapshot(ownerUsername, snapshot, version, unchanged)
    local owner = tostring(ownerUsername or snapshot and snapshot.ownerUsername or "")
    if owner == "" then
        return
    end

    if unchanged == true then
        notifyListeners("debug_archive_colony_unchanged", {
            ownerUsername = owner,
            snapshot = Bridge.cachedColonies[owner],
            version = Bridge.cachedColonyVersions[owner],
        })
        return
    end

    Bridge.cachedColonies[owner] = snapshot or nil
    Bridge.cachedColonyVersions[owner] = version or nil
    notifyListeners("debug_archive_colony", {
        ownerUsername = owner,
        snapshot = Bridge.cachedColonies[owner],
        version = Bridge.cachedColonyVersions[owner],
    })
end

function Bridge.GetCachedIndexSnapshot()
    return Bridge.cachedIndexSnapshot
end

function Bridge.GetCachedIndexVersion()
    return Bridge.cachedIndexVersion
end

function Bridge.GetCachedColonySnapshot(ownerUsername)
    return ownerUsername and Bridge.cachedColonies[tostring(ownerUsername)] or nil
end

function Bridge.GetCachedColonyVersion(ownerUsername)
    return ownerUsername and Bridge.cachedColonyVersions[tostring(ownerUsername)] or nil
end

local function onServerCommand(module, command, args)
    if module ~= getCommandModule() then
        return
    end

    if command == "SyncDebugArchiveIndex" then
        Bridge.UpdateIndexSnapshot(args and args.snapshot or nil, args and args.version or nil, args and args.unchanged == true)
    elseif command == "SyncDebugArchiveColony" then
        Bridge.UpdateColonySnapshot(args and args.ownerUsername or nil, args and args.snapshot or nil, args and args.version or nil, args and args.unchanged == true)
    elseif command == "ColonyNotice" then
        notifyListeners("colony_notice", {
            message = args and args.message or "Colony update received."
        })
    end
end

if not Bridge.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    Bridge.EventsAdded = true
end

return Bridge
