require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local ColonyConfig = DC_Colony.Config or {}
local Network = DC_Colony.Network
local Buildings = DC_Buildings
local Internal = Network.Internal

Network.Handlers = Network.Handlers or {}
Internal.BuildingMap = Internal.BuildingMap or {}

local MapTransport = Internal.BuildingMap

MapTransport.CHUNK_PLOT_COUNT = MapTransport.CHUNK_PLOT_COUNT or 10
MapTransport.MAX_CHUNK_SIZE = MapTransport.MAX_CHUNK_SIZE or 16000

local function logMap(level, message)
    if DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DynamicColonies", "BuildingMap", level or "Info", tostring(message or ""))
    elseif print then
        print("[DynamicColonies][BuildingMap][" .. tostring(level or "Info") .. "] " .. tostring(message or ""))
    end
end

local function isDebugTransportEnabled(player)
    if DynamicTrading and DynamicTrading.Debug then
        return true
    end
    if isDebugEnabled and isDebugEnabled() then
        return true
    end
    if player and player.getAccessLevel then
        local accessLevel = tostring(player:getAccessLevel() or "")
        if accessLevel ~= "" and accessLevel ~= "None" then
            return true
        end
    end
    return false
end

local function estimatePayloadSize(value, seen)
    local valueType = type(value)
    if valueType == "nil" then
        return 0
    end
    if valueType == "string" then
        return #value
    end
    if valueType == "number" or valueType == "boolean" then
        return #tostring(value)
    end
    if valueType ~= "table" then
        return #tostring(value)
    end

    seen = seen or {}
    if seen[value] then
        return 0
    end
    seen[value] = true

    local total = 2
    for key, child in pairs(value) do
        total = total + #tostring(key) + estimatePayloadSize(child, seen)
    end

    seen[value] = nil
    return total
end

local function shallowCopy(source)
    if type(source) ~= "table" then
        return source
    end
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

local function copyArray(source)
    local copy = {}
    for _, value in ipairs(source or {}) do
        if type(value) == "table" then
            copy[#copy + 1] = shallowCopy(value)
        else
            copy[#copy + 1] = value
        end
    end
    return copy
end

local function getOwnerUsername(subject)
    if ColonyConfig.GetOwnerUsername then
        return ColonyConfig.GetOwnerUsername(subject)
    end
    if type(subject) == "table" and subject.getUsername then
        return tostring(subject:getUsername() or "local")
    end
    return tostring(subject or "local")
end

local function getPlotKey(plotX, plotY)
    if Buildings.GetPlotKey then
        return Buildings.GetPlotKey(plotX, plotY)
    end
    return tostring(math.floor(tonumber(plotX) or 0)) .. ":" .. tostring(math.floor(tonumber(plotY) or 0))
end

local function normalizeCoord(plotX, plotY)
    return {
        x = math.floor(tonumber(plotX) or 0),
        y = math.floor(tonumber(plotY) or 0),
    }
end

local function ensureRevisionState(ownerUsername)
    local ownerData = Buildings.EnsureOwner and Buildings.EnsureOwner(ownerUsername) or nil
    if not ownerData then
        return {
            buildingMapRevision = 1,
            buildingTopologyRevision = 1,
            plotRevisions = {},
            projectRevisions = {},
            nextRequestToken = 0,
        }
    end

    ownerData.networkTransport = type(ownerData.networkTransport) == "table" and ownerData.networkTransport or {}
    ownerData.networkTransport.buildingMap = type(ownerData.networkTransport.buildingMap) == "table"
        and ownerData.networkTransport.buildingMap
        or {}

    local state = ownerData.networkTransport.buildingMap
    state.buildingMapRevision = math.max(1, math.floor(tonumber(state.buildingMapRevision) or 1))
    state.buildingTopologyRevision = math.max(1, math.floor(tonumber(state.buildingTopologyRevision) or 1))
    state.plotRevisions = type(state.plotRevisions) == "table" and state.plotRevisions or {}
    state.projectRevisions = type(state.projectRevisions) == "table" and state.projectRevisions or {}
    state.nextRequestToken = math.max(0, math.floor(tonumber(state.nextRequestToken) or 0))
    return state
end

local function getPlotRevision(ownerUsername, plotKey)
    local state = ensureRevisionState(ownerUsername)
    return math.max(1, math.floor(tonumber(state.plotRevisions and state.plotRevisions[plotKey]) or 1))
end

local function getRevisions(ownerUsername)
    local state = ensureRevisionState(ownerUsername)
    return {
        mapRevision = math.max(1, math.floor(tonumber(state.buildingMapRevision) or 1)),
        topologyRevision = math.max(1, math.floor(tonumber(state.buildingTopologyRevision) or 1)),
    }
end

local function nextRequestToken(ownerUsername)
    local state = ensureRevisionState(ownerUsername)
    state.nextRequestToken = math.max(0, math.floor(tonumber(state.nextRequestToken) or 0)) + 1
    return tostring(ownerUsername) .. ":" .. tostring(state.nextRequestToken)
end

local function appendUniqueCoord(target, seen, plotX, plotY)
    if plotX == nil or plotY == nil then
        return
    end
    local coord = normalizeCoord(plotX, plotY)
    local key = getPlotKey(coord.x, coord.y)
    if seen[key] then
        return
    end
    seen[key] = true
    target[#target + 1] = coord
end

local function collectAffectedCoords(ownerUsername, context)
    local coords = {}
    local seen = {}

    appendUniqueCoord(coords, seen, context and context.plotX, context and context.plotY)

    for _, coord in ipairs(context and context.additionalPlots or {}) do
        appendUniqueCoord(coords, seen, coord and coord.x, coord and coord.y)
    end

    local transition = context and context.transition or nil
    for _, coord in ipairs(transition and transition.affectedCoords or {}) do
        appendUniqueCoord(coords, seen, coord and coord.x, coord and coord.y)
    end

    if #coords <= 0 and transition and tonumber(transition.securedRingAfter) and Buildings.GetRingCoordinates then
        for _, coord in ipairs(Buildings.GetRingCoordinates(transition.securedRingAfter) or {}) do
            appendUniqueCoord(coords, seen, coord and coord.x, coord and coord.y)
        end
    end

    if #coords <= 0 and ownerUsername and Buildings.GetUnlockedPlotEntries then
        for _, plot in ipairs(Buildings.GetUnlockedPlotEntries(ownerUsername) or {}) do
            appendUniqueCoord(coords, seen, plot and plot.x, plot and plot.y)
        end
    end

    return coords
end

local function buildHeader(ownerUsername, snapshot)
    local territory = snapshot or {}
    local bounds = type(territory.bounds) == "table" and territory.bounds or {
        minX = 0,
        maxX = 0,
        minY = 0,
        maxY = 0,
    }
    return {
        ownerUsername = ownerUsername,
        hqLevel = tonumber(territory.headquartersLevel) or 0,
        securedRing = tonumber(territory.securedPerimeterRing) or 0,
        currentRing = tonumber(territory.currentFrontierRing) or 1,
        nextRing = tonumber(territory.nextFrontierRing) or tonumber(territory.currentFrontierRing) or 1,
        frontierRequiredHQLevel = tonumber(territory.frontierRequiredHQLevel) or 1,
        frontierExpansionAvailable = territory.frontierExpansionAvailable == true,
        unlockedPlotCount = tonumber(territory.unlockedPlotCount) or 0,
        activeBarricadeCount = tonumber(territory.activeBarricadeCount) or 0,
        maxActiveBarricades = tonumber(territory.maxActiveBarricades) or 0,
        bounds = {
            minX = math.floor(tonumber(bounds.minX) or 0),
            maxX = math.floor(tonumber(bounds.maxX) or 0),
            minY = math.floor(tonumber(bounds.minY) or 0),
            maxY = math.floor(tonumber(bounds.maxY) or 0),
        },
        visiblePlotCount = #(snapshot and snapshot.plots or {}),
    }
end

local function trimPlotPayload(ownerUsername, header, plot)
    if type(plot) ~= "table" then
        return nil
    end

    local building = type(plot.building) == "table" and shallowCopy(plot.building) or nil
    local project = type(plot.project) == "table" and shallowCopy(plot.project) or nil
    local availableActions = type(plot.availableActions) == "table" and shallowCopy(plot.availableActions) or {}

    return {
        key = tostring(plot.key or getPlotKey(plot.x, plot.y)),
        x = math.floor(tonumber(plot.x) or 0),
        y = math.floor(tonumber(plot.y) or 0),
        ring = math.floor(tonumber(plot.ring) or 0),
        kind = plot.kind,
        state = plot.state,
        unlocked = plot.unlocked == true,
        safeTile = plot.safeTile == true,
        frontierCandidate = plot.frontierCandidate == true,
        revision = getPlotRevision(ownerUsername, tostring(plot.key or getPlotKey(plot.x, plot.y))),
        availableActions = availableActions,
        buildOptions = copyArray(plot.buildOptions),
        building = building,
        project = project,
        territory = {
            headquartersLevel = header.hqLevel,
            securedPerimeterRing = header.securedRing,
            currentFrontierRing = header.currentRing,
            nextFrontierRing = header.nextRing,
            frontierExpansionAvailable = header.frontierExpansionAvailable,
            frontierRequiredHQLevel = header.frontierRequiredHQLevel,
            unlockedPlotCount = header.unlockedPlotCount,
            activeBarricadeCount = header.activeBarricadeCount,
            maxActiveBarricades = header.maxActiveBarricades,
        },
    }
end

local function sortPlots(plots)
    table.sort(plots, function(a, b)
        if tonumber(a.y) == tonumber(b.y) then
            return tonumber(a.x) < tonumber(b.x)
        end
        return tonumber(a.y) < tonumber(b.y)
    end)
end

local function buildVisiblePlots(ownerUsername, sourcePlayer)
    if Buildings.EnsureInitialHeadquartersProject then
        Buildings.EnsureInitialHeadquartersProject(ownerUsername)
    end
    if Buildings.GetUnlockedPlotEntries then
        Buildings.GetUnlockedPlotEntries(ownerUsername)
    end
    if Buildings.GetFrontierCandidatePlots then
        Buildings.GetFrontierCandidatePlots(ownerUsername)
    end

    local snapshot = Buildings.BuildMapSnapshot and Buildings.BuildMapSnapshot(ownerUsername, sourcePlayer) or {
        bounds = {
            minX = 0,
            maxX = 0,
            minY = 0,
            maxY = 0,
        },
        plots = {},
    }
    local header = buildHeader(ownerUsername, snapshot)
    local plots = {}

    for _, plot in ipairs(snapshot.plots or {}) do
        local trimmed = trimPlotPayload(ownerUsername, header, plot)
        if trimmed then
            plots[#plots + 1] = trimmed
        end
    end

    sortPlots(plots)
    return header, plots
end

local function prioritizeCorePlot(plots)
    local coreIndex = nil
    for index, plot in ipairs(plots) do
        if tostring(plot and plot.key or "") == "0:0" then
            coreIndex = index
            break
        end
    end

    if not coreIndex or coreIndex == 1 then
        return plots
    end

    local prioritized = { plots[coreIndex] }
    for index, plot in ipairs(plots) do
        if index ~= coreIndex then
            prioritized[#prioritized + 1] = plot
        end
    end
    return prioritized
end

local function splitPlotsIntoChunks(plots)
    local ordered = prioritizeCorePlot(plots or {})
    local chunks = {}
    local current = {}
    local currentSize = 0

    for _, plot in ipairs(ordered) do
        local plotSize = estimatePayloadSize(plot)
        if #current > 0 and (#current >= MapTransport.CHUNK_PLOT_COUNT or (currentSize + plotSize) > MapTransport.MAX_CHUNK_SIZE) then
            chunks[#chunks + 1] = current
            current = {}
            currentSize = 0
        end

        current[#current + 1] = plot
        currentSize = currentSize + plotSize
    end

    if #current > 0 or #chunks <= 0 then
        chunks[#chunks + 1] = current
    end

    return chunks
end

function MapTransport.Touch(ownerUsername, context)
    local owner = getOwnerUsername(ownerUsername)
    local state = ensureRevisionState(owner)
    local coords = collectAffectedCoords(owner, context or {})
    local topologyChanged = context and (context.topologyChanged == true or (context.transition and context.transition.safetyChanged == true)) or false

    state.buildingMapRevision = math.max(1, math.floor(tonumber(state.buildingMapRevision) or 1)) + 1
    if topologyChanged then
        state.buildingTopologyRevision = math.max(1, math.floor(tonumber(state.buildingTopologyRevision) or 1)) + 1
    end

    local plotRevisions = {}
    for _, coord in ipairs(coords) do
        local key = getPlotKey(coord.x, coord.y)
        state.plotRevisions[key] = math.max(1, math.floor(tonumber(state.plotRevisions[key]) or 1)) + 1
        plotRevisions[key] = state.plotRevisions[key]
    end

    if context and context.projectID then
        state.projectRevisions[context.projectID] = math.max(1, math.floor(tonumber(state.projectRevisions[context.projectID]) or 1)) + 1
    end

    return {
        mapRevision = state.buildingMapRevision,
        topologyRevision = state.buildingTopologyRevision,
        plotRevisions = plotRevisions,
        coords = coords,
    }
end

local function sendMapPacket(player, command, payload)
    local safeArgs = nil
    local stats = nil
    if Internal.sanitizeNetworkArgs then
        safeArgs, stats = Internal.sanitizeNetworkArgs(payload)
    else
        safeArgs = payload or {}
        stats = {
            dropped = 0,
            paths = {},
        }
    end
    local estimatedSize = estimatePayloadSize(safeArgs)
    local ownerUsername = safeArgs and safeArgs.ownerUsername or payload and payload.ownerUsername or "unknown"
    local requestToken = safeArgs and safeArgs.requestToken or payload and payload.requestToken or "n/a"
    local debugEnabled = isDebugTransportEnabled(player)

    if debugEnabled then
        logMap(
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
    local owner = getOwnerUsername(ownerUsername or player)
    local knownMapRevision = math.max(0, math.floor(tonumber(args and args.knownMapRevision) or 0))
    local knownTopologyRevision = math.max(0, math.floor(tonumber(args and args.knownTopologyRevision) or 0))
    local requestToken = tostring(args and args.requestToken or nextRequestToken(owner))

    local header, plots = buildVisiblePlots(owner, player)
    local revisions = getRevisions(owner)
    local chunks = {}

    if knownMapRevision ~= revisions.mapRevision or knownTopologyRevision ~= revisions.topologyRevision or args and args.forceFull == true then
        chunks = splitPlotsIntoChunks(plots)
    end

    sendMapPacket(player, "BuildingMapOpenState", {
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
        sendMapPacket(player, "BuildingMapStatus", {
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
        sendMapPacket(player, "BuildingMapStatus", {
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
        sendMapPacket(player, "BuildingMapChunk", {
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

    sendMapPacket(player, "BuildingMapReady", {
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
    local owner = getOwnerUsername(ownerUsername or player)
    local requested = type(args and args.plotKeys) == "table" and args.plotKeys or {}
    local header, plots = buildVisiblePlots(owner, player)
    local revisions = getRevisions(owner)
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

    sendMapPacket(player, "BuildingPlotsUpdated", {
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
    local owner = getOwnerUsername(ownerUsername or player)
    local header, plots = buildVisiblePlots(owner, options and options.sourcePlayer or player)
    local revisions = options and options.mapChange or getRevisions(owner)
    local targetKey = getPlotKey(plotX, plotY)
    local found = nil

    for _, plot in ipairs(plots) do
        if tostring(plot.key or "") == targetKey then
            found = plot
            break
        end
    end

    sendMapPacket(player, "BuildingPlotUpdated", {
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
    local owner = getOwnerUsername(ownerUsername or player)
    local header, plots = buildVisiblePlots(owner, options and options.sourcePlayer or player)
    local revisions = options and options.mapChange or getRevisions(owner)
    local coordsByKey = {}
    local selected = {}

    for _, coord in ipairs(coords or {}) do
        coordsByKey[getPlotKey(coord and coord.x, coord and coord.y)] = true
    end

    for _, plot in ipairs(plots) do
        if coordsByKey[tostring(plot.key or "")] then
            selected[#selected + 1] = plot
        end
    end

    sendMapPacket(player, "BuildingPlotsUpdated", {
        ownerUsername = owner,
        domain = "Building",
        mapRevision = revisions.mapRevision,
        topologyRevision = revisions.topologyRevision,
        header = header,
        plots = selected,
        reason = tostring(options and options.reason or "multi-plot-update"),
    })
end

function MapTransport.PushOwnerMutation(ownerUsername, context)
    local owner = getOwnerUsername(ownerUsername)
    local mapChange = context and context.mapChange or MapTransport.Touch(owner, context or {})
    local coords = context and context.coords or collectAffectedCoords(owner, context or {})
    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    local primaryKey = context and context.plotX ~= nil and context.plotY ~= nil and getPlotKey(context.plotX, context.plotY) or nil
    local secondaryCoords = {}

    for _, coord in ipairs(coords or {}) do
        local key = getPlotKey(coord and coord.x, coord and coord.y)
        if key ~= primaryKey then
            secondaryCoords[#secondaryCoords + 1] = coord
        end
    end

    if not onlinePlayers then
        return mapChange
    end

    for index = 0, onlinePlayers:size() - 1 do
        local player = onlinePlayers:get(index)
        if player and getOwnerUsername(player) == owner then
            if context and context.notice and Internal.syncNotice then
                Internal.syncNotice(player, context.notice.message, context.notice.severity, context.notice.popup)
            end
            if context and context.workerID and Internal.syncWorkerUpdated then
                Internal.syncWorkerUpdated(player, owner, context.workerID)
            end
            if context and context.sendWorkerList ~= false and Internal.syncWorkerListFocused then
                Internal.syncWorkerListFocused(player, owner)
            end

            if context and context.plotX ~= nil and context.plotY ~= nil then
                MapTransport.SyncPlotUpdated(player, owner, context.plotX, context.plotY, {
                    sourcePlayer = player,
                    mapChange = mapChange,
                })
            end

            if context and context.transition and context.transition.safetyChanged == true then
                MapTransport.SyncPlotsUpdated(player, owner, coords, {
                    sourcePlayer = player,
                    mapChange = mapChange,
                    reason = "plot-safety",
                })
            elseif #secondaryCoords > 0 then
                MapTransport.SyncPlotsUpdated(player, owner, secondaryCoords, {
                    sourcePlayer = player,
                    mapChange = mapChange,
                    reason = "owner-mutation",
                })
            elseif not (context and context.plotX ~= nil and context.plotY ~= nil) and #coords > 0 then
                MapTransport.SyncPlotsUpdated(player, owner, coords, {
                    sourcePlayer = player,
                    mapChange = mapChange,
                    reason = "owner-mutation",
                })
            end

            if context and context.sendFactionStatus == true and Internal.syncFactionStatusSummary then
                Internal.syncFactionStatusSummary(player, owner)
            end
        end
    end

    return mapChange
end

Network.Handlers.RequestBuildingMapOpen = function(player, args)
    MapTransport.SyncOpen(player, player, args or {})
end

Network.Handlers.RequestBuildingMapRetry = function(player, args)
    local payload = args or {}
    payload.forceFull = true
    MapTransport.SyncOpen(player, player, payload)
end

Network.Handlers.RequestBuildingPlots = function(player, args)
    MapTransport.SyncPlots(player, player, args or {})
end

return Network
