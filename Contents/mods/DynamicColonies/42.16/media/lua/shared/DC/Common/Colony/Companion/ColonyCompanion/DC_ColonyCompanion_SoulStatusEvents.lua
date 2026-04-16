DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.OnSoulStatusChanged(uuid, status, npcData)
    if not uuid or not status then
        return
    end

    Internal.Debug(
        "OnSoulStatusChanged uuid=" .. tostring(uuid)
            .. " status=" .. tostring(status)
            .. " linkedWorkerID=" .. tostring(npcData and npcData.linkedWorkerID)
    )

    local linkedWorkerID = npcData and npcData.linkedWorkerID or nil
    local registry = Internal.GetRegistry()
    local worker = linkedWorkerID and registry and registry.GetWorkerRaw and registry.GetWorkerRaw(linkedWorkerID) or nil
    if not worker or not Internal.IsTravelCompanionWorker(worker) then
        return
    end

    local companionData = Internal.GetCompanionData(worker)
    if tostring(status) == "Dead" then
        worker.state = Config.States.Dead
        worker.jobEnabled = false
        worker.hp = 0
        worker.presenceState = Config.PresenceStates.Home
        worker.travelHoursRemaining = 0
        companionData.stage = nil
        companionData.awaitingDespawn = false
        Internal.AppendLog(worker, "Died while away on companion duty.", Internal.GetCurrentWorldHours(), "death")
        Internal.SaveRegistry()
        return
    end

    if tostring(status) == "Away"
        and (companionData.awaitingDespawn == true
            or worker.presenceState == Config.PresenceStates.CompanionActive
            or worker.presenceState == Config.PresenceStates.CompanionToPlayer) then
        worker.jobEnabled = false
        worker.presenceState = Config.PresenceStates.CompanionReturning
        worker.travelHoursRemaining = math.max(0, tonumber(companionData.returnTravelHours) or Internal.GetTravelHours())
        worker.returnReason = worker.returnReason or companionData.returnReason or Config.ReturnReasons.Manual
        worker.state = worker.state == Config.States.Incapacitated and Config.States.Incapacitated or Config.States.Idle
        companionData.stage = Internal.Constants.TRAVEL_STAGE_RETURNING
        companionData.awaitingDespawn = false
        Internal.SaveRegistry()
    end
end