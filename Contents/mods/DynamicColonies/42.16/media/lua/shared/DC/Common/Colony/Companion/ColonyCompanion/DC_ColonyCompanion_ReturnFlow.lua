DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.BeginWorkerCompanionReturn(player, worker, reason)
    if not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false
    end

    Internal.Debug(
        "BeginWorkerCompanionReturn workerID=" .. tostring(worker.workerID)
            .. " uuid=" .. tostring(Internal.GetCompanionUUID(worker))
            .. " reason=" .. tostring(reason)
            .. " presenceState=" .. tostring(worker.presenceState)
    )

    local companionData = Internal.GetCompanionData(worker)
    local uuid = Internal.GetCompanionUUID(worker)
    local travelHours = Internal.GetTravelHours()
    local currentHour = Internal.GetCurrentWorldHours()
    companionData.returnReason = reason or Config.ReturnReasons.Manual
    companionData.returnTravelHours = travelHours
    companionData.commandInvalidSinceMs = nil
    worker.returnReason = companionData.returnReason

    if worker.presenceState == Config.PresenceStates.CompanionActive and uuid and DTNPCServerCore and DTNPCServerCore.IssueOrderByUUID then
        companionData.stage = Internal.Constants.TRAVEL_STAGE_DEPARTING
        companionData.awaitingDespawn = true
        worker.state = Config.States.Working
        local npcData = Internal.GetSoul(uuid)
        if npcData then
            Internal.SetSoulCompanionFlags(worker, npcData, false)
            Internal.SaveSoul(uuid, npcData)
        end
        DTNPCServerCore.IssueOrderByUUID(uuid, player or { ownerUsername = worker.ownerUsername }, {
            state = "Stay",
            returnStatus = "Resting",
            startDeparture = true,
            systemCompanionOrder = true,
        })
        Internal.AppendLog(worker, "Leaving your position and heading home.", currentHour, "travel")
        return true
    end

    if worker.presenceState == Config.PresenceStates.Home then
        worker.jobEnabled = false
        worker.returnReason = nil
        companionData.stage = nil
        companionData.awaitingDespawn = false
        companionData.commanderUsername = nil
        companionData.commanderOnlineID = nil
        companionData.commandInvalidSinceMs = nil
        return true
    end

    worker.presenceState = Config.PresenceStates.CompanionReturning
    worker.travelHoursRemaining = travelHours
    worker.jobEnabled = false
    companionData.stage = Internal.Constants.TRAVEL_STAGE_RETURNING
    companionData.awaitingDespawn = false
    Internal.AppendLog(worker, "Heading home from your location.", currentHour, "travel")
    return true
end