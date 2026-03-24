DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}
DC_Colony.Medical = DC_Colony.Medical or {}

local Config = DC_Colony.Config
local Health = DC_Colony.Health

function Health.ApplyDeprivationDamage(worker, deprivedHours)
    if not worker or deprivedHours <= 0 then
        return Health.GetCurrent(worker)
    end
    
    local damage = deprivedHours * (Config.GetHealthLossPerHour and Config.GetHealthLossPerHour() or 1)
    return Health.SetCurrent(worker, Health.GetCurrent(worker) - damage)
end

function Health.IsSleepEligible(worker, forcedRest)
    local presenceState = tostring(worker and worker.presenceState or "")
    local homeState = tostring((Config.PresenceStates or {}).Home or "Home")
    return worker
        and presenceState == homeState
        and forcedRest == true
        and Health.GetCurrent(worker) > 0
end

function Health.ApplySleepHealing(worker, forcedRest, supportedHours)
    local baseRate = 0.25
    local treatedRate = 1.00
    local hp = Health.GetCurrent(worker)
    local hpMax = Health.GetMax(worker)

    worker.sleepHealingRate = 0
    worker.sleepHealingSource = "None"
    worker.medicalSupplyBlocked = false
    
    if not Health.IsSleepEligible(worker, forcedRest) or supportedHours <= 0 or hp <= 0 or hp >= hpMax then
        return hp, supportedHours, 0
    end

    local healingAmount = supportedHours * baseRate
    local boostedHours = 0
    
    if DC_Colony.Medical and DC_Colony.Medical.ConsumeTreatmentHours then
        boostedHours = DC_Colony.Medical.ConsumeTreatmentHours(worker, supportedHours)
        if boostedHours > 0 then
            healingAmount = healingAmount + (boostedHours * (treatedRate - baseRate))
        end
    end

    hp = Health.SetCurrent(worker, hp + healingAmount)
    worker.sleepHealingRate = supportedHours > 0 and (healingAmount / supportedHours) or 0

    if boostedHours > 0 then
        worker.sleepHealingSource = "InfirmaryDoctor"
    elseif DC_Colony.Medical and DC_Colony.Medical.IsAssignedToInfirmary and DC_Colony.Medical.IsAssignedToInfirmary(worker) then
        worker.sleepHealingSource = "Infirmary"
    else
        worker.sleepHealingSource = "HomeSleep"
    end

    if DC_Colony.Medical and DC_Colony.Medical.IsDoctorCovered and DC_Colony.Medical.IsDoctorCovered(worker) and boostedHours < supportedHours then
        worker.medicalSupplyBlocked = true
    end

    return hp, supportedHours, boostedHours
end

return Health
