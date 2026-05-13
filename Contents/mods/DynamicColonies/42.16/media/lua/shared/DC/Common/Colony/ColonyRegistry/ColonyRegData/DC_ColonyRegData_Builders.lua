DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegData or {}

function Data.buildEmptyIndex()
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        nextColonyID = 1,
        playerToColonyID = {},
        colonies = {}
    }
end

function Data.buildEmptyColony(colonyID, ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        colonyID = Data.normalizeID(colonyID),
        colonyName = "Colony " .. tostring(colonyID),
        ownerUsername = owner,
        leaderUsername = owner,
        memberUsernames = {},
        permissions = {},
        recruitAttempts = {},
        versions = {
            colony = 1,
            workers = 1,
            sites = 1,
            warehouse = 1,
            warehouseItems = 1,
            buildings = 1,
        },
        counters = {
            nextWorkerID = 1,
            nextSiteID = 1,
        }
    }
end

function Data.buildEmptyWorkersData(colonyID)
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        colonyID = Data.normalizeID(colonyID),
        version = 1,
        workerIDs = {},
        summaries = {}
    }
end

function Data.buildEmptySitesData(colonyID)
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        colonyID = Data.normalizeID(colonyID),
        version = 1,
        sites = {}
    }
end

function Data.getIndexKey()
    return tostring(Config.MOD_DATA_INDEX_KEY or Config.MOD_DATA_KEY or "DColony_Index")
end

function Data.getColonyKey(colonyID)
    return tostring(Config.MOD_DATA_COLONY_PREFIX or "DColony_Colony_") .. tostring(colonyID)
end

function Data.getWorkersKey(colonyID)
    return tostring(Config.MOD_DATA_WORKERS_PREFIX or "DColony_Workers_") .. tostring(colonyID)
end

function Data.getWorkerKey(colonyID, workerID)
    return tostring(Config.MOD_DATA_WORKER_PREFIX or "DColony_Worker_") .. tostring(colonyID) .. "_" .. tostring(workerID)
end

function Data.getSitesKey(colonyID)
    return tostring(Config.MOD_DATA_SITES_PREFIX or "DColony_Sites_") .. tostring(colonyID)
end

Internal.GetColonyKey = Data.getColonyKey
Internal.GetWorkersKey = Data.getWorkersKey
Internal.GetWorkerKey = Data.getWorkerKey
Internal.GetSitesKey = Data.getSitesKey

return Data