DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Network = DC_Colony.Network
local NetworkInternal = Network.Internal
local Buildings = DC_Buildings

NetworkInternal.BuildingMap = NetworkInternal.BuildingMap or {}

local MapTransport = NetworkInternal.BuildingMap
local modules = MapTransport.Modules or {}
local helpers = MapTransport.Helpers or {}

MapTransport.Modules = modules
MapTransport.Helpers = helpers

if modules.Revisions then
    return
end

modules.Revisions = true

function helpers.EnsureRevisionState(ownerUsername)
    local ownerData = Buildings.Internal
        and Buildings.Internal.GetOwnerDataIfNormalizing
        and Buildings.Internal.GetOwnerDataIfNormalizing(ownerUsername)
        or Buildings.EnsureOwner and Buildings.EnsureOwner(ownerUsername)
        or nil
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

function helpers.GetPlotRevision(ownerUsername, plotKey)
    local state = helpers.EnsureRevisionState(ownerUsername)
    return math.max(1, math.floor(tonumber(state.plotRevisions and state.plotRevisions[plotKey]) or 1))
end

function helpers.GetRevisions(ownerUsername)
    local state = helpers.EnsureRevisionState(ownerUsername)
    return {
        mapRevision = math.max(1, math.floor(tonumber(state.buildingMapRevision) or 1)),
        topologyRevision = math.max(1, math.floor(tonumber(state.buildingTopologyRevision) or 1)),
    }
end

function helpers.NextRequestToken(ownerUsername)
    local state = helpers.EnsureRevisionState(ownerUsername)
    state.nextRequestToken = math.max(0, math.floor(tonumber(state.nextRequestToken) or 0)) + 1
    return tostring(ownerUsername) .. ":" .. tostring(state.nextRequestToken)
end

function helpers.AppendUniqueCoord(target, seen, plotX, plotY)
    if plotX == nil or plotY == nil then
        return
    end
    local coord = helpers.NormalizeCoord(plotX, plotY)
    local key = helpers.GetPlotKey(coord.x, coord.y)
    if seen[key] then
        return
    end
    seen[key] = true
    target[#target + 1] = coord
end

function helpers.CollectAffectedCoords(ownerUsername, context)
    local coords = {}
    local seen = {}

    helpers.AppendUniqueCoord(coords, seen, context and context.plotX, context and context.plotY)

    for _, coord in ipairs(context and context.additionalPlots or {}) do
        helpers.AppendUniqueCoord(coords, seen, coord and coord.x, coord and coord.y)
    end

    local transition = context and context.transition or nil
    for _, coord in ipairs(transition and transition.affectedCoords or {}) do
        helpers.AppendUniqueCoord(coords, seen, coord and coord.x, coord and coord.y)
    end

    if #coords <= 0 and transition and tonumber(transition.securedRingAfter) and Buildings.GetRingCoordinates then
        for _, coord in ipairs(Buildings.GetRingCoordinates(transition.securedRingAfter) or {}) do
            helpers.AppendUniqueCoord(coords, seen, coord and coord.x, coord and coord.y)
        end
    end

    if #coords <= 0 and ownerUsername and Buildings.GetUnlockedPlotEntries then
        for _, plot in ipairs(Buildings.GetUnlockedPlotEntries(ownerUsername) or {}) do
            helpers.AppendUniqueCoord(coords, seen, plot and plot.x, plot and plot.y)
        end
    end

    return coords
end

function MapTransport.Touch(ownerUsername, context)
    local owner = helpers.GetOwnerUsername(ownerUsername)
    local state = helpers.EnsureRevisionState(owner)
    local coords = helpers.CollectAffectedCoords(owner, context or {})
    local topologyChanged = context and (context.topologyChanged == true or (context.transition and context.transition.safetyChanged == true)) or false

    state.buildingMapRevision = math.max(1, math.floor(tonumber(state.buildingMapRevision) or 1)) + 1
    if topologyChanged then
        state.buildingTopologyRevision = math.max(1, math.floor(tonumber(state.buildingTopologyRevision) or 1)) + 1
    end

    local plotRevisions = {}
    for _, coord in ipairs(coords) do
        local key = helpers.GetPlotKey(coord.x, coord.y)
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
