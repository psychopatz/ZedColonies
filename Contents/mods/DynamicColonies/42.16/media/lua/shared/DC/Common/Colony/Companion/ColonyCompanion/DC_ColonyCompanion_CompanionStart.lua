DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.StartWorkerCompanion(player, worker)
    if not player or not worker or not Internal.IsTravelCompanionWorker(worker) then
        Internal.Debug("StartWorkerCompanion rejected: invalid player/worker context")
        return false, "Companion start is unavailable."
    end

    local okay, reason = Internal.CanWorkerBeCompanion(worker)
    if not okay then
        Internal.Debug("StartWorkerCompanion capability check failed workerID=" .. tostring(worker.workerID) .. " reason=" .. tostring(reason))
        return false, reason
    end

    local ready, readyReason = Internal.CanWorkerStartCompanionNow(worker)
    if not ready then
        Internal.Debug("StartWorkerCompanion readiness check failed workerID=" .. tostring(worker.workerID) .. " reason=" .. tostring(readyReason))
        return false, readyReason
    end

    local uuid, err, createdFresh = Internal.CreateCompanionSoul(worker)
    if not uuid then
        Internal.Debug("StartWorkerCompanion failed to prepare companion soul workerID=" .. tostring(worker.workerID) .. " reason=" .. tostring(err))
        return false, err or "Unable to prepare companion soul."
    end

    Internal.Debug(
        "StartWorkerCompanion prepared companion soul workerID=" .. tostring(worker.workerID)
            .. " uuid=" .. tostring(uuid)
            .. " owner=" .. tostring(worker.ownerUsername)
    )

    local companionData = Internal.GetCompanionData(worker)
    companionData.uuid = uuid
    companionData.stage = Internal.Constants.TRAVEL_STAGE_OUTBOUND
    companionData.awaitingDespawn = false
    companionData.currentOrder = "Follow"
    companionData.returnReason = nil
    companionData.returnTravelHours = nil
    companionData.homeRecoveryLogged = false
    Internal.AssignWorkerCompanionCommander(player, worker, Internal.GetPlayerUsername(player), "started")

    worker.presenceState = Config.PresenceStates.CompanionToPlayer
    worker.travelHoursRemaining = Internal.GetTravelHours()
    worker.returnReason = nil
    worker.state = Config.States.Working

    Internal.SyncNPCFromWorker(worker, uuid)

    if isClient() and not isServer() then
        Internal.Debug("StartWorkerCompanion client optimistic success workerID=" .. tostring(worker.workerID) .. " uuid=" .. tostring(uuid))
        return true, uuid
    end

    if not DTNPCServerCore then
        Internal.Debug("StartWorkerCompanion missing DTNPCServerCore workerID=" .. tostring(worker.workerID))
        Internal.RestoreWorkerAfterFailedStart(worker)
        return false, "Dynamic Trading V2 server controls are unavailable."
    end
    Internal.AppendLog(worker, "Left home and started heading to your location.", Internal.GetCurrentWorldHours(), "travel")
    Internal.Debug("StartWorkerCompanion queued outbound travel workerID=" .. tostring(worker.workerID) .. " uuid=" .. tostring(uuid) .. " travelHours=" .. tostring(worker.travelHoursRemaining))
    return true, uuid
end