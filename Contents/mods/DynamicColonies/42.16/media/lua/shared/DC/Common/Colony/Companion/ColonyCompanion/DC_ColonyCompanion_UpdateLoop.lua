DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

local function setTravelProgressMarker(companionData, currentHour, remainingHours)
    if not companionData then
        return
    end

    companionData.travelLastProgressHour = tonumber(currentHour) or companionData.travelLastProgressHour
    companionData.travelLastRemainingHours = math.max(0, tonumber(remainingHours) or 0)
end

local function applyTravelProgressFailsafe(worker, companionData, currentHour, deltaHours)
    local remainingHours = math.max(0, tonumber(worker and worker.travelHoursRemaining) or 0)
    if remainingHours <= 0 then
        setTravelProgressMarker(companionData, currentHour, remainingHours)
        return false
    end

    local lastProgressHour = tonumber(companionData and companionData.travelLastProgressHour) or nil
    local lastRemainingHours = tonumber(companionData and companionData.travelLastRemainingHours) or nil
    if lastProgressHour == nil or lastRemainingHours == nil or remainingHours < (lastRemainingHours - 0.0001) then
        setTravelProgressMarker(companionData, currentHour, remainingHours)
        return false
    end

    local graceHours = math.max(0.25, math.min(1.0, tonumber(Internal.GetTravelHours and Internal.GetTravelHours()) or 1))
    if (tonumber(currentHour) or 0) - lastProgressHour < graceHours then
        return false
    end

    local forcedStep = math.max(0.05, tonumber(deltaHours) or 0)
    worker.travelHoursRemaining = math.max(0, remainingHours - forcedStep)
    setTravelProgressMarker(companionData, currentHour, worker.travelHoursRemaining)
    Internal.Debug(
        "Companion travel failsafe advanced workerID=" .. tostring(worker and worker.workerID)
            .. " presenceState=" .. tostring(worker and worker.presenceState)
            .. " remaining=" .. tostring(worker and worker.travelHoursRemaining)
    )
    return true
end

function Internal.UpdateTravelCompanionWorker(worker, ctx)
    if not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false
    end

    local deltaHours = math.max(0, tonumber(ctx and ctx.deltaHours) or 0)
    local currentHour = tonumber(ctx and ctx.currentHour) or Internal.GetCurrentWorldHours()
    local forcedRest = ctx and ctx.forcedRest == true or false
    local hasCalories = ctx and ctx.hasCalories ~= false
    local hasHydration = ctx and ctx.hasHydration ~= false
    local energy = DC_Colony and DC_Colony.Energy or nil
    local health = Internal.GetHealth()
    local profile = ctx and ctx.profile or Config.GetJobProfile(worker.jobType)
    local presenceState = tostring(worker.presenceState or "")
    local companionData = Internal.GetCompanionData(worker)
    local hpCurrent = health and health.GetCurrent and health.GetCurrent(worker) or math.max(0, tonumber(worker.hp) or 0)
    local hpMax = health and health.GetMax and health.GetMax(worker) or math.max(1, tonumber(worker.maxHp) or tonumber(Config.DEFAULT_WORKER_MAX_HP) or 100)

    if presenceState == Config.PresenceStates.Home then
        Internal.ReconcileCompanionHomeState(worker, "update-home")

        if energy and deltaHours > 0 and hpCurrent > 0 and energy.ApplyHomeRecovery then
            energy.ApplyHomeRecovery(worker, deltaHours, profile)
            if energy.IsForcedRest and energy.IsForcedRest(worker) and energy.CompleteForcedRest then
                energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
            end
            forcedRest = energy.IsForcedRest and energy.IsForcedRest(worker) or forcedRest
        end

        local isIncapacitated = tostring(worker.state or "") == tostring(Config.States.Incapacitated)
        local needsRecovery = isIncapacitated or (hpCurrent + 0.0001) < hpMax

        if isIncapacitated and (hpCurrent + 0.0001) >= hpMax then
            worker.state = forcedRest and Config.States.Resting or Config.States.Idle
            companionData.homeRecoveryLogged = false
            Internal.AppendLog(worker, "Recovered from incapacitation and is back on their feet.", currentHour, "medical")
            return true
        end

        if needsRecovery then
            if companionData.homeRecoveryLogged ~= true then
                local message = isIncapacitated
                    and "Reached home and is now resting to recover from incapacitation."
                    or "Is resting at home to recover from injuries."
                Internal.AppendLog(worker, message, currentHour, "medical")
                companionData.homeRecoveryLogged = true
            end

            if not isIncapacitated then
                worker.state = Config.States.Resting
            end
            return true
        end

        companionData.homeRecoveryLogged = false
        if worker.state ~= Config.States.Dead then
            worker.state = forcedRest and Config.States.Resting or Config.States.Idle
        end
        return true
    end

    if presenceState == Config.PresenceStates.CompanionToPlayer then
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
            applyTravelProgressFailsafe(worker, companionData, currentHour, deltaHours)
        end
        setTravelProgressMarker(companionData, currentHour, worker.travelHoursRemaining)
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

    if presenceState == Config.PresenceStates.CompanionReturning then
        if companionData.awaitingDespawn == true then
            worker.state = Config.States.Working
            return true
        end
        if worker.state ~= Config.States.Incapacitated then
            worker.state = Config.States.Idle
        end
        if Internal.GetCompanionUUID(worker)
            and DTNPCServerCore
            and DTNPCServerCore.GetNPCDataByUUID
            and DTNPCServerCore.GetNPCDataByUUID(Internal.GetCompanionUUID(worker)) then
            Internal.BeginWorkerCompanionReturn(nil, worker, worker.returnReason or companionData.returnReason or Config.ReturnReasons.Manual)
            return true
        end
        worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
        if deltaHours > 0 then
            worker.travelHoursRemaining = math.max(0, worker.travelHoursRemaining - deltaHours)
        end
        if worker.travelHoursRemaining > 0 then
            applyTravelProgressFailsafe(worker, companionData, currentHour, deltaHours)
        end
        setTravelProgressMarker(companionData, currentHour, worker.travelHoursRemaining)
        if energy and deltaHours > 0 then
            energy.ApplyTravelDrain(worker, deltaHours, profile)
        end
        if worker.travelHoursRemaining <= 0 then
            Internal.FinalizeReturnTravel(worker, currentHour)
        else
            worker.state = worker.state == Config.States.Incapacitated and Config.States.Incapacitated or Config.States.Idle
        end
        return true
    end

    if presenceState == Config.PresenceStates.CompanionActive then
        Internal.RefreshCompanionCommanderValidity(worker)
        if tostring(worker.presenceState or "") ~= presenceState then
            return true
        end
        if companionData.awaitingDespawn == true then
            worker.state = Config.States.Working
            return true
        end

        if energy and deltaHours > 0 then
            energy.ApplyWorkDrain(worker, deltaHours, profile)
        end

        if not worker.jobEnabled then
            Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
        elseif not hasHydration then
            Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.LowDrink)
        elseif not hasCalories then
            Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.LowFood)
        elseif forcedRest or (energy and energy.IsDepleted and energy.IsDepleted(worker)) then
            local lowEnergyReason = Config.ReturnReasons and (Config.ReturnReasons.LowEnergy or Config.ReturnReasons.LowTiredness) or "LowEnergy"
            if energy and energy.BeginForcedRest then
                energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired for companion duty. Returning home to rest.")
            end
            Internal.BeginWorkerCompanionReturn(nil, worker, lowEnergyReason)
        else
            worker.state = Config.States.Working
            companionData.stage = Internal.Constants.TRAVEL_STAGE_ACTIVE
        end
        return true
    end

    return false
end
