DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local NetworkInternal = DC_Colony.Network.Internal
local ColonyConfig = DC_Colony.Config or {}

NetworkInternal.BuildingMap = NetworkInternal.BuildingMap or {}

local MapTransport = NetworkInternal.BuildingMap
local modules = MapTransport.Modules or {}
local helpers = MapTransport.Helpers or {}

MapTransport.Modules = modules
MapTransport.Helpers = helpers

if modules.Sync then
    return
end

modules.Sync = true

function helpers.SendMapPacket(player, command, payload)
    local safeArgs = nil
    local stats = nil
    if NetworkInternal.sanitizeNetworkArgs then
        safeArgs, stats = NetworkInternal.sanitizeNetworkArgs(payload)
    else
        safeArgs = payload or {}
        stats = {
            dropped = 0,
            paths = {},
        }
    end
    local estimatedSize = helpers.EstimatePayloadSize(safeArgs)
    local ownerUsername = safeArgs and safeArgs.ownerUsername or payload and payload.ownerUsername or "unknown"
    local requestToken = safeArgs and safeArgs.requestToken or payload and payload.requestToken or "n/a"
    local debugEnabled = helpers.IsDebugTransportEnabled(player)

    if debugEnabled then
        helpers.LogMap(
            "Info",
            "send command=" .. tostring(command)
                .. " owner=" .. tostring(ownerUsername)
                .. " request=" .. tostring(requestToken)
                .. " revision=" .. tostring(safeArgs and safeArgs.mapRevision or "n/a")
                .. " chunk=" .. tostring(safeArgs and safeArgs.chunkIndex or "n/a")
                .. "/" .. tostring(safeArgs and safeArgs.chunkCount or "n/a")
                .. " size=" .. tostring(estimatedSize)
                .. " dropped=" .. tostring(stats and stats.dropped or 0)
        )
    end

    if isServer() then
        sendServerCommand(player, ColonyConfig.COMMAND_MODULE or "DColony", command, safeArgs)
    else
        triggerEvent("OnServerCommand", ColonyConfig.COMMAND_MODULE or "DColony", command, safeArgs)
    end
end

function MapTransport.SyncOpen(player, ownerUsername, args)
    local owner = helpers.GetOwnerUsername(ownerUsername or player)
    local knownMapRevision = math.max(0, math.floor(tonumber(args and args.knownMapRevision) or 0))
    local knownTopologyRevision = math.max(0, math.floor(tonumber(args and args.knownTopologyRevision) or 0))
    local requestToken = tostring(args and args.requestToken or helpers.NextRequestToken(owner))

    local header, plots = helpers.BuildVisiblePlots(owner, player)
    local revisions = helpers.GetRevisions(owner)
    local chunks = {}

    if knownMapRevision ~= revisions.mapRevision or knownTopologyRevision ~= revisions.topologyRevision or args and args.forceFull == true then
        chunks = helpers.SplitPlotsIntoChunks(plots)
    end

    helpers.SendMapPacket(player, "BuildingMapOpenState", {
        ownerUsername = owner,
        domain = "Building",
        requestToken = requestToken,
        mapRevision = revisions.mapRevision,
        topologyRevision = revisions.topologyRevision,
        loading = #chunks > 0,
        chunkCount = #chunks,
        header = header,
        knownMapRevision = knownMapRevision,
        knownTopologyRevision = knownTopologyRevision,
    })

    if #chunks <= 0 then
        helpers.SendMapPacket(player, "BuildingMapStatus", {
            ownerUsername = owner,
            domain = "Building",
            requestToken = requestToken,
            mapRevision = revisions.mapRevision,
            topologyRevision = revisions.topologyRevision,
            state = "ready",
            message = "cache-valid",
            retryHint = false,
        })
    else
        helpers.SendMapPacket(player, "BuildingMapStatus", {
            ownerUsername = owner,
            domain = "Building",
            requestToken = requestToken,
            mapRevision = revisions.mapRevision,
            topologyRevision = revisions.topologyRevision,
            state = "loading",
            message = "chunked-bootstrap",
            retryHint = false,
        })
    end

    for index, chunk in ipairs(chunks) do
        helpers.SendMapPacket(player, "BuildingMapChunk", {
            ownerUsername = owner,
            domain = "Building",
            requestToken = requestToken,
            mapRevision = revisions.mapRevision,
            topologyRevision = revisions.topologyRevision,
            chunkIndex = index,
            chunkCount = #chunks,
            plots = chunk,
        })
    end

    helpers.SendMapPacket(player, "BuildingMapReady", {
        ownerUsername = owner,
        domain = "Building",
        requestToken = requestToken,
        mapRevision = revisions.mapRevision,
        topologyRevision = revisions.topologyRevision,
        header = header,
        chunkCount = #chunks,
        plotCount = #plots,
    })
end

function MapTransport.SyncPlots(player, ownerUsername, args)
    local owner = helpers.GetOwnerUsername(ownerUsername or player)
    local requested = type(args and args.plotKeys) == "table" and args.plotKeys or {}
    local header, plots = helpers.BuildVisiblePlots(owner, player)
    local revisions = helpers.GetRevisions(owner)
    local indexByKey = {}
    local selected = {}

    for _, plot in ipairs(plots) do
        indexByKey[tostring(plot.key or "")] = plot
    end

    for _, key in ipairs(requested) do
        local plot = indexByKey[tostring(key or "")]
        if plot then
            selected[#selected + 1] = plot
        end
    end

    helpers.SendMapPacket(player, "BuildingPlotsUpdated", {
        ownerUsername = owner,
        domain = "Building",
        mapRevision = revisions.mapRevision,
        topologyRevision = revisions.topologyRevision,
        header = header,
        plots = selected,
        reason = tostring(args and args.requestReason or "targeted-fetch"),
    })
end

function MapTransport.SyncPlotUpdated(player, ownerUsername, plotX, plotY, options)
    local owner = helpers.GetOwnerUsername(ownerUsername or player)
    local header, plots = helpers.BuildVisiblePlots(owner, options and options.sourcePlayer or player)
    local revisions = options and options.mapChange or helpers.GetRevisions(owner)
    local targetKey = helpers.GetPlotKey(plotX, plotY)
    local found = nil

    for _, plot in ipairs(plots) do
        if tostring(plot.key or "") == targetKey then
            found = plot
            break
        end
    end

    helpers.SendMapPacket(player, "BuildingPlotUpdated", {
        ownerUsername = owner,
        domain = "Building",
        mapRevision = revisions.mapRevision,
        topologyRevision = revisions.topologyRevision,
        plotKey = targetKey,
        plot = found,
        header = header,
    })
end

function MapTransport.SyncPlotsUpdated(player, ownerUsername, coords, options)
    local owner = helpers.GetOwnerUsername(ownerUsername or player)
    local header, plots = helpers.BuildVisiblePlots(owner, options and options.sourcePlayer or player)
    local revisions = options and options.mapChange or helpers.GetRevisions(owner)
    local coordsByKey = {}
    local selected = {}

    for _, coord in ipairs(coords or {}) do
        coordsByKey[helpers.GetPlotKey(coord and coord.x, coord and coord.y)] = true
    end

    for _, plot in ipairs(plots) do
        if coordsByKey[tostring(plot.key or "")] then
            selected[#selected + 1] = plot
        end
    end

    helpers.SendMapPacket(player, "BuildingPlotsUpdated", {
        ownerUsername = owner,
        domain = "Building",
        mapRevision = revisions.mapRevision,
        topologyRevision = revisions.topologyRevision,
        header = header,
        plots = selected,
        reason = tostring(options and options.reason or "multi-plot-update"),
    })
end
