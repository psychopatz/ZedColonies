DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

local function hasLiveCompanionNPC(uuid)
    if not uuid or not DTNPCServerCore then
        return false
    end

    if DTNPCServerCore.GetNPCDataByUUID and DTNPCServerCore.GetNPCDataByUUID(uuid) ~= nil then
        return true
    end

    return DTNPCServerCore.FindZombieByUUID and DTNPCServerCore.FindZombieByUUID(uuid) ~= nil or false
end

local function removeLiveCompanionNPC(uuid)
    if not uuid then
        return false
    end

    local removed = false
    local zombie = DTNPCServerCore and DTNPCServerCore.FindZombieByUUID and DTNPCServerCore.FindZombieByUUID(uuid) or nil
    if zombie then
        zombie:removeFromWorld()
        zombie:removeFromSquare()
        removed = true
    end

    if DTNPCManager and DTNPCManager.SetNPCStatus then
        DTNPCManager.SetNPCStatus(uuid, "Away", nil, nil)
        removed = true
    end

    if DTNPC_SpatialHash and DTNPC_SpatialHash.RemoveNPC then
        DTNPC_SpatialHash.RemoveNPC(uuid)
    end
    if DTNPC_DistanceFrequency and DTNPC_DistanceFrequency.RemoveNPC then
        DTNPC_DistanceFrequency.RemoveNPC(uuid)
    end
    if DTNPCManager and DTNPCManager.RemoveData then
        DTNPCManager.RemoveData(uuid, nil, nil, nil, "companion-home-reconcile")
    end

    return removed
end

function Internal.ReconcileCompanionHomeState(worker, reason)
    if isClient() and not isServer() then
        return false
    end
    if not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false
    end

    local uuid = Internal.GetCompanionUUID(worker)
    if not uuid or not hasLiveCompanionNPC(uuid) then
        return false
    end

    local companionData = Internal.GetCompanionData(worker)
    local npcData = Internal.GetSoul(uuid)
    if npcData then
        Internal.SetSoulCompanionFlags(worker, npcData, false)
        Internal.SaveSoul(uuid, npcData)
    end

    local cleaned = removeLiveCompanionNPC(uuid)
    if cleaned then
        worker.presenceState = Config.PresenceStates.Home
        worker.travelHoursRemaining = 0
        worker.jobEnabled = false
        worker.returnReason = nil
        companionData.stage = nil
        companionData.awaitingDespawn = false
        companionData.currentOrder = nil
        companionData.returnReason = nil
        companionData.returnTravelHours = nil
        companionData.commandInvalidSinceMs = nil
        Internal.Debug(
            "Reconciled live companion at home workerID=" .. tostring(worker.workerID)
                .. " uuid=" .. tostring(uuid)
                .. " reason=" .. tostring(reason or "home")
        )
    end

    return cleaned
end

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
    worker.jobEnabled = false

    if uuid
        and DTNPCServerCore
        and DTNPCServerCore.IssueOrderByUUID
        and worker.presenceState ~= Config.PresenceStates.Home
        and hasLiveCompanionNPC(uuid) then
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
        if worker.presenceState == Config.PresenceStates.CompanionActive then
            Internal.AppendLog(worker, "Leaving your position and heading home.", currentHour, "travel")
        elseif worker.presenceState == Config.PresenceStates.CompanionToPlayer then
            Internal.AppendLog(worker, "Stopping companion travel and heading home.", currentHour, "travel")
        end
        return true
    end

    if worker.presenceState == Config.PresenceStates.Home then
        Internal.ReconcileCompanionHomeState(worker, reason or "already-home")
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