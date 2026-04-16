require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources"

DC_ResourcesClientBridge = DC_ResourcesClientBridge or {}

local Bridge = DC_ResourcesClientBridge

Bridge.cachedSnapshot = Bridge.cachedSnapshot or nil
Bridge.cachedVersion = Bridge.cachedVersion or nil
Bridge.EventsAdded = Bridge.EventsAdded or false
Bridge.listeners = Bridge.listeners or {}

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
        if key and callback then
            local ok, err = pcall(callback, eventName, payload or {})
            if not ok and print then
                print("[DynamicColonies] Resources bridge listener failed: " .. tostring(err))
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

function Bridge.GetCachedSnapshot()
    return Bridge.cachedSnapshot
end

function Bridge.GetCachedVersion()
    return Bridge.cachedVersion
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

function Bridge.RequestSnapshot(knownVersion)
    return Bridge.SendCommand("RequestResourcesSnapshot", {
        knownVersion = knownVersion or Bridge.cachedVersion
    })
end

function Bridge.UpdateSnapshot(snapshot, version, unchanged)
    if unchanged == true then
        notifyListeners("resources_unchanged", {
            snapshot = Bridge.cachedSnapshot,
            version = Bridge.cachedVersion
        })
        return
    end

    Bridge.cachedSnapshot = snapshot or nil
    Bridge.cachedVersion = version or nil
    notifyListeners("resources_snapshot", {
        snapshot = Bridge.cachedSnapshot,
        version = Bridge.cachedVersion
    })
end

local function onServerCommand(module, command, args)
    if module ~= getCommandModule() then
        return
    end

    if command == "SyncResources" then
        Bridge.UpdateSnapshot(args and args.snapshot or nil, args and args.version or nil, args and args.unchanged == true)
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
