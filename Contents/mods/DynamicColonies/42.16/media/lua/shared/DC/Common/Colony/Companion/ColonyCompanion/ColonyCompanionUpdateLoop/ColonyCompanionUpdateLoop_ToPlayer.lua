DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
Companion.Internal = Companion.Internal or {}

local Internal = Companion.Internal
local UpdateLoop = Internal.UpdateLoop or {}
local Config = Internal.Config

Internal.UpdateLoop = UpdateLoop

function UpdateLoop.UpdateTravelCompanionToPlayerState(worker, ctx)
    local deltaHours = math.max(0, tonumber(ctx and ctx.deltaHours) or 0)
    local currentHour = tonumber(ctx and ctx.currentHour) or Internal.GetCurrentWorldHours()
    local profile = ctx and ctx.profile or Config.GetJobProfile(worker.jobType)
    local energy = DC_Colony and DC_Colony.Energy or nil
    local companionData = Internal.GetCompanionData(worker)
    local presenceState = tostring(worker.presenceState or "")

    Internal.RefreshCompanionCommanderValidity(worker)
    if tostring(worker.presenceState or "") ~= presenceState then
        return true
    end
    if companionData.awaitingDespawn == true then
        worker.state = Config.States.Working
        return true
    end
    if worker.state ~= Config.States.Working then
        worker.state = Config.States.Working
    end
    if not worker.jobEnabled then
        Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
        return true
    end
    local uuid = Internal.GetCompanionUUID(worker)
    if not uuid or not Internal.GetSoul(uuid) then
        local syncedUUID = uuid
        if not syncedUUID then
            syncedUUID = select(1, Internal.CreateCompanionSoul(worker))
        end
        if syncedUUID then
            uuid = syncedUUID
            companionData.uuid = syncedUUID
            Internal.SyncNPCFromWorker(worker, syncedUUID)
            Internal.SyncCommanderToSoul(worker)
        else
            Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
            return true
        end
    end
    worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
    if deltaHours > 0 then
        worker.travelHoursRemaining = math.max(0, worker.travelHoursRemaining - deltaHours)
    end
    if worker.travelHoursRemaining > 0 then
        UpdateLoop.ApplyTravelProgressFailsafe(worker, companionData, currentHour, deltaHours)
    end
    UpdateLoop.SetTravelProgressMarker(companionData, currentHour, worker.travelHoursRemaining)
    if energy and deltaHours > 0 then
        energy.ApplyTravelDrain(worker, deltaHours, profile)
    end
    if energy and energy.IsDepleted and energy.IsDepleted(worker) then
        local lowEnergyReason = Config.ReturnReasons and (Config.ReturnReasons.LowEnergy or Config.ReturnReasons.LowTiredness) or "LowEnergy"
        if energy.BeginForcedRest then
            energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to reach your position. Returning home to rest.")
        end
        Internal.BeginWorkerCompanionReturn(nil, worker, lowEnergyReason)
        return true
    end
    if worker.travelHoursRemaining <= 0 then
        if isClient() and not isServer() then
            worker.state = Config.States.Working
            return true
        end

        local commanderName = tostring(companionData.commanderUsername or "")
        local commanderPlayer = commanderName ~= ""
            and Internal.GetOnlinePlayerByUsername
            and Internal.GetOnlinePlayerByUsername(commanderName)
            or nil
        Internal.SyncNPCFromWorker(worker, uuid)
        Internal.SyncCommanderToSoul(worker)
        local activated = false
        local failureReason = nil
        if commanderPlayer and DTNPCServerCore and DTNPCServerCore.ActivateArrivalByUUID then
            activated, _, _, failureReason = DTNPCServerCore.ActivateArrivalByUUID(uuid, {
                controller = commanderPlayer,
                targetPlayer = commanderPlayer,
                targetUsername = commanderName,
                targetOnlineID = commanderPlayer.getOnlineID and commanderPlayer:getOnlineID() or nil,
                spawnPolicy = "nearby_follow",
                activationMode = "companion_follow",
                state = "Follow",
                status = "Working",
                returnTime = 0,
                returnStatus = nil,
                requestedReturnStatus = "Resting",
                invalidTargetBehavior = "abort",
            })
        elseif commanderPlayer and Internal.IssueCommanderFollowOrder then
            activated = Internal.IssueCommanderFollowOrder(worker, commanderPlayer)
        else
            failureReason = "target_missing"
        end

        if activated == true then
            Internal.MarkCompanionActive(worker)
            Internal.AppendLog(worker, "Reached your location and is now traveling with you.", currentHour, "travel")
            Internal.SaveRegistry()
        elseif failureReason == "target_missing" then
            Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
        else
            worker.state = Config.States.Working
            Internal.Debug(
                "UpdateTravelCompanionWorker waiting to activate live companion workerID=" .. tostring(worker.workerID)
                    .. " commander=" .. tostring(commanderName)
                    .. " hasCommanderPlayer=" .. tostring(commanderPlayer ~= nil)
            )
        end
    else
        worker.state = Config.States.Working
    end
    return true
end

return Companion