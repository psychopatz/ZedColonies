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

Network.Handlers.RequestResourcesSnapshot = function(player, args)
    if Network.Internal and Network.Internal.syncResources then
        Network.Internal.syncResources(player, args and args.knownVersion)
    end
end

Network.Handlers.SetGreenhouseThermostat = function(player, args)
    if not args or not args.buildingID then
        return
    end

    local resourcesApi = DC_Colony and DC_Colony.Resources or nil
    local ok, reason = false, "Resources unavailable."
    if resourcesApi and resourcesApi.SetGreenhouseThermostat then
        ok, reason = resourcesApi.SetGreenhouseThermostat(
            player,
            args.buildingID,
            tonumber(args.thermostatC) or 20
        )
    end

    if not ok and Network.Internal and Network.Internal.syncNotice then
        Network.Internal.syncNotice(player, reason or "Unable to update greenhouse thermostat.", "error", true)
    elseif ok and Network.Internal and Network.Internal.syncNotice then
        Network.Internal.syncNotice(player, "Greenhouse thermostat updated.", "info", false)
    end

    if Network.Internal and Network.Internal.syncResources then
        Network.Internal.syncResources(player)
    end
end

Network.Handlers.PlantGreenhouseSlot = function(player, args)
    if not args or not args.buildingID or not args.slotIndex or not args.seedFullType then
        return
    end

    local resourcesApi = DC_Colony and DC_Colony.Resources or nil
    local ok, reason = false, "Resources unavailable."
    if resourcesApi and resourcesApi.PlantGreenhouseSlot then
        ok, reason = resourcesApi.PlantGreenhouseSlot(
            player,
            args.buildingID,
            math.floor(tonumber(args.slotIndex) or 0),
            args.seedFullType
        )
    end

    if not ok and Network.Internal and Network.Internal.syncNotice then
        Network.Internal.syncNotice(player, reason or "Unable to plant that greenhouse slot.", "error", true)
    elseif ok and Network.Internal and Network.Internal.syncNotice then
        Network.Internal.syncNotice(player, "Greenhouse slot planted.", "info", false)
    end

    if Network.Internal and Network.Internal.syncResources then
        Network.Internal.syncResources(player)
    end
end

Network.Handlers.ClearGreenhouseSlot = function(player, args)
    if not args or not args.buildingID or not args.slotIndex then
        return
    end

    local resourcesApi = DC_Colony and DC_Colony.Resources or nil
    local ok, reason = false, "Resources unavailable."
    if resourcesApi and resourcesApi.ClearGreenhouseSlot then
        ok, reason = resourcesApi.ClearGreenhouseSlot(
            player,
            args.buildingID,
            math.floor(tonumber(args.slotIndex) or 0)
        )
    end

    if not ok and Network.Internal and Network.Internal.syncNotice then
        Network.Internal.syncNotice(player, reason or "Unable to clear that greenhouse slot.", "error", true)
    elseif ok and Network.Internal and Network.Internal.syncNotice then
        Network.Internal.syncNotice(player, "Greenhouse slot cleared.", "info", false)
    end

    if Network.Internal and Network.Internal.syncResources then
        Network.Internal.syncResources(player)
    end
end

return Network
