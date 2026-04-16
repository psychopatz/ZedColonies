DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

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
        if not worker.jobEnabled then
            Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
            return true
        end
        worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
        if deltaHours > 0 then
            worker.travelHoursRemaining = math.max(0, worker.travelHoursRemaining - deltaHours)
        end
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
            Internal.MarkCompanionActive(worker)
            Internal.AppendLog(worker, "Reached your location and is now traveling with you.", currentHour, "travel")
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