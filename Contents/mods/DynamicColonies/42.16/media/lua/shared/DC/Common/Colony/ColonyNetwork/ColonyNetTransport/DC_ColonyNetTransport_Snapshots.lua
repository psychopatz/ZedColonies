DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Internal = DC_Colony.Network.Internal
local Transport = Internal.Transport or {}
local Registry = Transport.Registry or {}
local Buildings = Transport.Buildings or {}

function Transport.findPlotEntryByCoords(mapSnapshot, plotX, plotY)
    for _, plot in ipairs(mapSnapshot and mapSnapshot.plots or {}) do
        if math.floor(tonumber(plot.x) or 0) == math.floor(tonumber(plotX) or 0)
            and math.floor(tonumber(plot.y) or 0) == math.floor(tonumber(plotY) or 0) then
            return plot
        end
    end
    return nil
end

function Transport.buildMapMeta(mapSnapshot)
    local map = mapSnapshot or {}
    return {
        colonyId = tostring(map.colonyId or "local"),
        bounds = Transport.copyShallow(map.bounds),
        headquartersLevel = tonumber(map.headquartersLevel) or 0,
        securedPerimeterRing = tonumber(map.securedPerimeterRing) or 0,
        currentFrontierRing = tonumber(map.currentFrontierRing) or 0,
        nextFrontierRing = tonumber(map.nextFrontierRing) or 0,
        frontierExpansionAvailable = map.frontierExpansionAvailable == true,
        frontierRequiredHQLevel = tonumber(map.frontierRequiredHQLevel) or 0,
        unlockedPlotCount = tonumber(map.unlockedPlotCount) or 0,
        activeBarricadeCount = tonumber(map.activeBarricadeCount) or 0,
        completedBarricadeCount = tonumber(map.completedBarricadeCount) or tonumber(map.activeBarricadeCount) or 0,
        maxActiveBarricades = tonumber(map.maxActiveBarricades) or 0,
    }
end

function Transport.buildPlotPacket(ownerUsername, plotX, plotY, sourcePlayer)
    local mapSnapshot = Buildings.BuildMapSnapshot and Buildings.BuildMapSnapshot(ownerUsername, sourcePlayer) or { plots = {} }
    return Transport.findPlotEntryByCoords(mapSnapshot, plotX, plotY), Transport.buildMapMeta(mapSnapshot)
end

function Transport.buildPlotsPacket(ownerUsername, coords, sourcePlayer)
    local mapSnapshot = Buildings.BuildMapSnapshot and Buildings.BuildMapSnapshot(ownerUsername, sourcePlayer) or { plots = {} }
    local plots = {}
    local seen = {}
    for _, coord in ipairs(coords or {}) do
        local key = tostring(math.floor(tonumber(coord and coord.x) or 0)) .. ":" .. tostring(math.floor(tonumber(coord and coord.y) or 0))
        if not seen[key] then
            seen[key] = true
            local plot = Transport.findPlotEntryByCoords(mapSnapshot, coord.x, coord.y)
            if plot then
                plots[#plots + 1] = plot
            end
        end
    end
    table.sort(plots, function(a, b)
        if tonumber(a.y) == tonumber(b.y) then
            return tonumber(a.x) < tonumber(b.x)
        end
        return tonumber(a.y) < tonumber(b.y)
    end)
    return plots, Transport.buildMapMeta(mapSnapshot)
end

function Transport.buildWorkerSummary(worker)
    if not worker then
        return nil
    end
    return Registry.GetWorkerSummaryForOwner and Registry.GetWorkerSummaryForOwner(worker.ownerUsername, worker.workerID)
        or Registry.GetWorkerDetailsForOwner and Registry.GetWorkerDetailsForOwner(worker.ownerUsername, worker.workerID, false, false)
        or nil
end

function Transport.findWorker(ownerUsername, workerID)
    return Registry.GetWorkerForOwner and Registry.GetWorkerForOwner(ownerUsername, workerID)
        or Registry.GetWorkerForOwnerRaw and Registry.GetWorkerForOwnerRaw(ownerUsername, workerID)
        or nil
end

function Transport.getWorkerDetailForPacket(ownerUsername, workerID)
    return Registry.GetWorkerDetailsForOwner and Registry.GetWorkerDetailsForOwner(ownerUsername, workerID, false, false) or nil
end

return Transport
