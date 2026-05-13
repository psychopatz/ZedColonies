DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Runtime = Internal.Runtime or {}
local Data = Internal.ColonyRegData or {}

function Registry.Save()
    local index = Data.ensureIndex()
    for colonyID, _ in pairs(index.colonies or {}) do
        local workersData = Data.ensureWorkersData(colonyID)
        if Registry.GetWorkerSummary then
            local summaries = {}
            for _, workerID in ipairs(workersData.workerIDs or {}) do
                local worker = Data.ensureWorkerData(colonyID, workerID, {})
                summaries[workerID] = Registry.GetWorkerSummary(worker)
            end
            workersData.summaries = summaries
        end
        Data.syncColonySummary(tostring(colonyID))
    end

    if GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
end

function Registry.NextID(kind, ownerOrColonyID)
    local colonyData = Registry.GetColonyData(ownerOrColonyID, true)
    if not colonyData then
        return 0
    end

    local key = kind == "site" and "nextSiteID" or "nextWorkerID"
    local prefix = kind == "site" and "site_" or "worker_"
    local value = math.max(1, math.floor(tonumber(colonyData.counters[key]) or 1))
    colonyData.counters[key] = value + 1
    colonyData.versions.colony = colonyData.versions.colony + 1
    return prefix .. tostring(value)
end

function Registry.TouchColonyVersion(ownerOrColonyID)
    local colonyData = Registry.GetColonyData(ownerOrColonyID, true)
    if not colonyData then
        return 0
    end

    colonyData.versions.colony = math.max(1, math.floor(tonumber(colonyData.versions.colony) or 1)) + 1
    Data.syncColonySummary(colonyData.colonyID)
    return colonyData.versions.colony
end

function Registry.TouchWorkersVersion(ownerOrColonyID)
    local colonyData = Registry.GetColonyData(ownerOrColonyID, true)
    local workersData = Registry.GetWorkersData(ownerOrColonyID, true)
    if not colonyData or not workersData then
        return 0
    end

    workersData.version = math.max(1, math.floor(tonumber(workersData.version) or 1)) + 1
    colonyData.versions.workers = workersData.version
    Data.syncColonySummary(colonyData.colonyID)
    return workersData.version
end

function Registry.TouchSitesVersion(ownerOrColonyID)
    local colonyData = Registry.GetColonyData(ownerOrColonyID, true)
    local sitesData = Registry.GetSitesData(ownerOrColonyID, true)
    if not colonyData or not sitesData then
        return 0
    end

    sitesData.version = math.max(1, math.floor(tonumber(sitesData.version) or 1)) + 1
    colonyData.versions.sites = sitesData.version
    Data.syncColonySummary(colonyData.colonyID)
    return sitesData.version
end

function Registry.TouchWorkerDetailVersion(worker)
    if type(worker) ~= "table" then
        return 0
    end

    worker.detailVersion = math.max(1, math.floor(tonumber(worker.detailVersion) or 1)) + 1
    return worker.detailVersion
end

function Registry.RemoveWorkerShard(colonyID, workerID)
    local key = Data.getWorkerKey(colonyID, workerID)
    if ModData.remove and ModData.exists(key) then
        ModData.remove(key)
    else
        local data = ModData.get(key)
        if type(data) == "table" then
            Data.clearTable(data)
        end
    end

    if Runtime.workerToColonyID then
        Runtime.workerToColonyID[tostring(workerID)] = nil
    end
end

return Data