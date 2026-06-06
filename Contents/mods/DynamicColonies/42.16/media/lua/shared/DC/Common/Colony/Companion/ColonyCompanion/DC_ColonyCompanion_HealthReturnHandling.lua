DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.HandleIncapacitatedNPC(npcData)
    local workerID = npcData and npcData.linkedWorkerID or nil
    local registry = Internal.GetRegistry()
    local worker = workerID and registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false
    end

    Internal.SyncWorkerHealthFromNPC(worker.workerID, npcData)
    worker.state = Config.States.Incapacitated
    worker.jobEnabled = false
    local companionData = Internal.GetCompanionData(worker)
    companionData.awaitingDespawn = false
    companionData.stage = Internal.Constants.TRAVEL_STAGE_RETURNING
    companionData.homeRecoveryLogged = false
    worker.presenceState = Config.PresenceStates.CompanionReturning
    worker.travelHoursRemaining = Internal.GetTravelHours()
    worker.returnReason = Config.ReturnReasons.LowEnergy
    Internal.AppendLog(worker, "Was incapacitated and is being brought home to recover.", Internal.GetCurrentWorldHours(), "medical")
    Internal.SaveRegistry()
    return true
end

function Internal.HandleRevivedNPC(npcData)
    local workerID = npcData and npcData.linkedWorkerID or nil
    local registry = Internal.GetRegistry()
    local worker = workerID and registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false
    end

    Internal.SyncWorkerHealthFromNPC(worker.workerID, npcData)

    local companionData = Internal.GetCompanionData(worker)
    local currentHp = math.max(0, tonumber(worker.hp) or 0)
    local maxHp = math.max(1, tonumber(worker.maxHp) or tonumber(Config.DEFAULT_WORKER_MAX_HP) or 100)
    local wasIncapacitated = tostring(worker.state or "") == tostring(Config.States.Incapacitated)
    local shouldResumeActiveDuty = npcData and npcData.dcCompanionActive == true

    if shouldResumeActiveDuty then
        worker.jobEnabled = true
        worker.presenceState = Config.PresenceStates.CompanionActive
        worker.returnReason = nil
        worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
        companionData.stage = Internal.Constants.TRAVEL_STAGE_ACTIVE
        companionData.awaitingDespawn = false
        companionData.homeRecoveryLogged = false
        worker.state = Config.States.Working
    else
        worker.state = currentHp + 0.0001 < maxHp and Config.States.Resting or Config.States.Idle
    end

    if wasIncapacitated then
        Internal.AppendLog(
            worker,
            shouldResumeActiveDuty
                and "Recovered in the field and resumed companion duty."
                or "Recovered from incapacitation.",
            Internal.GetCurrentWorldHours(),
            "medical"
        )
    end

    Internal.SaveRegistry()
    return true
end
