DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local NetworkInternal = DC_Colony.Network.Internal
local Buildings = DC_Buildings

NetworkInternal.BuildingMap = NetworkInternal.BuildingMap or {}

local MapTransport = NetworkInternal.BuildingMap
local modules = MapTransport.Modules or {}
local helpers = MapTransport.Helpers or {}

MapTransport.Modules = modules
MapTransport.Helpers = helpers

if modules.Snapshots then
    return
end

modules.Snapshots = true

function helpers.BuildHeader(ownerUsername, snapshot)
    local territory = snapshot or {}
    local bounds = type(territory.bounds) == "table" and territory.bounds or {
        minX = 0,
        maxX = 0,
        minY = 0,
        maxY = 0,
    }
    return {
        ownerUsername = ownerUsername,
        colonyId = tostring(territory.colonyId or ownerUsername or "local"),
        hqLevel = tonumber(territory.headquartersLevel) or 0,
        securedRing = tonumber(territory.securedPerimeterRing) or 0,
        currentRing = tonumber(territory.currentFrontierRing) or 1,
        nextRing = tonumber(territory.nextFrontierRing) or tonumber(territory.currentFrontierRing) or 1,
        frontierRequiredHQLevel = tonumber(territory.frontierRequiredHQLevel) or 1,
        frontierExpansionAvailable = territory.frontierExpansionAvailable == true,
        unlockedPlotCount = tonumber(territory.unlockedPlotCount) or 0,
        activeBarricadeCount = tonumber(territory.activeBarricadeCount) or 0,
        completedBarricadeCount = tonumber(territory.completedBarricadeCount) or tonumber(territory.activeBarricadeCount) or 0,
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

function helpers.TrimPlotPayload(ownerUsername, header, plot)
    if type(plot) ~= "table" then
        return nil
    end

    local building = type(plot.building) == "table" and helpers.ShallowCopy(plot.building) or nil
    local project = type(plot.project) == "table" and helpers.ShallowCopy(plot.project) or nil
    local availableActions = type(plot.availableActions) == "table" and helpers.ShallowCopy(plot.availableActions) or {}

    return {
        key = tostring(plot.key or helpers.GetPlotKey(plot.x, plot.y)),
        x = math.floor(tonumber(plot.x) or 0),
        y = math.floor(tonumber(plot.y) or 0),
        ring = math.floor(tonumber(plot.ring) or 0),
        kind = plot.kind,
        state = plot.state,
        unlocked = plot.unlocked == true,
        safeTile = plot.safeTile == true,
        frontierCandidate = plot.frontierCandidate == true,
        revision = helpers.GetPlotRevision(ownerUsername, tostring(plot.key or helpers.GetPlotKey(plot.x, plot.y))),
        availableActions = availableActions,
        buildOptions = helpers.CopyArray(plot.buildOptions),
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
            completedBarricadeCount = header.completedBarricadeCount,
            maxActiveBarricades = header.maxActiveBarricades,
        },
    }
end

function helpers.SortPlots(plots)
    table.sort(plots, function(a, b)
        if tonumber(a.y) == tonumber(b.y) then
            return tonumber(a.x) < tonumber(b.x)
        end
        return tonumber(a.y) < tonumber(b.y)
    end)
end

function helpers.BuildVisiblePlots(ownerUsername, sourcePlayer)
    if Buildings.EnsureInitialHeadquartersProject then
        Buildings.EnsureInitialHeadquartersProject(ownerUsername)
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
    local header = helpers.BuildHeader(ownerUsername, snapshot)
    local plots = {}

    for _, plot in ipairs(snapshot.plots or {}) do
        local trimmed = helpers.TrimPlotPayload(ownerUsername, header, plot)
        if trimmed then
            plots[#plots + 1] = trimmed
        end
    end

    helpers.SortPlots(plots)
    return header, plots
end

function helpers.PrioritizeCorePlot(plots)
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

function helpers.SplitPlotsIntoChunks(plots)
    local ordered = helpers.PrioritizeCorePlot(plots or {})
    local chunks = {}
    local current = {}
    local currentSize = 0

    for _, plot in ipairs(ordered) do
        local plotSize = helpers.EstimatePayloadSize(plot)
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
