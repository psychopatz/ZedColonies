DC_BuildingsClientState = DC_BuildingsClientState or {}

local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function sortPlots(plots)
    table.sort(plots, function(a, b)
        if tonumber(a.y) == tonumber(b.y) then
            return tonumber(a.x) < tonumber(b.x)
        end
        return tonumber(a.y) < tonumber(b.y)
    end)
end

function DC_BuildingsClientState.Normalize(snapshot)
    local state = snapshot or {}
    state.colonyId = tostring(state.colonyId or "")
    state.map = type(state.map) == "table" and state.map or {}
    state.map.colonyId = tostring(state.map.colonyId or state.colonyId or "")
    state.map.plots = type(state.map.plots) == "table" and state.map.plots or {}
    state.map.bounds = type(state.map.bounds) == "table" and state.map.bounds or {
        minX = -1,
        maxX = 1,
        minY = -1,
        maxY = 1
    }
    state.sync = type(state.sync) == "table" and state.sync or {}
    state.sync.state = tostring(state.sync.state or "idle")
    state.sync.message = state.sync.message or nil
    state.sync.requestToken = state.sync.requestToken or nil
    state.sync.mapRevision = math.max(0, math.floor(tonumber(state.sync.mapRevision) or 0))
    state.sync.topologyRevision = math.max(0, math.floor(tonumber(state.sync.topologyRevision) or 0))
    state.sync.chunkCount = math.max(0, math.floor(tonumber(state.sync.chunkCount) or 0))
    state.sync.receivedChunks = math.max(0, math.floor(tonumber(state.sync.receivedChunks) or 0))
    state.sync.plotCount = math.max(0, math.floor(tonumber(state.sync.plotCount) or 0))

    local territory = {
        headquartersLevel = tonumber(state.map.headquartersLevel) or 0,
        securedPerimeterRing = tonumber(state.map.securedPerimeterRing) or 0,
        currentFrontierRing = tonumber(state.map.currentFrontierRing) or 1,
        nextFrontierRing = tonumber(state.map.nextFrontierRing) or tonumber(state.map.currentFrontierRing) or 1,
        frontierExpansionAvailable = state.map.frontierExpansionAvailable == true,
        frontierRequiredHQLevel = tonumber(state.map.frontierRequiredHQLevel) or 1,
        unlockedPlotCount = tonumber(state.map.unlockedPlotCount) or 0,
        activeBarricadeCount = tonumber(state.map.activeBarricadeCount) or 0,
        completedBarricadeCount = tonumber(state.map.completedBarricadeCount) or tonumber(state.map.activeBarricadeCount) or 0,
        maxActiveBarricades = tonumber(state.map.maxActiveBarricades) or 0,
    }

    for _, plot in ipairs(state.map.plots) do
        if type(plot) == "table" then
            plot.territory = type(plot.territory) == "table" and plot.territory or shallowCopy(territory)
            plot.revision = math.max(0, math.floor(tonumber(plot.revision) or 0))
        end
    end

    sortPlots(state.map.plots)
    return state
end

return DC_BuildingsClientState
