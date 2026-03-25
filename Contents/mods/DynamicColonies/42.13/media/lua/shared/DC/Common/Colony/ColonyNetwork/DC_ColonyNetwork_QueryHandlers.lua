DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network

Network.Handlers = Network.Handlers or {}

Network.Handlers.RequestPlayerWorkers = function(player, args)
    Network.Internal.syncWorkerList(player, args and args.knownVersion)
end

Network.Handlers.RequestWorkerDetails = function(player, args)
    if not args or not args.workerID then return end
    Network.Internal.syncWorkerDetail(
        player,
        args.workerID,
        args.knownVersion,
        args.includeWorkerLedgers == true
    )
end

Network.Handlers.RequestWarehouse = function(player, args)
    Network.Internal.syncWarehouse(
        player,
        args and args.knownVersion,
        args and args.includeLedgers == true
    )
end

return Network
