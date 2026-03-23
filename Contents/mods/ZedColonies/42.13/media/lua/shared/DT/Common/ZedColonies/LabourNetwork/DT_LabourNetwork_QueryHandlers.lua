DT_Labour = DT_Labour or {}
DT_Labour.Network = DT_Labour.Network or {}

local Network = DT_Labour.Network

Network.Handlers = Network.Handlers or {}

Network.Handlers.RequestPlayerWorkers = function(player, args)
    Network.Internal.syncWorkerList(player)
end

Network.Handlers.RequestWorkerDetails = function(player, args)
    if not args or not args.workerID then return end
    Network.Internal.syncWorkerDetail(player, args.workerID, args.includeWarehouseLedgers == true)
end

return Network
