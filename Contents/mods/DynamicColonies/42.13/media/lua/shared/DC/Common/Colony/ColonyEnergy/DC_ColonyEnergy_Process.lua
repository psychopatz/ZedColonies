DC_Colony = DC_Colony or {}
DC_Colony.Energy = DC_Colony.Energy or {}

local Config = DC_Colony.Config
local Energy = DC_Colony.Energy

local function appendWorkerLog(worker, message, worldHour, category)
    local simInternal = DC_Colony and DC_Colony.Sim and DC_Colony.Sim.Internal or nil
    if simInternal and simInternal.appendWorkerLog then
        simInternal.appendWorkerLog(worker, message, worldHour, category)
    end
end

function Energy.ApplyWorkDrain(worker, hoursWorked, profile)
    local hours = math.max(0, tonumber(hoursWorked) or 0)
    if hours <= 0 then
        return Energy.GetCurrent(worker)
    end

    return Energy.SetCurrent(
        worker,
        Energy.GetCurrent(worker) - (Energy.GetWorkDrainPerHour(worker, profile) * hours)
    )
end

function Energy.ApplyTravelDrain(worker, travelHours, profile)
    local hours = math.max(0, tonumber(travelHours) or 0)
    if hours <= 0 then
        return Energy.GetCurrent(worker)
    end

    return Energy.SetCurrent(
        worker,
        Energy.GetCurrent(worker) - (Energy.GetTravelDrainPerHour(worker, profile) * hours)
    )
end

function Energy.ApplyHomeRecovery(worker, recoveryHours, profile)
    local hours = math.max(0, tonumber(recoveryHours) or 0)
    if hours <= 0 then
        return Energy.GetCurrent(worker)
    end

    return Energy.SetCurrent(
        worker,
        Energy.GetCurrent(worker) + (Energy.GetHomeRecoveryPerHour(worker, profile) * hours)
    )
end

function Energy.BeginForcedRest(worker, currentHour, reason, message)
    if not worker then
        return false
    end

    local changed = Energy.SetForcedRest(worker, true, reason, currentHour)
    if changed and message and tostring(message) ~= "" then
        appendWorkerLog(worker, tostring(message), currentHour, "energy")
    end
    return changed
end

function Energy.CompleteForcedRest(worker, currentHour, message)
    if not worker or not Energy.IsForcedRest(worker) then
        return false
    end

    local energy = Energy.EnsureWorkerEnergy(worker)
    local fullyRested = Energy.GetCurrent(worker) + 0.0001 >= Energy.GetMax(worker)
    local timedOut = false
    
    if energy and energy.restStartedHour then
        local elapsed = currentHour - energy.restStartedHour
        if elapsed >= 10 then
            timedOut = true
        end
    end

    if not fullyRested and not timedOut then
        return false
    end

    local finalMessage = message
    if timedOut and not fullyRested then
        finalMessage = "Woke up after 10 hours of rest."
    end

    local changed = Energy.SetForcedRest(worker, false)
    if changed and finalMessage and tostring(finalMessage) ~= "" then
        appendWorkerLog(worker, tostring(finalMessage), currentHour, "energy")
    end

    local lowEnergyReason = (Config.ReturnReasons or {}).LowEnergy or (Config.ReturnReasons or {}).LowTiredness
    if worker.returnReason == lowEnergyReason then
        worker.returnReason = nil
    end

    return changed
end

return Energy

