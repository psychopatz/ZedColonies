DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}
DC_Colony.Medical = DC_Colony.Medical or {}

local Config = DC_Colony.Config
local Health = DC_Colony.Health

Health.Internal = Health.Internal or {}
Health.Internal.Process = Health.Internal.Process or {}

local Process = Health.Internal.Process

function Process.appendMedicalLog(worker, message)
    local internal = DC_Colony and DC_Colony.Sim and DC_Colony.Sim.Internal or nil
    if not worker or not message or message == "" or not internal or not internal.appendWorkerLog then
        return
    end

    local currentHour = Config.GetCurrentWorldHours and Config.GetCurrentWorldHours() or Config.GetCurrentHour and Config.GetCurrentHour() or 0
    internal.appendWorkerLog(worker, tostring(message), currentHour, "medical")
end

function Process.getHomePresenceState()
    return tostring((Config.PresenceStates or {}).Home or "Home")
end

function Process.getDeadState()
    return tostring((Config.States or {}).Dead or "Dead")
end

function Process.getIncapacitatedState()
    return tostring((Config.States or {}).Incapacitated or "Incapacitated")
end

function Process.isHome(worker)
    return tostring(worker and worker.presenceState or "") == Process.getHomePresenceState()
end

function Process.isDead(worker)
    return tostring(worker and worker.state or "") == Process.getDeadState()
end

function Process.isIncapacitated(worker)
    return tostring(worker and worker.state or "") == Process.getIncapacitatedState()
end

function Process.hasMedicalRecoveryNeed(worker)
    return worker
        and (Process.isIncapacitated(worker)
            or (Health.GetCurrent(worker) + 0.0001) < Health.GetMax(worker))
end

function Process.isAssignedToInfirmary(worker)
    return DC_Colony.Medical
        and DC_Colony.Medical.IsAssignedToInfirmary
        and DC_Colony.Medical.IsAssignedToInfirmary(worker)
        or false
end

function Process.isDoctorCovered(worker)
    return DC_Colony.Medical
        and DC_Colony.Medical.IsDoctorCovered
        and DC_Colony.Medical.IsDoctorCovered(worker)
        or false
end

return Process