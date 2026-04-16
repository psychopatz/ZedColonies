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