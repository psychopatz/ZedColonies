DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network

Network.Handlers = Network.Handlers or {}

Network.Handlers.RequestZonesSnapshot = function(player, args)
    if Network.Internal and Network.Internal.syncZonesSnapshot then
        Network.Internal.syncZonesSnapshot(player, args and args.colonyId, args and args.knownVersion)
    end
end

Network.Handlers.SaveZonesSnapshot = function(player, args)
    if not args then
        return
    end

    local snapshot = type(args.snapshot) == "table" and args.snapshot or nil
    local zones = snapshot and snapshot.zones or args.zones
    if type(zones) ~= "table" then
        return
    end

    local knownVersion = snapshot and snapshot.version or args.knownVersion
    if Network.Internal and Network.Internal.saveZonesSnapshot then
        Network.Internal.saveZonesSnapshot(player, args.colonyId or (snapshot and snapshot.colonyId) or nil, zones, knownVersion)
    end
end

Network.Handlers.RequestZoneSnapshot = Network.Handlers.RequestZonesSnapshot
Network.Handlers.SaveZoneSnapshot = Network.Handlers.SaveZonesSnapshot

return Network