DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Internal = DC_Colony.Network.Internal
local Transport = Internal.Transport or {}
local Registry = Transport.Registry or {}
local Buildings = Transport.Buildings or {}

function Internal.forEachOnlineOwnerPlayer(ownerUsername, callback)
    local owner = Transport.getOwnerUsername(ownerUsername)
    if owner == "" then
        return 0
    end

    local handled = 0
    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for index = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(index)
            if player and Transport.getOwnerUsername(player) == owner then
                handled = handled + 1
                callback(player)
            end
        end
    end
    return handled
end

function Internal.syncNotice(player, message, severity, popup)
    Internal.sendTransportPacket(player, "ColonyNotice", Transport.getOwnerUsername(player), {
        message = tostring(message or ""),
        severity = severity or "info",
        popup = popup == true,
    })
end

function Internal.syncFactionStatusSummary(player, ownerUsername)
    local owner = Transport.getOwnerUsername(ownerUsername or player)
    local status = Transport.buildFactionStatusSummary(owner)
    Internal.sendTransportPacket(player, "FactionStatusSummary", owner, {
        version = Transport.getFactionStatusVersion(owner),
        status = status,
    })
end

function Internal.syncWarehouseSummaryUpdated(player, ownerUsername)
    local owner = Transport.getOwnerUsername(ownerUsername or player)
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    Internal.sendTransportPacket(player, "WarehouseSummaryUpdated", owner, {
        version = Transport.getWarehouseSummaryVersion(owner),
        warehouse = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(owner) or nil,
    })
end

function Internal.syncResourcesSummaryUpdated(player, ownerUsername)
    local owner = Transport.getOwnerUsername(ownerUsername or player)
    Internal.sendTransportPacket(player, "ResourcesSummaryUpdated", owner, {
        version = Transport.getResourcesVersion(owner),
        snapshot = Transport.buildResourcesSummary(owner),
    })
end

function Internal.syncWorkerListFocused(player, ownerUsername)
    local owner = Transport.getOwnerUsername(ownerUsername or player)
    Internal.sendTransportPacket(player, "WorkerListUpdated", owner, {
        version = Transport.getWorkerListVersion(owner),
        workers = Registry.GetWorkerSummariesForOwner and Registry.GetWorkerSummariesForOwner(owner) or {},
    })
end

function Internal.syncWorkerUpdated(player, ownerUsername, workerID)
    local owner = Transport.getOwnerUsername(ownerUsername or player)
    local worker = Transport.findWorker(owner, workerID)
    local detail = worker and Transport.getWorkerDetailForPacket(owner, worker.workerID) or nil
    local summary = worker and Transport.buildWorkerSummary(worker) or nil
    Internal.sendTransportPacket(player, "WorkerUpdated", owner, {
        version = Transport.getWorkerDetailVersion(detail or worker),
        listVersion = Transport.getWorkerListVersion(owner),
        workerID = workerID,
        workerSummary = summary,
        worker = detail,
    })
end

function Internal.syncBuildingState(player, ownerUsername, plotX, plotY, options)
    local owner = Transport.getOwnerUsername(ownerUsername or player)
    if Internal.BuildingMap and Internal.BuildingMap.SyncPlotUpdated then
        Internal.BuildingMap.SyncPlotUpdated(player, owner, plotX, plotY, options or {})
        return
    end

    local plot, map = Transport.buildPlotPacket(owner, plotX, plotY, options and options.sourcePlayer or player)
    Internal.sendTransportPacket(player, "BuildingStateUpdated", owner, {
        version = Transport.getBuildingVersion(owner),
        plotKey = plot and plot.key or (Buildings.GetPlotKey and Buildings.GetPlotKey(plotX, plotY) or nil),
        plotX = math.floor(tonumber(plotX) or 0),
        plotY = math.floor(tonumber(plotY) or 0),
        plot = plot,
        map = map,
    })
end

function Internal.syncPlotSafety(player, ownerUsername, changeInfo)
    local owner = Transport.getOwnerUsername(ownerUsername or player)
    local coords = {}

    if type(changeInfo and changeInfo.affectedCoords) == "table" then
        coords = changeInfo.affectedCoords
    elseif changeInfo and changeInfo.plotX ~= nil and changeInfo.plotY ~= nil then
        coords[1] = {
            x = changeInfo.plotX,
            y = changeInfo.plotY,
        }
    end

    if #coords <= 0 and Buildings.GetRingCoordinates and tonumber(changeInfo and changeInfo.securedRingAfter) then
        coords = Buildings.GetRingCoordinates(changeInfo.securedRingAfter)
    end

    if Internal.BuildingMap and Internal.BuildingMap.SyncPlotsUpdated then
        Internal.BuildingMap.SyncPlotsUpdated(player, owner, coords, {
            sourcePlayer = player,
            reason = "plot-safety",
            mapChange = changeInfo and changeInfo.mapChange or nil,
        })
        return
    end

    local plots, map = Transport.buildPlotsPacket(owner, coords, player)
    Internal.sendTransportPacket(player, "PlotSafetyChanged", owner, {
        version = Transport.getBuildingVersion(owner),
        ring = tonumber(changeInfo and changeInfo.securedRingAfter) or tonumber(map and map.securedPerimeterRing) or 0,
        plots = plots,
        map = map,
    })
end

function Internal.syncColonyBootstrap(player, args)
    local owner = Transport.getOwnerUsername(player)
    local knownVersions = type(args and args.knownVersions) == "table" and args.knownVersions or {}
    local forceBuildingsSnapshot = args and args.forceBuildingsSnapshot == true
    local versions = Transport.buildVersions(owner)
    local payload = {
        version = versions.building,
        versions = versions,
    }

    if forceBuildingsSnapshot or tonumber(knownVersions.building) ~= tonumber(versions.building) then
        if Buildings.EnsureInitialHeadquartersProject then
            Buildings.EnsureInitialHeadquartersProject(owner)
        end
        payload.buildingsSnapshot = Buildings.BuildOwnerSnapshot and Buildings.BuildOwnerSnapshot(owner, player) or nil
    end
    if tonumber(knownVersions.workerList) ~= tonumber(versions.workerList) then
        payload.workers = Registry.GetWorkerSummariesForOwner and Registry.GetWorkerSummariesForOwner(owner) or {}
    end
    if tonumber(knownVersions.warehouseSummary) ~= tonumber(versions.warehouseSummary) then
        local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
        payload.warehouse = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(owner) or nil
    end
    if tonumber(knownVersions.resources) ~= tonumber(versions.resources) then
        payload.resourcesSummary = Transport.buildResourcesSummary(owner)
    end
    if tostring(knownVersions.factionStatus or "") ~= tostring(versions.factionStatus) then
        payload.factionStatus = Transport.buildFactionStatusSummary(owner)
    end

    Internal.sendTransportPacket(player, "ColonyBootstrap", owner, payload)
end

return Transport