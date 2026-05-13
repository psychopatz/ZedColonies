DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}
DC_Colony.Medical = DC_Colony.Medical or {}

local Health = DC_Colony.Health

Health.Internal = Health.Internal or {}
Health.Internal.Process = Health.Internal.Process or {}

local Process = Health.Internal.Process

function Health.IsSleepEligible(worker, forcedRest)
    return worker
        and Process.isHome(worker)
        and not Process.isDead(worker)
        and (forcedRest == true or Process.hasMedicalRecoveryNeed(worker))
end

function Health.GetSleepHealingRate(worker, forcedRest)
    if not Health.IsSleepEligible(worker, forcedRest) then
        return 0
    end

    local baseRate = Process.getBaseSleepHealRate(worker)
    local healingRate = baseRate
    if Process.isAssignedToInfirmary(worker) then
        healingRate = math.max(healingRate, Process.getInfirmarySleepHealRate(worker))
    end
    if Process.isDoctorCovered(worker) then
        healingRate = math.max(healingRate, Process.getDoctorSleepHealRate(worker))
    end

    local treatmentState = Process.getSelfTreatmentState(worker)
    if treatmentState and (tonumber(treatmentState.healRemaining) or 0) > 0 then
        healingRate = healingRate + math.max(0, tonumber(treatmentState.regenPerHour) or 0)
    end

    if baseRate <= 0 then
        return 0
    end

    return healingRate / baseRate
end

function Health.ApplySleepHealing(worker, forcedRest, supportedHours)
    local baseRate = Process.getBaseSleepHealRate(worker)
    local infirmaryRate = Process.getInfirmarySleepHealRate(worker)
    local treatedRate = Process.getDoctorSleepHealRate(worker)
    local hp = Health.GetCurrent(worker)
    local hpMax = Health.GetMax(worker)
    local inInfirmary = Process.isAssignedToInfirmary(worker)
    local healingRate = inInfirmary and math.max(baseRate, infirmaryRate) or baseRate

    worker.sleepHealingRate = 0
    worker.sleepHealingSource = "None"
    worker.medicalSupplyBlocked = false

    if not Health.IsSleepEligible(worker, forcedRest) then
        Process.clearSelfTreatmentState(worker)
        return hp, supportedHours, 0
    end

    if supportedHours <= 0 then
        return hp, supportedHours, 0
    end

    if hp >= hpMax then
        Process.clearSelfTreatmentState(worker)
        return hp, supportedHours, 0
    end

    local healingAmount = supportedHours * healingRate
    local boostedHours = 0

    if DC_Colony.Medical and DC_Colony.Medical.ConsumeTreatmentHours then
        boostedHours = DC_Colony.Medical.ConsumeTreatmentHours(worker, supportedHours)
        if boostedHours > 0 then
            healingAmount = healingAmount + (boostedHours * (treatedRate - healingRate))
        end
    end

    local selfTreatmentHealing = 0
    hp = Health.SetCurrent(worker, hp + healingAmount)
    hp, selfTreatmentHealing = Process.applySelfTreatment(worker, supportedHours, hp, hpMax)
    hp = Health.SetCurrent(worker, hp)
    healingAmount = healingAmount + selfTreatmentHealing
    worker.sleepHealingRate = supportedHours > 0 and (healingAmount / supportedHours) or 0

    if boostedHours > 0 then
        worker.sleepHealingSource = "InfirmaryDoctor"
    elseif inInfirmary then
        worker.sleepHealingSource = "Infirmary"
    else
        worker.sleepHealingSource = "HomeSleep"
    end

    if Process.isDoctorCovered(worker) and boostedHours < supportedHours then
        worker.medicalSupplyBlocked = true
    end

    return hp, supportedHours, boostedHours
end

return Health