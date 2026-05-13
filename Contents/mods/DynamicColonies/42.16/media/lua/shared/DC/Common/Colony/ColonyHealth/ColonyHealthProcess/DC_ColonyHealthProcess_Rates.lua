DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}

local Config = DC_Colony.Config
local Health = DC_Colony.Health

Health.Internal = Health.Internal or {}
Health.Internal.Process = Health.Internal.Process or {}

local Process = Health.Internal.Process

function Process.getBaseSleepHealRate(worker)
    return math.max(0, tonumber(Config.GetHealthRegenPerHour and Config.GetHealthRegenPerHour(worker)) or 1)
end

function Process.getInfirmarySleepHealRate(worker)
    local multiplier = tonumber(Config.GetInfirmaryHealthRegenMultiplier and Config.GetInfirmaryHealthRegenMultiplier(worker)) or 1.5
    return Process.getBaseSleepHealRate(worker) * math.max(1, multiplier)
end

function Process.getDoctorSleepHealRate(worker)
    local multiplier = tonumber(Config.GetDoctorHealthRegenMultiplier and Config.GetDoctorHealthRegenMultiplier(worker)) or 4.0
    return Process.getBaseSleepHealRate(worker) * math.max(1, multiplier)
end

function Process.getSelfTreatmentHours()
    return math.max(1, tonumber(Config.GetBandageTreatmentHours and Config.GetBandageTreatmentHours()) or 24)
end

return Process