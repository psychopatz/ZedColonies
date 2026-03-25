DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal

Internal.Runtime = Internal.Runtime or {}

local Runtime = Internal.Runtime

local function ensureTable(value)
    return type(value) == "table" and value or {}
end

local function clearTable(target)
    for key, _ in pairs(target or {}) do
        target[key] = nil
    end
end

local function ensureModDataTable(key, defaults)
    if not ModData.exists(key) then
        ModData.add(key, defaults or {})
    end

    local data = ModData.get(key)
    if type(data) == "table" then
        return data
    end

    if ModData.remove then
        ModData.remove(key)
    end

    ModData.add(key, defaults or {})
    return ModData.get(key)
end

local function normalizeID(value, fallback)
    local text = tostring(value or fallback or "")
    if text == "" then
        return tostring(fallback or "0")
    end
    return text
end

local function buildEmptyIndex()
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        nextColonyID = 1,
        playerToColonyID = {},
        colonies = {}
    }
end

local function buildEmptyColony(colonyID, ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        colonyID = normalizeID(colonyID),
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

local function buildEmptyWorkersData(colonyID)
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        colonyID = normalizeID(colonyID),
        version = 1,
        workerIDs = {},
        summaries = {}
    }
end

local function buildEmptySitesData(colonyID)
    return {
        schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3,
        colonyID = normalizeID(colonyID),
        version = 1,
        sites = {}
    }
end

local function getIndexKey()
    return tostring(Config.MOD_DATA_INDEX_KEY or Config.MOD_DATA_KEY or "DColony_Index")
end

local function getColonyKey(colonyID)
    return tostring(Config.MOD_DATA_COLONY_PREFIX or "DColony_Colony_") .. tostring(colonyID)
end

local function getWorkersKey(colonyID)
    return tostring(Config.MOD_DATA_WORKERS_PREFIX or "DColony_Workers_") .. tostring(colonyID)
end

local function getWorkerKey(colonyID, workerID)
    return tostring(Config.MOD_DATA_WORKER_PREFIX or "DColony_Worker_") .. tostring(colonyID) .. "_" .. tostring(workerID)
end

local function getSitesKey(colonyID)
    return tostring(Config.MOD_DATA_SITES_PREFIX or "DColony_Sites_") .. tostring(colonyID)
end

local function normalizeIndex(data)
    data.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    data.nextColonyID = math.max(1, math.floor(tonumber(data.nextColonyID) or 1))
    data.playerToColonyID = ensureTable(data.playerToColonyID)
    data.colonies = ensureTable(data.colonies)
    return data
end

local function normalizeVersions(versions)
    versions = ensureTable(versions)
    versions.colony = math.max(1, math.floor(tonumber(versions.colony) or 1))
    versions.workers = math.max(1, math.floor(tonumber(versions.workers) or 1))
    versions.sites = math.max(1, math.floor(tonumber(versions.sites) or 1))
    versions.warehouse = math.max(1, math.floor(tonumber(versions.warehouse) or 1))
    versions.warehouseItems = math.max(1, math.floor(tonumber(versions.warehouseItems) or 1))
    versions.buildings = math.max(1, math.floor(tonumber(versions.buildings) or 1))
    return versions
end

local function normalizeCounters(counters)
    counters = ensureTable(counters)
    counters.nextWorkerID = math.max(1, math.floor(tonumber(counters.nextWorkerID) or 1))
    counters.nextSiteID = math.max(1, math.floor(tonumber(counters.nextSiteID) or 1))
    return counters
end

local function normalizeColonyData(colonyID, colonyData)
    local fallbackOwner = colonyData and (colonyData.ownerUsername or colonyData.leaderUsername) or "local"
    local normalizedID = normalizeID(colonyID)
    local owner = Config.GetOwnerUsername(fallbackOwner)

    colonyData.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    colonyData.colonyID = normalizedID
    colonyData.colonyName = tostring(colonyData.colonyName or ("Colony " .. normalizedID))
    colonyData.ownerUsername = owner
    colonyData.leaderUsername = Config.GetOwnerUsername(colonyData.leaderUsername or owner)
    colonyData.memberUsernames = type(colonyData.memberUsernames) == "table" and colonyData.memberUsernames or {}
    colonyData.permissions = ensureTable(colonyData.permissions)
    colonyData.recruitAttempts = ensureTable(colonyData.recruitAttempts)
    colonyData.versions = normalizeVersions(colonyData.versions)
    colonyData.counters = normalizeCounters(colonyData.counters)
    return colonyData
end

local function normalizeWorkersData(colonyID, workersData)
    workersData.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    workersData.colonyID = normalizeID(colonyID)
    workersData.version = math.max(1, math.floor(tonumber(workersData.version) or 1))
    workersData.workerIDs = type(workersData.workerIDs) == "table" and workersData.workerIDs or {}
    workersData.summaries = ensureTable(workersData.summaries)
    return workersData
end

local function normalizeSitesData(colonyID, sitesData)
    sitesData.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    sitesData.colonyID = normalizeID(colonyID)
    sitesData.version = math.max(1, math.floor(tonumber(sitesData.version) or 1))
    sitesData.sites = ensureTable(sitesData.sites)
    return sitesData
end

local function normalizeWorkerData(colonyID, workerID, workerData)
    workerData.schemaVersion = Config.MOD_DATA_SCHEMA_VERSION or 3
    workerData.colonyID = normalizeID(colonyID)
    workerData.workerID = tostring(workerData.workerID or workerID or "")
    workerData.detailVersion = math.max(1, math.floor(tonumber(workerData.detailVersion) or 1))
    workerData.ownerUsername = Config.GetOwnerUsername(workerData.ownerUsername)
    return workerData
end

local function ensureIndex()
    return normalizeIndex(ensureModDataTable(getIndexKey(), buildEmptyIndex()))
end

local function ensureColonyData(colonyID, ownerUsername)
    return normalizeColonyData(
        colonyID,
        ensureModDataTable(getColonyKey(colonyID), buildEmptyColony(colonyID, ownerUsername))
    )
end

local function ensureWorkersData(colonyID)
    return normalizeWorkersData(colonyID, ensureModDataTable(getWorkersKey(colonyID), buildEmptyWorkersData(colonyID)))
end

local function ensureSitesData(colonyID)
    return normalizeSitesData(colonyID, ensureModDataTable(getSitesKey(colonyID), buildEmptySitesData(colonyID)))
end

local function ensureWorkerData(colonyID, workerID, defaults)
    return normalizeWorkerData(
        colonyID,
        workerID,
        ensureModDataTable(getWorkerKey(colonyID, workerID), defaults or {})
    )
end

local function getAuthorityOwner(ownerUsername)
    return Config.GetOwnerUsername(ownerUsername)
end

local function syncColonySummary(colonyID)
    local index = ensureIndex()
    local colonyData = ensureColonyData(colonyID, "local")
    local workersData = ensureWorkersData(colonyID)
    local summary = index.colonies[colonyID]
    if type(summary) ~= "table" then
        summary = {}
        index.colonies[colonyID] = summary
    end

    summary.colonyID = colonyID
    summary.colonyName = colonyData.colonyName
    summary.ownerUsername = colonyData.ownerUsername
    summary.leaderUsername = colonyData.leaderUsername
    summary.workerCount = #workersData.workerIDs
    summary.versions = Internal.CopyDeep and Internal.CopyDeep(colonyData.versions) or colonyData.versions
    index.playerToColonyID[colonyData.ownerUsername] = colonyID
end

local function rebuildRuntimeIndexes()
    Runtime.workerToColonyID = {}
    Runtime.siteToColonyID = {}
    Runtime.sourceNPCToWorkerID = {}

    local index = ensureIndex()
    for colonyID, summary in pairs(index.colonies or {}) do
        local colonyData = ensureColonyData(colonyID, summary and summary.ownerUsername or "local")
        local workersData = ensureWorkersData(colonyID)
        local sitesData = ensureSitesData(colonyID)

        for _, workerID in ipairs(workersData.workerIDs or {}) do
            local worker = ensureWorkerData(colonyID, workerID, {})
            worker.colonyID = colonyID
            worker.ownerUsername = colonyData.ownerUsername
            Runtime.workerToColonyID[workerID] = colonyID
            if worker.sourceNPCID ~= nil and tostring(worker.sourceNPCID or "") ~= "" then
                Runtime.sourceNPCToWorkerID[tostring(worker.sourceNPCID)] = workerID
            end
        end

        for siteID, site in pairs(sitesData.sites or {}) do
            if type(site) == "table" then
                site.siteID = site.siteID or siteID
                site.ownerUsername = colonyData.ownerUsername
                site.colonyID = colonyID
                Runtime.siteToColonyID[site.siteID] = colonyID
            end
        end

        syncColonySummary(colonyID)
    end
end

local function resolveColonyID(ownerUsername, createIfMissing)
    local index = ensureIndex()
    if ownerUsername ~= nil and index.colonies[tostring(ownerUsername)] then
        return tostring(ownerUsername)
    end

    local owner = getAuthorityOwner(ownerUsername)
    local colonyID = index.playerToColonyID[owner]

    if colonyID and index.colonies[tostring(colonyID)] then
        return tostring(colonyID)
    end

    for existingColonyID, summary in pairs(index.colonies or {}) do
        if Config.GetOwnerUsername(summary and (summary.ownerUsername or summary.leaderUsername)) == owner then
            index.playerToColonyID[owner] = tostring(existingColonyID)
            return tostring(existingColonyID)
        end
    end

    if not createIfMissing then
        return nil
    end

    colonyID = tostring(index.nextColonyID or 1)
    index.nextColonyID = (tonumber(index.nextColonyID) or 1) + 1
    ensureColonyData(colonyID, owner)
    ensureWorkersData(colonyID)
    ensureSitesData(colonyID)
    index.playerToColonyID[owner] = colonyID
    syncColonySummary(colonyID)
    return colonyID
end

local function buildOwnerView(colonyID)
    local colonyData = ensureColonyData(colonyID, "local")
    local workersData = ensureWorkersData(colonyID)
    local sitesData = ensureSitesData(colonyID)
    local workers = {}

    for _, workerID in ipairs(workersData.workerIDs or {}) do
        local worker = ensureWorkerData(colonyID, workerID, {})
        worker.ownerUsername = colonyData.ownerUsername
        worker.colonyID = colonyID
        workers[workerID] = worker
    end

    return {
        colonyID = colonyID,
        ownerUsername = colonyData.ownerUsername,
        leaderUsername = colonyData.leaderUsername,
        colonyName = colonyData.colonyName,
        permissions = colonyData.permissions,
        memberUsernames = colonyData.memberUsernames,
        recruitAttempts = colonyData.recruitAttempts,
        workerIDs = workersData.workerIDs,
        workers = workers,
        sites = sitesData.sites
    }
end

function Registry.Init()
    ensureIndex()
    rebuildRuntimeIndexes()
end

Events.OnInitGlobalModData.Add(Registry.Init)

function Registry.GetData()
    return ensureIndex()
end

function Registry.GetIndexKey()
    return getIndexKey()
end

function Registry.GetColonyIDForOwner(ownerUsername, createIfMissing)
    return resolveColonyID(ownerUsername, createIfMissing == true)
end

function Registry.ResolveColonyID(ownerUsername, createIfMissing)
    return resolveColonyID(ownerUsername, createIfMissing == true)
end

function Registry.GetColonyData(ownerOrColonyID, createIfMissing)
    local colonyID = resolveColonyID(ownerOrColonyID, createIfMissing == true)
    if not colonyID then
        return nil
    end
    return ensureColonyData(colonyID, ownerOrColonyID)
end

function Registry.GetWorkersData(ownerOrColonyID, createIfMissing)
    local colonyID = resolveColonyID(ownerOrColonyID, createIfMissing == true)
    if not colonyID then
        return nil
    end
    return ensureWorkersData(colonyID)
end

function Registry.GetSitesData(ownerOrColonyID, createIfMissing)
    local colonyID = resolveColonyID(ownerOrColonyID, createIfMissing == true)
    if not colonyID then
        return nil
    end
    return ensureSitesData(colonyID)
end

function Registry.GetWorkerData(colonyID, workerID)
    if not colonyID or not workerID then
        return nil
    end
    return ensureWorkerData(colonyID, workerID, {})
end

function Registry.GetOwnerData(ownerUsername)
    local colonyID = resolveColonyID(ownerUsername, true)
    return buildOwnerView(colonyID)
end

function Registry.Save()
    local index = ensureIndex()
    for colonyID, _ in pairs(index.colonies or {}) do
        local workersData = ensureWorkersData(colonyID)
        if Registry.GetWorkerSummary then
            local summaries = {}
            for _, workerID in ipairs(workersData.workerIDs or {}) do
                local worker = ensureWorkerData(colonyID, workerID, {})
                summaries[workerID] = Registry.GetWorkerSummary(worker)
            end
            workersData.summaries = summaries
        end
        syncColonySummary(tostring(colonyID))
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

function Registry.EnsureOwner(ownerUsername)
    return Registry.GetOwnerData(ownerUsername)
end

function Registry.GetOwnerUsernames()
    local owners = {}
    local index = ensureIndex()

    for _, summary in pairs(index.colonies or {}) do
        local owner = Config.GetOwnerUsername(summary and (summary.ownerUsername or summary.leaderUsername))
        if owner ~= "" then
            owners[#owners + 1] = owner
        end
    end

    table.sort(owners, function(a, b)
        return tostring(a or "") < tostring(b or "")
    end)

    return owners
end

function Registry.GetWorkerOwner(workerID)
    local colonyID = workerID and Runtime.workerToColonyID and Runtime.workerToColonyID[tostring(workerID)] or nil
    if not colonyID then
        return nil
    end

    local colonyData = ensureColonyData(colonyID, "local")
    return colonyData.ownerUsername
end

function Registry.GetWorkerColonyID(workerID)
    return workerID and Runtime.workerToColonyID and Runtime.workerToColonyID[tostring(workerID)] or nil
end

function Registry.GetSiteOwner(siteID)
    local colonyID = siteID and Runtime.siteToColonyID and Runtime.siteToColonyID[tostring(siteID)] or nil
    if not colonyID then
        return nil
    end

    local colonyData = ensureColonyData(colonyID, "local")
    return colonyData.ownerUsername
end

function Registry.GetSiteColonyID(siteID)
    return siteID and Runtime.siteToColonyID and Runtime.siteToColonyID[tostring(siteID)] or nil
end

function Registry.ForEachOwner(callback)
    if type(callback) ~= "function" then
        return
    end

    for _, ownerUsername in ipairs(Registry.GetOwnerUsernames()) do
        if callback(ownerUsername, Registry.EnsureOwner(ownerUsername)) == false then
            return
        end
    end
end

function Registry.ForEachWorkerRaw(callback)
    if type(callback) ~= "function" then
        return
    end

    Registry.ForEachOwner(function(ownerUsername, ownerData)
        for _, workerID in ipairs(ownerData.workerIDs or {}) do
            local worker = ownerData.workers[workerID]
            if worker then
                worker.ownerUsername = ownerUsername
                if callback(worker, ownerUsername, ownerData) == false then
                    return false
                end
            end
        end
        return true
    end)
end

function Registry.TouchColonyVersion(ownerOrColonyID)
    local colonyData = Registry.GetColonyData(ownerOrColonyID, true)
    if not colonyData then
        return 0
    end

    colonyData.versions.colony = math.max(1, math.floor(tonumber(colonyData.versions.colony) or 1)) + 1
    syncColonySummary(colonyData.colonyID)
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
    syncColonySummary(colonyData.colonyID)
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
    syncColonySummary(colonyData.colonyID)
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
    local key = getWorkerKey(colonyID, workerID)
    if ModData.remove and ModData.exists(key) then
        ModData.remove(key)
    else
        local data = ModData.get(key)
        if type(data) == "table" then
            clearTable(data)
        end
    end

    if Runtime.workerToColonyID then
        Runtime.workerToColonyID[tostring(workerID)] = nil
    end
end

Internal.EnsureModDataTable = ensureModDataTable
Internal.NormalizeWorkerData = normalizeWorkerData
Internal.RebuildRuntimeIndexes = rebuildRuntimeIndexes
Internal.GetColonyKey = getColonyKey
Internal.GetWorkersKey = getWorkersKey
Internal.GetWorkerKey = getWorkerKey
Internal.GetSitesKey = getSitesKey

return Registry
