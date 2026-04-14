require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"

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

local function copyDeep(value)
    local internal = Registry and Registry.Internal or nil
    if internal and internal.CopyDeep then
        return internal.CopyDeep(value)
    end
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, child in pairs(value) do
        copy[key] = copyDeep(child)
    end
    return copy
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

local function clearTable(target)
    for key, _ in pairs(target or {}) do
        target[key] = nil
    end
end

local function workerExistsInColony(colonyID, workerID)
    local workersData = Registry.GetWorkersData(colonyID, false)
    for _, existingID in ipairs(workersData and workersData.workerIDs or {}) do
        if tostring(existingID) == tostring(workerID) then
            return true
        end
    end
    return false
end

local function reserveWorkerID(targetColonyID, preferredID)
    if preferredID and not workerExistsInColony(targetColonyID, preferredID) then
        return preferredID
    end
    local nextID = Registry.NextID and Registry.NextID("worker", targetColonyID) or nil
    while nextID and workerExistsInColony(targetColonyID, nextID) do
        nextID = Registry.NextID("worker", targetColonyID)
    end
    return nextID or (tostring(preferredID or "worker") .. "_" .. tostring(ZombRand(1000000)))
end

local function resetWorkerForTransfer(worker, targetOwner, targetColonyID, options)
    worker.ownerUsername = targetOwner
    worker.colonyID = targetColonyID
    worker.state = Config.States and Config.States.Idle or "Idle"
    worker.presenceState = Config.PresenceStates and Config.PresenceStates.Home or "Home"
    worker.assignedSiteID = nil
    worker.workX = nil
    worker.workY = nil
    worker.workZ = 0
    worker.travelHoursRemaining = 0
    worker.returnReason = nil
    worker.jobEnabled = options and options.jobEnabled == true
    worker.autoRepeatJob = false
    worker.autoRepeatScavenge = false
    worker.workProgress = 0
    worker.workTarget = nil
    worker.siteState = "Deferred"
    worker.toolState = worker.toolState or "Missing"
    worker.detailVersion = math.max(1, math.floor(tonumber(worker.detailVersion) or 1)) + 1
    if Registry.RecalculateWorker then
        Registry.RecalculateWorker(worker)
    end
end

local function updateSourceIndex(worker, workerID)
    local runtime = Registry.Internal and Registry.Internal.Runtime or nil
    if not (runtime and runtime.sourceNPCToWorkerID) then
        return
    end
    if worker and worker.sourceNPCID ~= nil and tostring(worker.sourceNPCID or "") ~= "" then
        runtime.sourceNPCToWorkerID[tostring(worker.sourceNPCID)] = workerID
    end
end

local function moveWorker(sourceColonyID, targetColonyID, sourceOwner, targetOwner, workerID, options)
    options = options or {}
    local sourceWorkers = Registry.GetWorkersData(sourceColonyID, false)
    local targetWorkers = Registry.GetWorkersData(targetColonyID, true)
    if not workerExistsInColony(sourceColonyID, workerID) then
        return nil
    end
    local sourceWorker = Registry.GetWorkerData(sourceColonyID, workerID)
    if type(sourceWorker) ~= "table" or not isWorkerLiving(sourceWorker) then
        return nil
    end

    local targetWorkerID = reserveWorkerID(targetColonyID, options.preferredWorkerID or workerID)
    local movedWorker = copyDeep(sourceWorker)
    movedWorker.previousWorkerID = movedWorker.previousWorkerID or workerID
    movedWorker.previousOwnerUsername = movedWorker.previousOwnerUsername or sourceOwner
    movedWorker.previousColonyID = movedWorker.previousColonyID or sourceColonyID
    movedWorker.workerID = targetWorkerID
    resetWorkerForTransfer(movedWorker, targetOwner, targetColonyID, options)

    local targetShard = Registry.GetWorkerData(targetColonyID, targetWorkerID)
    clearTable(targetShard)
    for key, value in pairs(movedWorker) do
        targetShard[key] = value
    end

    targetWorkers.workerIDs = targetWorkers.workerIDs or {}
    targetWorkers.summaries = targetWorkers.summaries or {}
    appendUnique(targetWorkers.workerIDs, targetWorkerID)
    if Registry.GetWorkerSummary then
        targetWorkers.summaries[targetWorkerID] = Registry.GetWorkerSummary(targetShard)
    end

    local targetHadPreferredID = workerExistsInColony(targetColonyID, workerID)

    removeValue(sourceWorkers.workerIDs, workerID)
    if sourceWorkers.summaries then
        sourceWorkers.summaries[workerID] = nil
    end
    Registry.RemoveWorkerShard(sourceColonyID, workerID)

    local runtime = Registry.Internal and Registry.Internal.Runtime or nil
    if runtime then
        runtime.workerToColonyID = runtime.workerToColonyID or {}
        if targetHadPreferredID then
            runtime.workerToColonyID[tostring(workerID)] = targetColonyID
        end
        runtime.workerToColonyID[tostring(targetWorkerID)] = targetColonyID
    end
    updateSourceIndex(targetShard, targetWorkerID)

    Registry.TouchWorkersVersion(sourceColonyID)
    Registry.TouchWorkersVersion(targetColonyID)

    return {
        oldWorkerID = workerID,
        newWorkerID = targetWorkerID,
        worker = targetShard,
        sourceColonyID = sourceColonyID,
        targetColonyID = targetColonyID
    }
end

function WorkerTransfer.MoveLivingWorkers(sourceOwnerUsername, targetOwnerUsername, options)
    options = options or {}
    local sourceOwner = normalizeOwner(sourceOwnerUsername)
    local targetOwner = normalizeOwner(targetOwnerUsername)
    local sourceColonyID = options.sourceColonyID or (Registry.GetColonyIDForOwner and Registry.GetColonyIDForOwner(sourceOwner, false))
    local targetColonyID = options.targetColonyID or (Registry.GetColonyIDForOwner and Registry.GetColonyIDForOwner(targetOwner, true))
    local result = {
        moved = {},
        oldToNew = {},
        sourceOwner = sourceOwner,
        targetOwner = targetOwner,
        sourceColonyID = sourceColonyID,
        targetColonyID = targetColonyID
    }

    if not (sourceColonyID and targetColonyID) or tostring(sourceColonyID) == tostring(targetColonyID) then
        return result
    end

    local sourceWorkers = Registry.GetWorkersData(sourceColonyID, false)
    local ids = copyDeep(sourceWorkers and sourceWorkers.workerIDs or {})
    for _, workerID in ipairs(ids) do
        local worker = Registry.GetWorkerData(sourceColonyID, workerID)
        if isWorkerLiving(worker) then
            local moved = moveWorker(sourceColonyID, targetColonyID, sourceOwner, targetOwner, workerID, options)
            if moved then
                result.moved[#result.moved + 1] = moved
                result.oldToNew[tostring(workerID)] = moved.newWorkerID
            end
        end
    end

    if Registry.Save then
        Registry.Save()
    end
    return result
end

function WorkerTransfer.MoveWorkersToOwner(sourceOwnerUsername, targetOwnerUsername, workerIDs, options)
    options = options or {}
    local sourceOwner = normalizeOwner(sourceOwnerUsername)
    local targetOwner = normalizeOwner(targetOwnerUsername)
    local sourceColonyID = options.sourceColonyID or (Registry.GetColonyIDForOwner and Registry.GetColonyIDForOwner(sourceOwner, false))
    local result = {
        moved = {},
        oldToNew = {},
        sourceOwner = sourceOwner,
        targetOwner = targetOwner,
        sourceColonyID = sourceColonyID
    }

    if not sourceColonyID then
        return result
    end

    for _, workerID in ipairs(workerIDs or {}) do
        local sourceWorker = Registry.GetWorkerData(sourceColonyID, workerID)
        local targetColonyID = options.targetColonyID
        if not targetColonyID and type(options.targetColonyIDByWorker) == "table" then
            targetColonyID = options.targetColonyIDByWorker[tostring(workerID)]
        end
        targetColonyID = targetColonyID or (sourceWorker and sourceWorker.previousColonyID) or Registry.GetColonyIDForOwner(targetOwner, true)

        if targetColonyID and tostring(targetColonyID) ~= tostring(sourceColonyID) then
            local moveOptions = copyDeep(options)
            moveOptions.preferredWorkerID = moveOptions.preferredWorkerID
                or (sourceWorker and sourceWorker.previousWorkerID)
                or workerID
            local moved = moveWorker(sourceColonyID, targetColonyID, sourceOwner, targetOwner, workerID, moveOptions)
            if moved then
                result.targetColonyID = result.targetColonyID or moved.targetColonyID
                result.moved[#result.moved + 1] = moved
                result.oldToNew[tostring(workerID)] = moved.newWorkerID
            end
        end
    end

    if Registry.Save then
        Registry.Save()
    end
    return result
end

return WorkerTransfer
