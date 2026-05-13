DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Runtime = Internal.Runtime or {}
local Data = Internal.ColonyRegData or {}

function Data.syncColonySummary(colonyID)
    local index = Data.ensureIndex()
    local colonyData = Data.ensureColonyData(colonyID, "local")
    local workersData = Data.ensureWorkersData(colonyID)
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

function Data.rebuildRuntimeIndexes()
    Runtime.workerToColonyID = {}
    Runtime.siteToColonyID = {}
    Runtime.sourceNPCToWorkerID = {}

    local index = Data.ensureIndex()
    for colonyID, summary in pairs(index.colonies or {}) do
        local colonyData = Data.ensureColonyData(colonyID, summary and summary.ownerUsername or "local")
        local workersData = Data.ensureWorkersData(colonyID)
        local sitesData = Data.ensureSitesData(colonyID)

        for _, workerID in ipairs(workersData.workerIDs or {}) do
            local worker = Data.ensureWorkerData(colonyID, workerID, {})
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

        Data.syncColonySummary(colonyID)
    end
end

function Data.resolveColonyID(ownerUsername, createIfMissing)
    local index = Data.ensureIndex()
    if ownerUsername ~= nil and index.colonies[tostring(ownerUsername)] then
        return tostring(ownerUsername)
    end

    local owner = Data.getAuthorityOwner(ownerUsername)
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
    Data.ensureColonyData(colonyID, owner)
    Data.ensureWorkersData(colonyID)
    Data.ensureSitesData(colonyID)
    index.playerToColonyID[owner] = colonyID
    Data.syncColonySummary(colonyID)
    return colonyID
end

function Data.buildOwnerView(colonyID)
    local colonyData = Data.ensureColonyData(colonyID, "local")
    local workersData = Data.ensureWorkersData(colonyID)
    local sitesData = Data.ensureSitesData(colonyID)
    local workers = {}

    for _, workerID in ipairs(workersData.workerIDs or {}) do
        local worker = Data.ensureWorkerData(colonyID, workerID, {})
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
    Data.ensureIndex()
    Data.rebuildRuntimeIndexes()
end

Events.OnInitGlobalModData.Add(Registry.Init)

Internal.RebuildRuntimeIndexes = Data.rebuildRuntimeIndexes

return Data