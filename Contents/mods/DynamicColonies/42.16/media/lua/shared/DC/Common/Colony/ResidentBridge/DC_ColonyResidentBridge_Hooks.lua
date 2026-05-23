DC_Colony = DC_Colony or {}
DC_Colony.ResidentBridge = DC_Colony.ResidentBridge or {}

local Bridge = DC_Colony.ResidentBridge
local Internal = Bridge.Internal or {}

Bridge.SyncQueue = Bridge.SyncQueue or {
    order = {},
    byWorkerID = {},
    saveQueued = false,
    spawnCheckQueued = false,
    ticksSinceSave = 0,
    ticksSinceSpawnCheck = 0,
}
Bridge.SYNC_QUEUE_BATCH_SIZE = Bridge.SYNC_QUEUE_BATCH_SIZE or 3
Bridge.SyncDebugStats = Bridge.SyncDebugStats or {
    queuedWorkers = 0,
    processedWorkers = 0,
    syncRuns = 0,
    saves = 0,
    rosterFlushes = 0,
}

local function getSyncQueue()
    Bridge.SyncQueue = Bridge.SyncQueue or {
        order = {},
        byWorkerID = {},
        saveQueued = false,
        spawnCheckQueued = false,
        ticksSinceSave = 0,
        ticksSinceSpawnCheck = 0,
    }
    Bridge.SyncQueue.order = type(Bridge.SyncQueue.order) == "table" and Bridge.SyncQueue.order or {}
    Bridge.SyncQueue.byWorkerID = type(Bridge.SyncQueue.byWorkerID) == "table" and Bridge.SyncQueue.byWorkerID or {}
    return Bridge.SyncQueue
end

local function enqueueWorker(worker)
    if type(worker) ~= "table" then
        return false
    end
    local workerID = tostring(worker.workerID or "")
    if workerID == "" then
        return false
    end

    local queue = getSyncQueue()
    if queue.byWorkerID[workerID] == true then
        return false
    end

    queue.byWorkerID[workerID] = true
    queue.order[#queue.order + 1] = workerID
    Bridge.SyncDebugStats.queuedWorkers = (tonumber(Bridge.SyncDebugStats.queuedWorkers) or 0) + 1
    return true
end

function Bridge.GetSyncQueueDepth()
    local queue = getSyncQueue()
    return #queue.order
end

function Bridge.GetSyncDebugStats()
    local queue = getSyncQueue()
    local stats = Bridge.SyncDebugStats or {}
    return {
        queueDepth = #queue.order,
        queuedWorkers = tonumber(stats.queuedWorkers) or 0,
        processedWorkers = tonumber(stats.processedWorkers) or 0,
        syncRuns = tonumber(stats.syncRuns) or 0,
        saves = tonumber(stats.saves) or 0,
        rosterFlushes = tonumber(stats.rosterFlushes) or 0,
    }
end

function Bridge.EnsureSyncQueueHook()
    if Bridge._syncQueueTickHooked == true then
        return true
    end
    if Events and Events.OnTick and Events.OnTick.Add then
        Events.OnTick.Add(Bridge.ProcessSyncQueue)
        Bridge._syncQueueTickHooked = true
        return true
    end
    return false
end

function Bridge.OnWorkerStateApplied(worker)
    local changed = false
    if not Internal.IsAuthority() or type(worker) ~= "table" then
        return changed
    end

    changed = Bridge.SyncWorker(worker) == true or false
    if changed then
        local registry = Internal.GetRegistry()
        local persistedWorker = registry and registry.GetWorkerRaw and registry.GetWorkerRaw(worker.workerID) or nil
        if registry and registry.Save and persistedWorker == worker then
            registry.Save()
        end
    end

    return changed
end

function Bridge.ProcessSyncQueue()
    if not Internal.IsAuthority() then
        return false
    end

    local queue = getSyncQueue()
    local registry = Internal.GetRegistry()
    if not registry or not registry.GetWorkerRaw then
        return false
    end

    if #queue.order <= 0 and queue.saveQueued ~= true and queue.spawnCheckQueued ~= true then
        return false
    end

    local budget = math.max(1, tonumber(Bridge.SYNC_QUEUE_BATCH_SIZE) or 3)
    local processed = 0
    local changed = false
    local stats = Bridge.SyncDebugStats
    stats.syncRuns = (tonumber(stats.syncRuns) or 0) + 1

    while processed < budget and #queue.order > 0 do
        local workerID = table.remove(queue.order, 1)
        queue.byWorkerID[tostring(workerID or "")] = nil
        processed = processed + 1
        stats.processedWorkers = (tonumber(stats.processedWorkers) or 0) + 1

        local worker = registry.GetWorkerRaw(workerID)
        if worker then
            if registry.RecalculateWorker then
                registry.RecalculateWorker(worker)
            end
            changed = Bridge.SyncWorker(worker) == true or changed
        end
    end

    if changed then
        queue.saveQueued = true
        queue.spawnCheckQueued = true
    end

    if queue.saveQueued == true then
        queue.ticksSinceSave = math.max(0, tonumber(queue.ticksSinceSave) or 0) + 1
        if (#queue.order == 0 or queue.ticksSinceSave >= 10) and registry.Save then
            registry.Save()
            stats.saves = (tonumber(stats.saves) or 0) + 1
            queue.saveQueued = false
            queue.ticksSinceSave = 0
        end
    else
        queue.ticksSinceSave = 0
    end

    if queue.spawnCheckQueued == true then
        queue.ticksSinceSpawnCheck = math.max(0, tonumber(queue.ticksSinceSpawnCheck) or 0) + 1
        if #queue.order == 0 or queue.ticksSinceSpawnCheck >= 10 then
            if DTNPCManager and DTNPCManager.CheckRosterSpawns then
                DTNPCManager.CheckRosterSpawns()
                stats.rosterFlushes = (tonumber(stats.rosterFlushes) or 0) + 1
            end
            queue.spawnCheckQueued = false
            queue.ticksSinceSpawnCheck = 0
        end
    else
        queue.ticksSinceSpawnCheck = 0
    end

    return changed
end

function Bridge.RefreshOwnerWorkers(ownerUsername)
    if not Internal.IsAuthority() then
        return false
    end
    Bridge.EnsureSyncQueueHook()

    local registry = Internal.GetRegistry()
    if not registry or not registry.GetWorkersForOwnerRaw then
        return false
    end

    local enqueued = false
    for _, worker in ipairs(registry.GetWorkersForOwnerRaw(ownerUsername) or {}) do
        enqueued = enqueueWorker(worker) == true or enqueued
    end

    return enqueued
end

function Bridge.ShouldKeepHomeResidentBody(worker)
    if not Internal.IsAuthority() or type(worker) ~= "table" then
        return false
    end

    local uuid = tostring(worker.residentSoulUUID or Internal.GetCompanionUUID(worker) or "")
    if uuid == "" then
        return false
    end

    local homeCoords = {
        x = worker.homeX,
        y = worker.homeY,
        z = worker.homeZ or 0
    }
    if not Internal.HasPoint(homeCoords) then
        return false
    end

    if DTNPC_ColonyResidents and DTNPC_ColonyResidents.IsLiveResidentAtHome then
        return DTNPC_ColonyResidents.IsLiveResidentAtHome(uuid, homeCoords, 8) == true
    end

    return false
end

Bridge.EnsureSyncQueueHook()

return Bridge
