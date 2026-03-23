DT_Labour = DT_Labour or {}
DT_Labour.Tiredness = DT_Labour.Tiredness or {}

local Config = DT_Labour.Config
local Tiredness = DT_Labour.Tiredness

local function appendWorkerLog(worker, message, worldHour, category)
    local simInternal = DT_Labour and DT_Labour.Sim and DT_Labour.Sim.Internal or nil
    if simInternal and simInternal.appendWorkerLog then
        simInternal.appendWorkerLog(worker, message, worldHour, category)
    end
end

function Tiredness.ApplyWorkDrain(worker, hoursWorked, profile)
    local hours = math.max(0, tonumber(hoursWorked) or 0)
    if hours <= 0 then
        return Tiredness.GetCurrent(worker)
    end

    return Tiredness.SetCurrent(
        worker,
        Tiredness.GetCurrent(worker) - (Tiredness.GetWorkDrainPerHour(worker, profile) * hours)
    )
end

function Tiredness.ApplyTravelDrain(worker, travelHours, profile)
    local hours = math.max(0, tonumber(travelHours) or 0)
    if hours <= 0 then
        return Tiredness.GetCurrent(worker)
    end

    return Tiredness.SetCurrent(
        worker,
        Tiredness.GetCurrent(worker) - (Tiredness.GetTravelDrainPerHour(worker, profile) * hours)
    )
end

function Tiredness.ApplyHomeRecovery(worker, recoveryHours, profile)
    local hours = math.max(0, tonumber(recoveryHours) or 0)
    if hours <= 0 then
        return Tiredness.GetCurrent(worker)
    end

    return Tiredness.SetCurrent(
        worker,
        Tiredness.GetCurrent(worker) + (Tiredness.GetHomeRecoveryPerHour(worker, profile) * hours)
    )
end

function Tiredness.BeginForcedRest(worker, currentHour, reason, message)
    if not worker then
        return false
    end

    local changed = Tiredness.SetForcedRest(worker, true, reason)
    if changed and message and tostring(message) ~= "" then
        appendWorkerLog(worker, tostring(message), currentHour, "tiredness")
    end
    return changed
end

function Tiredness.CompleteForcedRest(worker, currentHour, message)
    if not worker or not Tiredness.IsForcedRest(worker) then
        return false
    end

    if Tiredness.GetCurrent(worker) + 0.0001 < Tiredness.GetMax(worker) then
        return false
    end

    local changed = Tiredness.SetForcedRest(worker, false)
    if changed and message and tostring(message) ~= "" then
        appendWorkerLog(worker, tostring(message), currentHour, "tiredness")
    end

    if worker.returnReason == ((Config.ReturnReasons or {}).LowTiredness) then
        worker.returnReason = nil
    end

    return changed
end

return Tiredness
