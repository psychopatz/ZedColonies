require "DC/Common/Buildings/Core/DC_Buildings"

DC_BuildingsWindowSync = DC_BuildingsWindowSync or {}

local Sync = DC_BuildingsWindowSync

local function getExpectedModule()
    return ((DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony")
end

local function ensureSnapshot(windowClass)
    windowClass.cachedSnapshot = type(windowClass.cachedSnapshot) == "table" and windowClass.cachedSnapshot or {}
    local snapshot = windowClass.cachedSnapshot
    snapshot.map = type(snapshot.map) == "table" and snapshot.map or {}
    snapshot.map.plots = type(snapshot.map.plots) == "table" and snapshot.map.plots or {}
    snapshot.map.bounds = type(snapshot.map.bounds) == "table" and snapshot.map.bounds or {
        minX = -1,
        maxX = 1,
        minY = -1,
        maxY = 1,
    }
    snapshot.sync = type(snapshot.sync) == "table" and snapshot.sync or {
        state = "idle",
    }
    windowClass.cachedSnapshot = snapshot
    return snapshot
end

local function refreshVisibleWindow(windowClass)
    if windowClass and windowClass.instance and windowClass.instance:getIsVisible() then
        windowClass.instance:refreshFromSnapshot()
    end
end

local function findPlotIndex(plots, plotKey)
    for index, plot in ipairs(plots or {}) do
        if tostring(plot and plot.key or "") == tostring(plotKey or "") then
            return index
        end
    end
    return nil
end

local function removePlot(windowClass, plotKey)
    local snapshot = ensureSnapshot(windowClass)
    local index = findPlotIndex(snapshot.map.plots, plotKey)
    if index then
        table.remove(snapshot.map.plots, index)
    end
end

local function mergePlots(windowClass, incomingPlots)
    local snapshot = ensureSnapshot(windowClass)
    for _, plot in ipairs(incomingPlots or {}) do
        local key = tostring(plot and plot.key or "")
        if key ~= "" then
            local existingIndex = findPlotIndex(snapshot.map.plots, key)
            if existingIndex then
                snapshot.map.plots[existingIndex] = plot
            else
                snapshot.map.plots[#snapshot.map.plots + 1] = plot
            end
        end
    end
end

local function applyHeader(windowClass, header)
    if type(header) ~= "table" then
        return
    end

    local snapshot = ensureSnapshot(windowClass)
    snapshot.map.headquartersLevel = tonumber(header.hqLevel) or tonumber(snapshot.map.headquartersLevel) or 0
    snapshot.map.securedPerimeterRing = tonumber(header.securedRing) or tonumber(snapshot.map.securedPerimeterRing) or 0
    snapshot.map.currentFrontierRing = tonumber(header.currentRing) or tonumber(snapshot.map.currentFrontierRing) or 1
    snapshot.map.nextFrontierRing = tonumber(header.nextRing) or tonumber(snapshot.map.nextFrontierRing) or 1
    snapshot.map.frontierRequiredHQLevel = tonumber(header.frontierRequiredHQLevel) or tonumber(snapshot.map.frontierRequiredHQLevel) or 1
    snapshot.map.frontierExpansionAvailable = header.frontierExpansionAvailable == true
    snapshot.map.unlockedPlotCount = tonumber(header.unlockedPlotCount) or tonumber(snapshot.map.unlockedPlotCount) or 0
    snapshot.map.activeBarricadeCount = tonumber(header.activeBarricadeCount) or tonumber(snapshot.map.activeBarricadeCount) or 0
    snapshot.map.maxActiveBarricades = tonumber(header.maxActiveBarricadeCount or header.maxActiveBarricades) or tonumber(snapshot.map.maxActiveBarricades) or 0
    if type(header.bounds) == "table" then
        snapshot.map.bounds = {
            minX = math.floor(tonumber(header.bounds.minX) or 0),
            maxX = math.floor(tonumber(header.bounds.maxX) or 0),
            minY = math.floor(tonumber(header.bounds.minY) or 0),
            maxY = math.floor(tonumber(header.bounds.maxY) or 0),
        }
    end
end

local function setSyncState(windowClass, state, extra)
    local snapshot = ensureSnapshot(windowClass)
    local sync = snapshot.sync
    sync.state = tostring(state or sync.state or "idle")
    if extra then
        for key, value in pairs(extra) do
            sync[key] = value
        end
    end
    sync.framesSinceActivity = 0
end

local function buildGapRequestSignature(plotKeys)
    local normalized = {}
    for _, key in ipairs(plotKeys or {}) do
        local plotKey = tostring(key or "")
        if plotKey ~= "" then
            normalized[#normalized + 1] = plotKey
        end
    end
    table.sort(normalized)
    return table.concat(normalized, "|")
end

local function clearGapRequest(sync, resolvedMapRevision)
    if type(sync) ~= "table" then
        return
    end

    local targetRevision = tonumber(sync.pendingGapMapRevision) or 0
    local resolvedRevision = math.max(0, math.floor(tonumber(resolvedMapRevision) or 0))
    if resolvedMapRevision == nil or targetRevision <= 0 or resolvedRevision >= targetRevision then
        sync.pendingGapMapRevision = nil
        sync.pendingGapSignature = nil
    end
end

local function resetChunkTracking(windowClass)
    windowClass.receivedChunkIndexes = {}
end

local function countReceivedChunks(windowClass)
    local count = 0
    for _, received in pairs(windowClass.receivedChunkIndexes or {}) do
        if received == true then
            count = count + 1
        end
    end
    return count
end

local function requestCommand(window, command, payload)
    local ownerWindow = window and window.getOwnerWindow and window:getOwnerWindow() or nil
    if ownerWindow and ownerWindow.sendColonyCommand then
        return ownerWindow:sendColonyCommand(command, payload or {})
    end
    return false
end

function Sync.RequestSnapshot(window, windowClass, forceRetry)
    if isClient() and not isServer() then
        local snapshot = ensureSnapshot(windowClass)
        local sync = snapshot.sync
        clearGapRequest(sync, nil)
        local knownMapRevision = sync.state == "ready" and math.max(0, math.floor(tonumber(sync.mapRevision) or 0)) or 0
        local knownTopologyRevision = sync.state == "ready" and math.max(0, math.floor(tonumber(sync.topologyRevision) or 0)) or 0
        local command = forceRetry == true and "RequestBuildingMapRetry" or "RequestBuildingMapOpen"
        setSyncState(windowClass, #snapshot.map.plots > 0 and "partial" or "loading", {
            message = forceRetry == true and "Retrying building map sync..." or "Requesting building map...",
            knownMapRevision = knownMapRevision,
            knownTopologyRevision = knownTopologyRevision,
        })
        refreshVisibleWindow(windowClass)
        requestCommand(window, command, {
            knownMapRevision = knownMapRevision,
            knownTopologyRevision = knownTopologyRevision,
            requestReason = forceRetry == true and "retry" or "open",
            forceFull = forceRetry == true,
            requestToken = sync.requestToken,
        })
        return
    end

    if DC_Buildings and DC_Buildings.EnsureInitialHeadquartersProject then
        DC_Buildings.EnsureInitialHeadquartersProject(
            (DC_Colony and DC_Colony.Config and DC_Colony.Config.GetPlayerObject and DC_Colony.Config.GetPlayerObject()) or "local"
        )
    end
    if windowClass then
        windowClass.cachedSnapshot = DC_Buildings and DC_Buildings.BuildOwnerSnapshot
            and DC_Buildings.BuildOwnerSnapshot(
                (DC_Colony and DC_Colony.Config and DC_Colony.Config.GetPlayerObject and DC_Colony.Config.GetPlayerObject()) or "local"
            )
            or nil
        if windowClass.cachedSnapshot then
            windowClass.cachedSnapshot.sync = {
                state = "ready",
                mapRevision = 1,
                topologyRevision = 1,
            }
        end
    end
    if window and window.refreshFromSnapshot then
        window:refreshFromSnapshot()
    end
end

function Sync.HandleOpenState(windowClass, args)
    if not windowClass or not args then
        return
    end

    local snapshot = ensureSnapshot(windowClass)
    local sync = snapshot.sync
    local incomingMapRevision = math.max(0, math.floor(tonumber(args.mapRevision) or 0))
    local incomingTopologyRevision = math.max(0, math.floor(tonumber(args.topologyRevision) or 0))
    local chunkCount = math.max(0, math.floor(tonumber(args.chunkCount) or 0))
    local sameRevision = incomingMapRevision == math.max(0, math.floor(tonumber(sync.mapRevision) or 0))
        and incomingTopologyRevision == math.max(0, math.floor(tonumber(sync.topologyRevision) or 0))

    sync.requestToken = args.requestToken or sync.requestToken
    sync.mapRevision = incomingMapRevision
    sync.topologyRevision = incomingTopologyRevision
    sync.chunkCount = chunkCount
    sync.receivedChunks = 0
    sync.message = chunkCount > 0 and "Loading colony plots..." or nil

    if chunkCount > 0 and sameRevision ~= true then
        snapshot.map.plots = {}
    end
    if chunkCount > 0 then
        resetChunkTracking(windowClass)
    end

    applyHeader(windowClass, args.header)
    setSyncState(windowClass, args.loading == true and "loading" or "ready", {
        requestToken = sync.requestToken,
        mapRevision = incomingMapRevision,
        topologyRevision = incomingTopologyRevision,
        chunkCount = chunkCount,
        receivedChunks = 0,
        message = chunkCount > 0 and "Loading colony plots..." or nil,
    })
    refreshVisibleWindow(windowClass)
end

function Sync.HandleMapStatus(windowClass, args)
    if not windowClass or not args then
        return
    end

    local snapshot = ensureSnapshot(windowClass)
    local sync = snapshot.sync
    sync.requestToken = args.requestToken or sync.requestToken
    sync.mapRevision = math.max(0, math.floor(tonumber(args.mapRevision) or sync.mapRevision or 0))
    sync.topologyRevision = math.max(0, math.floor(tonumber(args.topologyRevision) or sync.topologyRevision or 0))

    setSyncState(windowClass, args.state or sync.state, {
        requestToken = sync.requestToken,
        mapRevision = sync.mapRevision,
        topologyRevision = sync.topologyRevision,
        message = args.message or sync.message,
        retryHint = args.retryHint == true,
        chunkCount = sync.chunkCount,
        receivedChunks = sync.receivedChunks,
    })
    refreshVisibleWindow(windowClass)
end

function Sync.HandleMapChunk(windowClass, args)
    if not windowClass or not args then
        return
    end

    local snapshot = ensureSnapshot(windowClass)
    local sync = snapshot.sync
    if sync.requestToken and args.requestToken and tostring(sync.requestToken) ~= tostring(args.requestToken) then
        return
    end

    applyHeader(windowClass, args.header)
    mergePlots(windowClass, args.plots or {})
    windowClass.receivedChunkIndexes = windowClass.receivedChunkIndexes or {}
    windowClass.receivedChunkIndexes[math.max(1, math.floor(tonumber(args.chunkIndex) or 1))] = true

    setSyncState(windowClass, "partial", {
        requestToken = args.requestToken or sync.requestToken,
        mapRevision = math.max(0, math.floor(tonumber(args.mapRevision) or sync.mapRevision or 0)),
        topologyRevision = math.max(0, math.floor(tonumber(args.topologyRevision) or sync.topologyRevision or 0)),
        chunkCount = math.max(0, math.floor(tonumber(args.chunkCount) or sync.chunkCount or 0)),
        receivedChunks = countReceivedChunks(windowClass),
        message = "Loading colony plots...",
    })
    refreshVisibleWindow(windowClass)
end

function Sync.HandleMapReady(windowClass, args)
    if not windowClass or not args then
        return
    end

    applyHeader(windowClass, args.header)
    setSyncState(windowClass, "ready", {
        requestToken = args.requestToken,
        mapRevision = math.max(0, math.floor(tonumber(args.mapRevision) or 0)),
        topologyRevision = math.max(0, math.floor(tonumber(args.topologyRevision) or 0)),
        chunkCount = math.max(0, math.floor(tonumber(args.chunkCount) or 0)),
        receivedChunks = countReceivedChunks(windowClass),
        plotCount = math.max(0, math.floor(tonumber(args.plotCount) or 0)),
        message = nil,
        retryHint = false,
    })
    clearGapRequest(ensureSnapshot(windowClass).sync, args.mapRevision)
    refreshVisibleWindow(windowClass)
end

local function handleRevisionGap(windowClass, args, plotKeys)
    if not windowClass or not args or not plotKeys or #plotKeys <= 0 then
        return
    end

    local snapshot = ensureSnapshot(windowClass)
    local sync = snapshot.sync
    local incomingMapRevision = math.max(0, math.floor(tonumber(args.mapRevision) or 0))
    local currentMapRevision = math.max(0, math.floor(tonumber(sync.mapRevision) or 0))
    local gapSignature = buildGapRequestSignature(plotKeys)

    if currentMapRevision > 0 and incomingMapRevision > (currentMapRevision + 1) and windowClass.instance and windowClass.instance.getOwnerWindow then
        if tonumber(sync.pendingGapMapRevision) == incomingMapRevision and tostring(sync.pendingGapSignature or "") == gapSignature then
            return
        end

        sync.pendingGapMapRevision = incomingMapRevision
        sync.pendingGapSignature = gapSignature

        local ownerWindow = windowClass.instance:getOwnerWindow()
        if ownerWindow and ownerWindow.sendColonyCommand then
            ownerWindow:sendColonyCommand("RequestBuildingPlots", {
                plotKeys = plotKeys,
                requestReason = "revision-gap",
            })
        end
    end
end

function Sync.HandlePlotUpdated(windowClass, args)
    if not windowClass or not args then
        return
    end

    handleRevisionGap(windowClass, args, { tostring(args.plotKey or (args.plot and args.plot.key) or "") })
    applyHeader(windowClass, args.header)

    if args.plot then
        mergePlots(windowClass, { args.plot })
    elseif args.plotKey then
        removePlot(windowClass, args.plotKey)
    end

    setSyncState(windowClass, "ready", {
        mapRevision = math.max(0, math.floor(tonumber(args.mapRevision) or 0)),
        topologyRevision = math.max(0, math.floor(tonumber(args.topologyRevision) or 0)),
        message = nil,
    })
    clearGapRequest(ensureSnapshot(windowClass).sync, args.mapRevision)
    refreshVisibleWindow(windowClass)
end

function Sync.HandlePlotsUpdated(windowClass, args)
    if not windowClass or not args then
        return
    end

    local plotKeys = {}
    for _, plot in ipairs(args.plots or {}) do
        plotKeys[#plotKeys + 1] = tostring(plot and plot.key or "")
    end
    handleRevisionGap(windowClass, args, plotKeys)
    applyHeader(windowClass, args.header)
    mergePlots(windowClass, args.plots or {})
    setSyncState(windowClass, "ready", {
        mapRevision = math.max(0, math.floor(tonumber(args.mapRevision) or 0)),
        topologyRevision = math.max(0, math.floor(tonumber(args.topologyRevision) or 0)),
        message = nil,
    })
    clearGapRequest(ensureSnapshot(windowClass).sync, args.mapRevision)
    refreshVisibleWindow(windowClass)
end

function Sync.HandleSnapshotResponse(windowClass, args)
    if args and args.unchanged == true then
        return
    end

    if windowClass then
        windowClass.cachedVersion = args and args.version or nil
        windowClass.cachedSnapshot = args and args.snapshot or nil
        if windowClass.cachedSnapshot then
            windowClass.cachedSnapshot.sync = {
                state = "ready",
                mapRevision = tonumber(windowClass.cachedVersion) or 1,
                topologyRevision = tonumber(windowClass.cachedVersion) or 1,
            }
            clearGapRequest(windowClass.cachedSnapshot.sync, windowClass.cachedVersion)
        end
        refreshVisibleWindow(windowClass)
    end
end

function Sync.InstallEvents(windowClass)
    if not windowClass or windowClass.EventsAdded then
        return
    end

    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= getExpectedModule() then
            return
        end
        if command == "BuildingMapOpenState" then
            Sync.HandleOpenState(windowClass, args)
            return
        end
        if command == "BuildingMapStatus" then
            Sync.HandleMapStatus(windowClass, args)
            return
        end
        if command == "BuildingMapChunk" then
            Sync.HandleMapChunk(windowClass, args)
            return
        end
        if command == "BuildingMapReady" then
            Sync.HandleMapReady(windowClass, args)
            return
        end
        if command == "BuildingPlotUpdated" then
            Sync.HandlePlotUpdated(windowClass, args)
            return
        end
        if command == "BuildingPlotsUpdated" then
            Sync.HandlePlotsUpdated(windowClass, args)
            return
        end
        if command == "SyncBuildingsSnapshot" then
            Sync.HandleSnapshotResponse(windowClass, args)
        end
    end)

    windowClass.EventsAdded = true
end

return Sync
