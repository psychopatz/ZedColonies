DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network

Network.Handlers = Network.Handlers or {}

Network.Handlers.RequestColonyBootstrap = function(player, args)
    if Network.Internal and Network.Internal.ensureStarterWorkers then
        Network.Internal.ensureStarterWorkers(player)
    end
    if Network.Internal and Network.Internal.syncColonyBootstrap then
        Network.Internal.syncColonyBootstrap(player, args or {})
    end
end

Network.Handlers.RequestPlayerWorkers = function(player, args)
    if Network.Internal and Network.Internal.ensureStarterWorkers then
        Network.Internal.ensureStarterWorkers(player)
    end
    Network.Internal.syncWorkerList(player, args and args.knownVersion)
end

Network.Handlers.RequestWorkerDetails = function(player, args)
    if not args or not args.workerID then return end
    Network.Internal.syncWorkerDetail(
        player,
        args.workerID,
        args.knownVersion,
        args.includeWorkerLedgers == true or type(args.workerLedgerMask) == "table",
        args.includeWarehouseLedgers == true or type(args.warehouseLedgerMask) == "table",
        args.workerLedgerMask,
        args.warehouseLedgerMask
    )
end

Network.Handlers.RequestWarehouse = function(player, args)
    Network.Internal.syncWarehouse(
        player,
        args and args.knownVersion,
        args and (args.includeLedgers == true or type(args.ledgerMask) == "table"),
        args and args.ledgerMask
    )
end

Network.Handlers.RequestWarehouseInventoryFeed = function(player, args)
    if Network.Internal and Network.Internal.syncWarehouseInventoryFeed then
        Network.Internal.syncWarehouseInventoryFeed(
            player,
            args and args.knownVersion,
            args and args.cursor,
            args and args.limit,
            args and args.filterText
        )
    end
end

Network.Handlers.RequestResourcesSnapshot = function(player, args)
    if Network.Internal and Network.Internal.syncResources then
        Network.Internal.syncResources(player, args and args.knownVersion)
    end
end

Network.Handlers.RequestDebugArchiveIndex = function(player, args)
    local debugArchive = DC_Colony and DC_Colony.DebugArchive or nil
    if not (debugArchive and debugArchive.CanUseDebug and debugArchive.CanUseDebug(player)) then
        if Network.Internal and Network.Internal.syncNotice then
            Network.Internal.syncNotice(player, "Debug archive is unavailable for this player.", "error", true)
        end
        return
    end

    if Network.Internal and Network.Internal.syncDebugArchiveIndex then
        Network.Internal.syncDebugArchiveIndex(player, args and args.knownVersion)
    end
end

Network.Handlers.RequestDebugArchiveColony = function(player, args)
    local debugArchive = DC_Colony and DC_Colony.DebugArchive or nil
    if not (debugArchive and debugArchive.CanUseDebug and debugArchive.CanUseDebug(player)) then
        if Network.Internal and Network.Internal.syncNotice then
            Network.Internal.syncNotice(player, "Debug archive is unavailable for this player.", "error", true)
        end
        return
    end

    local ownerUsername = args and args.ownerUsername or nil
    if not ownerUsername or tostring(ownerUsername) == "" then
        return
    end

    if Network.Internal and Network.Internal.syncDebugArchiveColony then
        Network.Internal.syncDebugArchiveColony(player, ownerUsername, args and args.knownVersion)
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
