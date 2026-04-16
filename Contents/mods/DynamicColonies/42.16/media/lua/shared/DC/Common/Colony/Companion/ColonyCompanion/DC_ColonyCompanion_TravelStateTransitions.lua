DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.FinalizeReturnTravel(worker, currentHour)
    local companionData = Internal.GetCompanionData(worker)
    worker.presenceState = Config.PresenceStates.Home
    worker.travelHoursRemaining = 0
    worker.returnReason = nil
    if worker.state ~= Config.States.Dead and worker.state ~= Config.States.Incapacitated then
        worker.state = Config.States.Idle
    end
    companionData.awaitingDespawn = false
    companionData.stage = nil
    companionData.currentOrder = nil
    companionData.returnReason = nil
    companionData.returnTravelHours = nil
    companionData.commanderUsername = nil
    companionData.commanderOnlineID = nil
    companionData.commandInvalidSinceMs = nil
    Internal.AppendLog(worker, "Returned home after companion duty.", currentHour, "travel")
end

function Internal.MarkCompanionActive(worker)
    if not worker then
        return
    end

    local companionData = Internal.GetCompanionData(worker)
    companionData.stage = Internal.Constants.TRAVEL_STAGE_ACTIVE
    companionData.awaitingDespawn = false
    companionData.homeRecoveryLogged = false
    worker.presenceState = Config.PresenceStates.CompanionActive
    worker.travelHoursRemaining = 0
    worker.state = Config.States.Working

    local uuid = Internal.GetCompanionUUID(worker)
    local npcData = uuid and Internal.GetSoul(uuid) or nil
    if npcData then
        Internal.SetSoulCompanionFlags(worker, npcData, true)
        Internal.SaveSoul(uuid, npcData)
    end
end