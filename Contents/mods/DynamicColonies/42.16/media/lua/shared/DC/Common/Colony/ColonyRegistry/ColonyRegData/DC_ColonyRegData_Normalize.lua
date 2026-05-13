DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegData or {}

function Data.normalizeIndex(data)
    data.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    data.nextColonyID = math.max(1, math.floor(tonumber(data.nextColonyID) or 1))
    data.playerToColonyID = Data.ensureTable(data.playerToColonyID)
    data.colonies = Data.ensureTable(data.colonies)
    return data
end

function Data.normalizeVersions(versions)
    versions = Data.ensureTable(versions)
    versions.colony = math.max(1, math.floor(tonumber(versions.colony) or 1))
    versions.workers = math.max(1, math.floor(tonumber(versions.workers) or 1))
    versions.sites = math.max(1, math.floor(tonumber(versions.sites) or 1))
    versions.warehouse = math.max(1, math.floor(tonumber(versions.warehouse) or 1))
    versions.warehouseItems = math.max(1, math.floor(tonumber(versions.warehouseItems) or 1))
    versions.buildings = math.max(1, math.floor(tonumber(versions.buildings) or 1))
    return versions
end

function Data.normalizeCounters(counters)
    counters = Data.ensureTable(counters)
    counters.nextWorkerID = math.max(1, math.floor(tonumber(counters.nextWorkerID) or 1))
    counters.nextSiteID = math.max(1, math.floor(tonumber(counters.nextSiteID) or 1))
    return counters
end

function Data.normalizeColonyData(colonyID, colonyData)
    local fallbackOwner = colonyData and (colonyData.ownerUsername or colonyData.leaderUsername) or "local"
    local normalizedID = Data.normalizeID(colonyID)
    local owner = Config.GetOwnerUsername(fallbackOwner)

    colonyData.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    colonyData.colonyID = normalizedID
    colonyData.colonyName = tostring(colonyData.colonyName or ("Colony " .. normalizedID))
    colonyData.ownerUsername = owner
    colonyData.leaderUsername = Config.GetOwnerUsername(colonyData.leaderUsername or owner)
    colonyData.memberUsernames = type(colonyData.memberUsernames) == "table" and colonyData.memberUsernames or {}
    colonyData.permissions = Data.ensureTable(colonyData.permissions)
    colonyData.recruitAttempts = Data.ensureTable(colonyData.recruitAttempts)
    colonyData.versions = Data.normalizeVersions(colonyData.versions)
    colonyData.counters = Data.normalizeCounters(colonyData.counters)
    return colonyData
end

function Data.normalizeWorkersData(colonyID, workersData)
    workersData.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    workersData.colonyID = Data.normalizeID(colonyID)
    workersData.version = math.max(1, math.floor(tonumber(workersData.version) or 1))
    workersData.workerIDs = type(workersData.workerIDs) == "table" and workersData.workerIDs or {}
    workersData.summaries = Data.ensureTable(workersData.summaries)
    return workersData
end

function Data.normalizeSitesData(colonyID, sitesData)
    sitesData.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    sitesData.colonyID = Data.normalizeID(colonyID)
    sitesData.version = math.max(1, math.floor(tonumber(sitesData.version) or 1))
    sitesData.sites = Data.ensureTable(sitesData.sites)
    return sitesData
end

function Data.normalizeWorkerData(colonyID, workerID, workerData)
    workerData.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    workerData.colonyID = Data.normalizeID(colonyID)
    workerData.workerID = tostring(workerData.workerID or workerID or "")
    workerData.detailVersion = math.max(1, math.floor(tonumber(workerData.detailVersion) or 1))
    workerData.ownerUsername = Config.GetOwnerUsername(workerData.ownerUsername)
    return workerData
end

function Data.ensureIndex()
    return Data.normalizeIndex(Data.ensureModDataTable(Data.getIndexKey(), Data.buildEmptyIndex()))
end

function Data.ensureColonyData(colonyID, ownerUsername)
    return Data.normalizeColonyData(
        colonyID,
        Data.ensureModDataTable(Data.getColonyKey(colonyID), Data.buildEmptyColony(colonyID, ownerUsername))
    )
end

function Data.ensureWorkersData(colonyID)
    return Data.normalizeWorkersData(colonyID, Data.ensureModDataTable(Data.getWorkersKey(colonyID), Data.buildEmptyWorkersData(colonyID)))
end

function Data.ensureSitesData(colonyID)
    return Data.normalizeSitesData(colonyID, Data.ensureModDataTable(Data.getSitesKey(colonyID), Data.buildEmptySitesData(colonyID)))
end

function Data.ensureWorkerData(colonyID, workerID, defaults)
    return Data.normalizeWorkerData(
        colonyID,
        workerID,
        Data.ensureModDataTable(Data.getWorkerKey(colonyID, workerID), defaults or {})
    )
end

Internal.NormalizeWorkerData = Data.normalizeWorkerData

return Data