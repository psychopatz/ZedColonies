DC_Colony = DC_Colony or {}
DC_Colony.ResidentBridge = DC_Colony.ResidentBridge or {}

local Bridge = DC_Colony.ResidentBridge
local Internal = Bridge.Internal or {}

local function logResident(message)
    if DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DColony", "Resident", "Bridge", tostring(message or ""))
    end
end

local function nowMillis()
    if getTimeInMillis then
        local value = tonumber(getTimeInMillis())
        if value and value > 0 then
            return math.floor(value)
        end
    end

    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        return math.floor((tonumber(gameTime:getWorldAgeHours()) or 0) * 3600000)
    end

    return 0
end

Bridge.SyncFailureState = Bridge.SyncFailureState or {}
Bridge.SYNC_FAILURE_RETRY_MS = Bridge.SYNC_FAILURE_RETRY_MS or 5000

local function fallbackEnqueueWorker(worker)
    if type(worker) ~= "table" then
        return false
    end

    local workerID = tostring(worker.workerID or "")
    if workerID == "" then
        return false
    end

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

    if Bridge.SyncQueue.byWorkerID[workerID] == true then
        return false
    end

    Bridge.SyncQueue.byWorkerID[workerID] = true
    Bridge.SyncQueue.order[#Bridge.SyncQueue.order + 1] = workerID
    Bridge.SyncDebugStats = Bridge.SyncDebugStats or {}
    Bridge.SyncDebugStats.queuedWorkers = (tonumber(Bridge.SyncDebugStats.queuedWorkers) or 0) + 1
    return true
end

local function copyPointToWorker(worker, fieldPrefix, point)
    if type(worker) ~= "table" or not Internal.HasPoint(point) then
        return false
    end

    local xKey = tostring(fieldPrefix) .. "X"
    local yKey = tostring(fieldPrefix) .. "Y"
    local zKey = tostring(fieldPrefix) .. "Z"
    local nextX = math.floor(tonumber(point.x) or 0)
    local nextY = math.floor(tonumber(point.y) or 0)
    local nextZ = math.floor(tonumber(point.z) or 0)
    local changed = worker[xKey] ~= nextX or worker[yKey] ~= nextY or worker[zKey] ~= nextZ
    worker[xKey] = nextX
    worker[yKey] = nextY
    worker[zKey] = nextZ
    return changed
end

local function chooseFallbackHome(anchorSnapshot, existingSoul)
    if anchorSnapshot and Internal.HasPoint(anchorSnapshot.home) then
        return Internal.CopyPoint(anchorSnapshot.home)
    end

    if existingSoul and Internal.HasPoint(existingSoul.homeCoords) then
        return Internal.CopyPoint(existingSoul.homeCoords)
    end

    return nil
end

local function chooseFallbackWork(anchorSnapshot, existingSoul, fallbackHome)
    if anchorSnapshot and Internal.HasPoint(anchorSnapshot.work) then
        return Internal.CopyPoint(anchorSnapshot.work)
    end

    if existingSoul and Internal.HasPoint(existingSoul.workCoords) then
        return Internal.CopyPoint(existingSoul.workCoords)
    end

    return Internal.CopyPoint(fallbackHome)
end

local function buildAnchorSignature(anchorSnapshot, existingUUID)
    anchorSnapshot = type(anchorSnapshot) == "table" and anchorSnapshot or {}
    local home = anchorSnapshot.home or {}
    local work = anchorSnapshot.work or {}
    return table.concat({
        tostring(existingUUID or ""),
        tostring(home.x or ""),
        tostring(home.y or ""),
        tostring(home.z or ""),
        tostring(work.x or ""),
        tostring(work.y or ""),
        tostring(work.z or ""),
        tostring(anchorSnapshot.homeMode or ""),
        tostring(anchorSnapshot.workMode or ""),
    }, "|")
end

local function getSyncSignature(worker, npcData)
    return table.concat({
        tostring(worker and worker.workerID or ""),
        tostring(worker and worker.name or ""),
        tostring(worker and worker.isFemale == true),
        tostring(worker and worker.identitySeed or ""),
        tostring(worker and worker.visualID or ""),
        tostring(worker and worker.archetypeID or ""),
        tostring(worker and worker.ownerUsername or ""),
        tostring(worker and worker.homeX or ""),
        tostring(worker and worker.homeY or ""),
        tostring(worker and worker.homeZ or ""),
        tostring(worker and worker.workX or ""),
        tostring(worker and worker.workY or ""),
        tostring(worker and worker.workZ or ""),
        tostring(worker and worker.dcDutyMode or ""),
        tostring(worker and worker.dcCanFight == true),
        tostring(worker and worker.dcGuardPostIndex or ""),
        tostring(worker and worker.dcAnchorRevision or ""),
        tostring(worker and worker.dcBehaviorState or ""),
        tostring(worker and worker.guardEngageRadius or ""),
        tostring(worker and worker.guardLeashRadius or ""),
        tostring(worker and worker.dcPatrolPauseMinMs or ""),
        tostring(worker and worker.dcPatrolPauseMaxMs or ""),
        tostring(worker and worker.dcPatrolMoveGapMinMs or ""),
        tostring(worker and worker.dcPatrolMoveGapMaxMs or ""),
        tostring(npcData and npcData.factionID or ""),
        tostring(npcData and npcData.dcResidentRole or ""),
        tostring(npcData and npcData.dcResidentHomeMode or ""),
        tostring(npcData and npcData.dcResidentWorkMode or ""),
        tostring(npcData and npcData.state or ""),
        tostring(npcData and npcData.status or ""),
        tostring(npcData and npcData.lastX or ""),
        tostring(npcData and npcData.lastY or ""),
        tostring(npcData and npcData.lastZ or ""),
    }, "|")
end

function Bridge.QueueWorkerSync(worker)
    if Bridge.EnsureSyncQueueHook then
        Bridge.EnsureSyncQueueHook()
    end

    if Internal.EnqueueWorker then
        return Internal.EnqueueWorker(worker)
    end

    return fallbackEnqueueWorker(worker)
end

local function setResidentFields(worker, npcData, anchorSnapshot)
    npcData.dcResident = true
    npcData.dcResidentOwnerUsername = tostring(worker.ownerUsername or npcData.ownerUsername or "")
    npcData.dcResidentColonyId = tostring(worker.colonyID or npcData.dcResidentColonyId or "")
    npcData.dcResidentWorkerID = tostring(worker.workerID or npcData.dcResidentWorkerID or "")
    npcData.dcResidentRole = Internal.GetResidentRole(worker)
    npcData.dcResidentHomeMode = tostring(anchorSnapshot and anchorSnapshot.homeMode or "base")
    npcData.dcResidentWorkMode = tostring(anchorSnapshot and anchorSnapshot.workMode or "base")
    npcData.abstractResident = false
end

local function applyWorkerIdentity(worker, npcData)
    local factionID = Internal.ResolvePlayerFactionID and Internal.ResolvePlayerFactionID(worker.ownerUsername) or nil
    npcData.name = worker.name or npcData.name
    npcData.isFemale = worker.isFemale
    npcData.identitySeed = worker.identitySeed or npcData.identitySeed
    npcData.visualID = worker.visualID or npcData.visualID
    npcData.archetypeID = worker.archetypeID or npcData.archetypeID or worker.profession or "General"
    npcData.ownerUsername = worker.ownerUsername
    npcData.linkedWorkerID = worker.workerID
    npcData.isPlayerFactionTrader = false
    npcData.factionID = factionID or "Independent"
end

local function applyWorkerRuntime(worker, npcData, homeCoords, workCoords)
    local defense = Internal.GetDefense and Internal.GetDefense() or nil
    local runtime = defense and defense.BuildWorkerRuntime and defense.BuildWorkerRuntime(worker, homeCoords, workCoords) or nil
    if type(runtime) ~= "table" then
        return false
    end

    local changed = false
    if tostring(worker.dcDutyMode or "") ~= tostring(runtime.dcDutyMode or "idle") then
        changed = true
    end
    if (worker.dcCanFight == true) ~= (runtime.dcCanFight == true) then
        changed = true
    end
    if math.max(1, math.floor(tonumber(worker.dcGuardPostIndex) or 1)) ~= math.max(1, math.floor(tonumber(runtime.dcGuardPostIndex) or 1)) then
        changed = true
    end
    if tostring(worker.dcAnchorRevision or "") ~= tostring(runtime.dcAnchorRevision or "") then
        changed = true
    end
    if tostring(worker.dcBehaviorState or "") ~= tostring(runtime.dcBehaviorState or "") then
        changed = true
    end
    if math.floor(tonumber(worker.guardEngageRadius) or 0) ~= math.floor(tonumber(runtime.guardEngageRadius) or 0) then
        changed = true
    end
    if math.floor(tonumber(worker.guardLeashRadius) or 0) ~= math.floor(tonumber(runtime.guardLeashRadius) or 0) then
        changed = true
    end
    if math.floor(tonumber(worker.dcPatrolPauseMinMs) or 0) ~= math.floor(tonumber(runtime.dcPatrolPauseMinMs) or 0) then
        changed = true
    end
    if math.floor(tonumber(worker.dcPatrolPauseMaxMs) or 0) ~= math.floor(tonumber(runtime.dcPatrolPauseMaxMs) or 0) then
        changed = true
    end
    if math.floor(tonumber(worker.dcPatrolMoveGapMinMs) or 0) ~= math.floor(tonumber(runtime.dcPatrolMoveGapMinMs) or 0) then
        changed = true
    end
    if math.floor(tonumber(worker.dcPatrolMoveGapMaxMs) or 0) ~= math.floor(tonumber(runtime.dcPatrolMoveGapMaxMs) or 0) then
        changed = true
    end

    worker.dcDutyMode = tostring(runtime.dcDutyMode or worker.dcDutyMode or "idle")
    worker.dcCanFight = runtime.dcCanFight == true
    worker.dcGuardPostIndex = math.max(1, math.floor(tonumber(runtime.dcGuardPostIndex) or tonumber(worker.dcGuardPostIndex) or 1))
    worker.dcAnchorRevision = tostring(runtime.dcAnchorRevision or worker.dcAnchorRevision or "")
    worker.dcBehaviorState = tostring(runtime.dcBehaviorState or worker.dcBehaviorState or "ColonyIdle")
    worker.guardEngageRadius = math.max(0, math.floor(tonumber(runtime.guardEngageRadius) or tonumber(worker.guardEngageRadius) or 0))
    worker.guardLeashRadius = math.max(0, math.floor(tonumber(runtime.guardLeashRadius) or tonumber(worker.guardLeashRadius) or 0))
    worker.dcPatrolPauseMinMs = math.max(0, math.floor(tonumber(runtime.dcPatrolPauseMinMs) or tonumber(worker.dcPatrolPauseMinMs) or 0))
    worker.dcPatrolPauseMaxMs = math.max(0, math.floor(tonumber(runtime.dcPatrolPauseMaxMs) or tonumber(worker.dcPatrolPauseMaxMs) or 0))
    worker.dcPatrolMoveGapMinMs = math.max(0, math.floor(tonumber(runtime.dcPatrolMoveGapMinMs) or tonumber(worker.dcPatrolMoveGapMinMs) or 0))
    worker.dcPatrolMoveGapMaxMs = math.max(0, math.floor(tonumber(runtime.dcPatrolMoveGapMaxMs) or tonumber(worker.dcPatrolMoveGapMaxMs) or 0))

    npcData.dcDutyMode = worker.dcDutyMode
    npcData.dcCanFight = worker.dcCanFight == true
    npcData.dcGuardPostIndex = worker.dcGuardPostIndex
    npcData.dcAnchorRevision = worker.dcAnchorRevision
    npcData.dcBehaviorState = worker.dcBehaviorState
    npcData.dcResidentJobType = tostring(worker.jobType or npcData.dcResidentJobType or "")
    npcData.guardEngageRadius = worker.guardEngageRadius
    npcData.guardLeashRadius = worker.guardLeashRadius
    npcData.dcPatrolPauseMinMs = worker.dcPatrolPauseMinMs
    npcData.dcPatrolPauseMaxMs = worker.dcPatrolPauseMaxMs
    npcData.dcPatrolMoveGapMinMs = worker.dcPatrolMoveGapMinMs
    npcData.dcPatrolMoveGapMaxMs = worker.dcPatrolMoveGapMaxMs
    return changed
end

local function applyCompanionDerivedData(worker, npcData)
    local companionInternal = Internal.GetCompanionInternal()
    if not companionInternal then
        return
    end

    if companionInternal.BuildLoadoutFromWorker then
        npcData.loadout = companionInternal.BuildLoadoutFromWorker(worker)
    end
    if companionInternal.BuildHealthSeed then
        companionInternal.BuildHealthSeed(worker, npcData)
    end

    if Internal.IsTravelCompanionWorker(worker) and companionInternal.SetSoulCompanionFlags then
        local config = Internal.GetConfig()
        local activeState = config and config.PresenceStates and config.PresenceStates.CompanionActive or "CompanionActive"
        companionInternal.SetSoulCompanionFlags(worker, npcData, tostring(worker.presenceState or "") == tostring(activeState))
    elseif not Internal.IsTravelCompanionWorker(worker) then
        npcData.dcCompanionActive = false
        npcData.dcCompanionStage = nil
    end
end

local function applyResidentPosition(worker, npcData, homeCoords, workCoords)
    local config = Internal.GetConfig()
    local states = config and config.States or {}
    local presenceStates = config and config.PresenceStates or {}
    local presenceState = tostring(worker.presenceState or "")
    local state = tostring(worker.state or "")

    if Internal.IsTravelCompanionWorker(worker)
        and presenceState ~= tostring(presenceStates.Home or "Home") then
        return
    end

    local dutyMode = tostring(worker.dcDutyMode or npcData.dcDutyMode or "")
    local useWork = (dutyMode == "work" or dutyMode == "patient" or dutyMode == "guard")
        and Internal.HasPoint(workCoords)
    if dutyMode == "" then
        useWork = state ~= tostring(states.Resting or "Resting")
            and state ~= tostring(states.Idle or "Idle")
            and state ~= tostring(states.Incapacitated or "Incapacitated")
            and Internal.HasPoint(workCoords)
    end
    local anchor = useWork and workCoords or homeCoords

    if not Internal.HasPoint(anchor) then
        return
    end

    if dutyMode == "guard" or dutyMode == "work" or dutyMode == "patient" then
        npcData.status = "Working"
    else
        npcData.status = "Resting"
    end
    npcData.returnTime = 0
    npcData.returnStatus = nil
    npcData.lastX = math.floor(tonumber(anchor.x) or 0)
    npcData.lastY = math.floor(tonumber(anchor.y) or 0)
    npcData.lastZ = math.floor(tonumber(anchor.z) or 0)
    npcData.state = tostring(worker.dcBehaviorState or npcData.dcBehaviorState or (useWork and "ColonyWork" or "ColonyIdle"))
end

local function ensureResidentSoul(worker, homeCoords)
    if not DynamicTrading_Roster or not DynamicTrading_Roster.AddSoul or not Internal.HasPoint(homeCoords) then
        return nil
    end

    local uuid = DynamicTrading_Roster.AddSoul(
        "Independent",
        worker.archetypeID or worker.profession or "General",
        homeCoords,
        {
            forceFaction = true,
            suppressRecruitLog = true
        }
    )
    if not uuid then
        return nil
    end

    worker.residentSoulUUID = uuid
    if Internal.IsTravelCompanionWorker(worker) then
        local companionData = Internal.GetCompanionData(worker)
        if companionData then
            companionData.uuid = companionData.uuid or uuid
        end
    end

    return uuid
end

function Bridge.SyncWorker(worker)
    if not Internal.IsAuthority() or not Internal.IsWorkerLiving(worker) then
        return false, nil
    end

    local anchorSnapshot = Bridge.BuildAnchorSnapshot(worker)
    local existingUUID, existingSoul = Internal.FindResidentSoul(worker)
    local workerID = tostring(worker.workerID or "")
    local anchorSignature = buildAnchorSignature(anchorSnapshot, existingUUID)
    local failureState = Bridge.SyncFailureState[workerID]
    if type(failureState) == "table"
        and tostring(failureState.anchorSignature or "") == anchorSignature
        and (tonumber(failureState.retryAt) or 0) > nowMillis() then
        Bridge.SyncDebugStats.backoffHits = (tonumber(Bridge.SyncDebugStats.backoffHits) or 0) + 1
        return false, existingUUID
    end

    local homeCoords = chooseFallbackHome(anchorSnapshot, existingSoul)
    local workCoords = chooseFallbackWork(anchorSnapshot, existingSoul, homeCoords)
    if not Internal.HasPoint(homeCoords) then
        local currentTime = nowMillis()
        failureState = failureState or {}
        failureState.anchorSignature = anchorSignature
        failureState.retryAt = currentTime + math.max(500, math.floor(tonumber(Bridge.SYNC_FAILURE_RETRY_MS) or 5000))
        local shouldLog = (tonumber(failureState.lastLogAt) or 0) <= 0
            or (currentTime - math.max(0, tonumber(failureState.lastLogAt) or 0)) >= math.max(500, math.floor(tonumber(Bridge.SYNC_FAILURE_RETRY_MS) or 5000))
        if shouldLog then
            failureState.lastLogAt = currentTime
            logResident("Skipping resident sync; no valid home coords for workerID=" .. tostring(worker and worker.workerID))
        end
        Bridge.SyncFailureState[workerID] = failureState
        return false, nil
    end
    Bridge.SyncFailureState[workerID] = nil

    local workerChanged = false
    workerChanged = copyPointToWorker(worker, "home", homeCoords) or workerChanged
    if Internal.HasPoint(workCoords) then
        workerChanged = copyPointToWorker(worker, "work", workCoords) or workerChanged
    end

    local uuid = existingUUID
    local npcData = existingSoul
    if not uuid then
        uuid = ensureResidentSoul(worker, homeCoords)
        if not uuid or not DynamicTrading_Roster or not DynamicTrading_Roster.GetSoul then
            return workerChanged, nil
        end
        npcData = DynamicTrading_Roster.GetSoul(uuid)
        workerChanged = true
    end

    if type(npcData) ~= "table" then
        return workerChanged, uuid
    end

    applyWorkerIdentity(worker, npcData)
    setResidentFields(worker, npcData, anchorSnapshot)
    npcData.homeCoords = homeCoords
    npcData.workCoords = workCoords or npcData.workCoords or homeCoords
    workerChanged = applyWorkerRuntime(worker, npcData, homeCoords, workCoords) == true or workerChanged
    applyResidentPosition(worker, npcData, homeCoords, workCoords)
    applyCompanionDerivedData(worker, npcData)

    local syncSignature = getSyncSignature(worker, npcData)
    if tostring(worker._dtResidentSyncSignature or "") == syncSignature
        and tostring(worker.residentSoulUUID or "") == tostring(uuid or "") then
        return workerChanged, uuid
    end

    if DynamicTrading_Roster and DynamicTrading_Roster.SaveSoul then
        DynamicTrading_Roster.SaveSoul(uuid, npcData)
    end

    if DTNPCServerCore and DTNPCServerCore.UpdateNPCByUUID then
        DTNPCServerCore.UpdateNPCByUUID(uuid, {
            factionID = npcData.factionID,
            ownerUsername = npcData.ownerUsername,
            linkedWorkerID = npcData.linkedWorkerID,
            dcResident = npcData.dcResident,
            dcResidentOwnerUsername = npcData.dcResidentOwnerUsername,
            dcResidentColonyId = npcData.dcResidentColonyId,
            dcResidentWorkerID = npcData.dcResidentWorkerID,
            dcResidentRole = npcData.dcResidentRole,
            dcResidentHomeMode = npcData.dcResidentHomeMode,
            dcResidentWorkMode = npcData.dcResidentWorkMode,
            abstractResident = npcData.abstractResident,
            status = npcData.status,
            state = npcData.state,
            homeCoords = npcData.homeCoords,
            workCoords = npcData.workCoords,
            lastX = npcData.lastX,
            lastY = npcData.lastY,
            lastZ = npcData.lastZ,
            dcDutyMode = npcData.dcDutyMode,
            dcCanFight = npcData.dcCanFight == true,
            dcGuardPostIndex = npcData.dcGuardPostIndex,
            dcAnchorRevision = npcData.dcAnchorRevision,
            dcBehaviorState = npcData.dcBehaviorState,
            guardEngageRadius = npcData.guardEngageRadius,
            guardLeashRadius = npcData.guardLeashRadius,
            dcPatrolPauseMinMs = npcData.dcPatrolPauseMinMs,
            dcPatrolPauseMaxMs = npcData.dcPatrolPauseMaxMs,
            dcPatrolMoveGapMinMs = npcData.dcPatrolMoveGapMinMs,
            dcPatrolMoveGapMaxMs = npcData.dcPatrolMoveGapMaxMs,
        }, true)
    end

    if worker.residentSoulUUID ~= uuid then
        worker.residentSoulUUID = uuid
        workerChanged = true
    end
    worker._dtResidentSyncSignature = syncSignature

    return workerChanged, uuid
end

function Bridge.RemoveWorker(worker)
    if not Internal.IsAuthority() or type(worker) ~= "table" then
        return false
    end

    local uuid = tostring(worker.residentSoulUUID or Internal.GetCompanionUUID(worker) or "")
    if uuid == "" then
        return false
    end

    if DTNPCManager and DTNPCManager.RemoveData then
        DTNPCManager.RemoveData(uuid, nil, nil, nil, "resident-worker-removed")
    end
    if DynamicTrading_Roster and DynamicTrading_Roster.RemoveSpecificSoul then
        DynamicTrading_Roster.RemoveSpecificSoul(uuid)
    end

    worker.residentSoulUUID = nil
    local companionData = Internal.GetCompanionData(worker)
    if companionData and tostring(companionData.uuid or "") == uuid then
        companionData.uuid = nil
    end

    return true
end

return Bridge
