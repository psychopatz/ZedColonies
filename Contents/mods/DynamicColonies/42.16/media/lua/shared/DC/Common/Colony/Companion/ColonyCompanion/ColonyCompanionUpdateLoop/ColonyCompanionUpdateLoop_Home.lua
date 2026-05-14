DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
Companion.Internal = Companion.Internal or {}

local Internal = Companion.Internal
local UpdateLoop = Internal.UpdateLoop or {}
local Config = Internal.Config

Internal.UpdateLoop = UpdateLoop

function UpdateLoop.UpdateTravelCompanionHomeState(worker, ctx)
    local deltaHours = math.max(0, tonumber(ctx and ctx.deltaHours) or 0)
    local currentHour = tonumber(ctx and ctx.currentHour) or Internal.GetCurrentWorldHours()
    local forcedRest = ctx and ctx.forcedRest == true or false
    local energy = DC_Colony and DC_Colony.Energy or nil
    local health = Internal.GetHealth()
    local profile = ctx and ctx.profile or Config.GetJobProfile(worker.jobType)
    local companionData = Internal.GetCompanionData(worker)
    local hpCurrent = health and health.GetCurrent and health.GetCurrent(worker) or math.max(0, tonumber(worker.hp) or 0)
    local hpMax = health and health.GetMax and health.GetMax(worker) or math.max(1, tonumber(worker.maxHp) or tonumber(Config.DEFAULT_WORKER_MAX_HP) or 100)

    local shouldReconcileHome = true
    if DC_Colony and DC_Colony.ResidentBridge and DC_Colony.ResidentBridge.ShouldKeepHomeResidentBody then
        shouldReconcileHome = DC_Colony.ResidentBridge.ShouldKeepHomeResidentBody(worker) ~= true
    end
    if shouldReconcileHome then
        Internal.ReconcileCompanionHomeState(worker, "update-home")
    end

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

return Companion
