require "DC/Common/Colony/WorkerTransfer/DC_WorkerTransfer_Registry"

DC_Colony = DC_Colony or {}
DC_Colony.WorkerTransfer = DC_Colony.WorkerTransfer or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local WorkerTransfer = DC_Colony.WorkerTransfer

local function normalizeOwner(ownerUsername)
    if Config and Config.GetOwnerUsername then
        return Config.GetOwnerUsername(ownerUsername)
    end
    return tostring(ownerUsername or "local")
end

local function appendUnique(array, value)
    if not array or not value then
        return false
    end
    for _, existing in ipairs(array) do
        if tostring(existing) == tostring(value) then
            return false
        end
    end
    array[#array + 1] = value
    return true
end

local function removeValue(array, value)
    local removed = false
    for index = #(array or {}), 1, -1 do
        if tostring(array[index]) == tostring(value) then
            table.remove(array, index)
            removed = true
        end
    end
    return removed
end

local function isWorkerLiving(worker)
    local deadState = Config and Config.States and Config.States.Dead or "Dead"
    return type(worker) == "table" and worker.workerID ~= nil and tostring(worker.state or "") ~= tostring(deadState)
end

local function ensureFactionTables(faction)
    faction.linkedWorkerIDs = faction.linkedWorkerIDs or {}
    faction.tradeEligibleWorkerIDs = faction.tradeEligibleWorkerIDs or {}
    faction.activeTradeWorkerIDs = faction.activeTradeWorkerIDs or {}
    faction.tradeWorkerSouls = faction.tradeWorkerSouls or {}
    faction.workerContributionOwners = faction.workerContributionOwners or {}
    faction.retainedWorkerContributionOwners = faction.retainedWorkerContributionOwners or {}
end

local function clearFactionWorkerLinks(faction, workerID)
    removeValue(faction.linkedWorkerIDs, workerID)
    if faction.tradeEligibleWorkerIDs then faction.tradeEligibleWorkerIDs[workerID] = nil end
    if faction.activeTradeWorkerIDs then faction.activeTradeWorkerIDs[workerID] = nil end
    if faction.tradeWorkerSouls then faction.tradeWorkerSouls[workerID] = nil end
    if faction.workerContributionOwners then faction.workerContributionOwners[workerID] = nil end
end

function WorkerTransfer.AddOwnerWorkersToFaction(faction, joiningOwnerUsername)
    if type(faction) ~= "table" then
        return { moved = {} }
    end

    ensureFactionTables(faction)
    local sourceOwner = normalizeOwner(joiningOwnerUsername)
    local leader = normalizeOwner(faction.leaderUsername)
    local result = WorkerTransfer.MoveLivingWorkers(sourceOwner, leader, {
        contributionOwnerUsername = sourceOwner,
        jobEnabled = false
    })

    for _, moved in ipairs(result.moved or {}) do
        local workerID = moved.newWorkerID
        local worker = moved.worker
        if worker then
            worker.contributionOwnerUsername = sourceOwner
        end
        appendUnique(faction.linkedWorkerIDs, workerID)
        faction.workerContributionOwners[workerID] = sourceOwner
        faction.tradeEligibleWorkerIDs[workerID] = faction.tradeEligibleWorkerIDs[workerID] == true
        faction.activeTradeWorkerIDs[workerID] = nil
    end

    return result
end

function WorkerTransfer.ReturnContributorWorkers(faction, contributorUsername)
    if type(faction) ~= "table" then
        return { moved = {} }
    end

    ensureFactionTables(faction)
    local contributor = normalizeOwner(contributorUsername)
    local leader = normalizeOwner(faction.leaderUsername)
    local workerIDs = {}
    local targetColonyIDByWorker = {}

    for workerID, owner in pairs(faction.workerContributionOwners or {}) do
        if normalizeOwner(owner) == contributor then
            workerIDs[#workerIDs + 1] = workerID
            local worker = Registry and Registry.GetWorkerRaw and Registry.GetWorkerRaw(workerID) or nil
            if worker and worker.previousColonyID then
                targetColonyIDByWorker[tostring(workerID)] = worker.previousColonyID
            end
        end
    end

    local result = WorkerTransfer.MoveWorkersToOwner(leader, contributor, workerIDs, {
        targetColonyIDByWorker = targetColonyIDByWorker,
        jobEnabled = false
    })

    for _, moved in ipairs(result.moved or {}) do
        clearFactionWorkerLinks(faction, moved.oldWorkerID)
        if moved.worker then
            moved.worker.contributionOwnerUsername = nil
        end
    end

    return result
end

function WorkerTransfer.RetainContributorWorkers(faction, contributorUsername)
    if type(faction) ~= "table" then
        return { retained = 0 }
    end

    ensureFactionTables(faction)
    local contributor = normalizeOwner(contributorUsername)
    local workerIDs = {}
    local retained = 0

    for workerID, owner in pairs(faction.workerContributionOwners or {}) do
        if normalizeOwner(owner) == contributor then
            workerIDs[#workerIDs + 1] = workerID
        end
    end

    for _, workerID in ipairs(workerIDs) do
        faction.workerContributionOwners[workerID] = nil
        faction.retainedWorkerContributionOwners[workerID] = contributor
        local worker = Registry and Registry.GetWorkerRaw and Registry.GetWorkerRaw(workerID) or nil
        if worker then
            worker.contributionOwnerUsername = nil
            worker.retainedFromOwnerUsername = contributor
        end
        retained = retained + 1
    end

    if Registry and Registry.Save then
        Registry.Save()
    end

    return { retained = retained }
end

function WorkerTransfer.CountLivingLinkedWorkers(faction)
    local count = 0
    for _, workerID in ipairs(faction and faction.linkedWorkerIDs or {}) do
        local worker = Registry and Registry.GetWorkerRaw and Registry.GetWorkerRaw(workerID) or nil
        if isWorkerLiving(worker) then
            count = count + 1
        end
    end
    return count
end

return WorkerTransfer
