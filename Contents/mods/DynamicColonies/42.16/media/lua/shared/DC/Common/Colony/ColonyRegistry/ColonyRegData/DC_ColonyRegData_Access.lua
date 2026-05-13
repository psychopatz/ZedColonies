DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Runtime = Internal.Runtime or {}
local Data = Internal.ColonyRegData or {}

function Registry.GetData()
    return Data.ensureIndex()
end

function Registry.GetIndexKey()
    return Data.getIndexKey()
end

function Registry.GetColonyIDForOwner(ownerUsername, createIfMissing)
    return Data.resolveColonyID(ownerUsername, createIfMissing == true)
end

function Registry.ResolveColonyID(ownerUsername, createIfMissing)
    return Data.resolveColonyID(ownerUsername, createIfMissing == true)
end

function Registry.GetColonyData(ownerOrColonyID, createIfMissing)
    local colonyID = Data.resolveColonyID(ownerOrColonyID, createIfMissing == true)
    if not colonyID then
        return nil
    end
    return Data.ensureColonyData(colonyID, ownerOrColonyID)
end

function Registry.GetWorkersData(ownerOrColonyID, createIfMissing)
    local colonyID = Data.resolveColonyID(ownerOrColonyID, createIfMissing == true)
    if not colonyID then
        return nil
    end
    return Data.ensureWorkersData(colonyID)
end

function Registry.GetSitesData(ownerOrColonyID, createIfMissing)
    local colonyID = Data.resolveColonyID(ownerOrColonyID, createIfMissing == true)
    if not colonyID then
        return nil
    end
    return Data.ensureSitesData(colonyID)
end

function Registry.GetWorkerData(colonyID, workerID)
    if not colonyID or not workerID then
        return nil
    end
    return Data.ensureWorkerData(colonyID, workerID, {})
end

function Registry.GetOwnerData(ownerUsername)
    local colonyID = Data.resolveColonyID(ownerUsername, true)
    return Data.buildOwnerView(colonyID)
end

function Registry.EnsureOwner(ownerUsername)
    return Registry.GetOwnerData(ownerUsername)
end

function Registry.GetOwnerUsernames()
    local owners = {}
    local index = Data.ensureIndex()

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

    local colonyData = Data.ensureColonyData(colonyID, "local")
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

    local colonyData = Data.ensureColonyData(colonyID, "local")
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

return Data