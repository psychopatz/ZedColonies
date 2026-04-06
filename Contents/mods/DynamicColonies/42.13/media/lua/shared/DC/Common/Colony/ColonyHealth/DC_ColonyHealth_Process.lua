DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}
DC_Colony.Medical = DC_Colony.Medical or {}

local Config = DC_Colony.Config
local Health = DC_Colony.Health

local SELF_TREATMENT_TIERS = {
    clean_rag = {
        label = "clean rag",
        totalHeal = 20,
        applyHeal = 2,
        iconFullType = "Base.RippedSheets",
    },
    sterilized_rag = {
        label = "sterilized rag",
        totalHeal = 28,
        applyHeal = 3,
        iconFullType = "Base.AlcoholRippedSheets",
    },
    bandage = {
        label = "bandage",
        totalHeal = 36,
        applyHeal = 4,
        iconFullType = "Base.Bandage",
    },
}

local function appendMedicalLog(worker, message)
    local internal = DC_Colony and DC_Colony.Sim and DC_Colony.Sim.Internal or nil
    if not worker or not message or message == "" or not internal or not internal.appendWorkerLog then
        return
    end

    local currentHour = Config.GetCurrentWorldHours and Config.GetCurrentWorldHours() or Config.GetCurrentHour and Config.GetCurrentHour() or 0
    internal.appendWorkerLog(worker, tostring(message), currentHour, "medical")
end

local function getHomePresenceState()
    return tostring((Config.PresenceStates or {}).Home or "Home")
end

local function getDeadState()
    return tostring((Config.States or {}).Dead or "Dead")
end

local function getIncapacitatedState()
    return tostring((Config.States or {}).Incapacitated or "Incapacitated")
end

local function isHome(worker)
    return tostring(worker and worker.presenceState or "") == getHomePresenceState()
end

local function isDead(worker)
    return tostring(worker and worker.state or "") == getDeadState()
end

local function isIncapacitated(worker)
    return tostring(worker and worker.state or "") == getIncapacitatedState()
end

local function getBaseSleepHealRate(worker)
    return math.max(0, tonumber(Config.GetHealthRegenPerHour and Config.GetHealthRegenPerHour(worker)) or 1)
end

local function getInfirmarySleepHealRate(worker)
    local multiplier = tonumber(Config.GetInfirmaryHealthRegenMultiplier and Config.GetInfirmaryHealthRegenMultiplier(worker)) or 1.5
    return getBaseSleepHealRate(worker) * math.max(1, multiplier)
end

local function getDoctorSleepHealRate(worker)
    local multiplier = tonumber(Config.GetDoctorHealthRegenMultiplier and Config.GetDoctorHealthRegenMultiplier(worker)) or 4.0
    return getBaseSleepHealRate(worker) * math.max(1, multiplier)
end

local function getSelfTreatmentHours()
    return math.max(1, tonumber(Config.GetBandageTreatmentHours and Config.GetBandageTreatmentHours()) or 24)
end

local function hasMedicalRecoveryNeed(worker)
    return worker
        and (isIncapacitated(worker)
            or (Health.GetCurrent(worker) + 0.0001) < Health.GetMax(worker))
end

local function isAssignedToInfirmary(worker)
    return DC_Colony.Medical
        and DC_Colony.Medical.IsAssignedToInfirmary
        and DC_Colony.Medical.IsAssignedToInfirmary(worker)
        or false
end

local function isDoctorCovered(worker)
    return DC_Colony.Medical
        and DC_Colony.Medical.IsDoctorCovered
        and DC_Colony.Medical.IsDoctorCovered(worker)
        or false
end

local function getSelfTreatmentTierDef(tierID)
    local resolvedID = tostring(tierID or "clean_rag")
    local tierDef = SELF_TREATMENT_TIERS[resolvedID]
    if tierDef then
        return resolvedID, tierDef
    end

    return "clean_rag", SELF_TREATMENT_TIERS.clean_rag
end

local function clearSelfTreatmentPresentation(worker)
    if not worker then
        return
    end

    worker.selfTreatmentActive = false
    worker.selfTreatmentTierID = nil
    worker.selfTreatmentLabel = nil
    worker.selfTreatmentItemFullType = nil
    worker.selfTreatmentHealRemaining = 0
    worker.selfTreatmentRegenPerHour = 0
end

local function syncSelfTreatmentPresentation(worker, state)
    if not worker then
        return
    end

    if type(state) ~= "table" then
        clearSelfTreatmentPresentation(worker)
        return
    end

    worker.selfTreatmentActive = true
    worker.selfTreatmentTierID = state.tierID
    worker.selfTreatmentLabel = state.label
    worker.selfTreatmentItemFullType = state.itemFullType
    worker.selfTreatmentHealRemaining = math.max(0, tonumber(state.healRemaining) or 0)
    worker.selfTreatmentRegenPerHour = math.max(0, tonumber(state.regenPerHour) or 0)
end

local function getSelfTreatmentState(worker)
    local state = type(worker and worker.selfTreatmentState) == "table" and worker.selfTreatmentState or nil
    if state then
        local tierID, tierDef = getSelfTreatmentTierDef(state.tierID)
        local treatmentHours = getSelfTreatmentHours()
        state.tierID = tierID
        state.label = tostring(state.label or tierDef.label or "bandage")
        state.itemFullType = tostring(state.itemFullType or tierDef.iconFullType or "Base.Bandage")
        state.healRemaining = math.max(0, tonumber(state.healRemaining) or 0)
        state.regenPerHour = math.max(
            0,
            tonumber(state.regenPerHour)
                or ((math.max(0, tonumber(tierDef.totalHeal) or 0) - math.max(0, tonumber(tierDef.applyHeal) or 0))
                    / treatmentHours)
        )
        worker.selfTreatmentState = state
        syncSelfTreatmentPresentation(worker, state)
    else
        clearSelfTreatmentPresentation(worker)
    end
    return state
end

local function clearSelfTreatmentState(worker)
    if worker then
        worker.selfTreatmentState = nil
        clearSelfTreatmentPresentation(worker)
    end
end

local function beginSelfTreatment(worker, missingHealth)
    if not worker or missingHealth <= 0 then
        return 0, nil
    end

    local companion = DC_Colony and DC_Colony.Companion or nil
    if not companion or not companion.ConsumeBandageSupply then
        return 0, nil
    end

    local consumed = companion.ConsumeBandageSupply(worker.workerID)
    if not consumed or not consumed.tierID then
        return 0, nil
    end

    local tierID, tierDef = getSelfTreatmentTierDef(consumed.tierID)
    local treatmentHours = getSelfTreatmentHours()
    local immediateHeal = math.min(
        missingHealth,
        math.max(0, tonumber(tierDef.applyHeal) or 0)
    )
    local totalHeal = math.max(0, tonumber(tierDef.totalHeal) or 0)
    local remainingHeal = math.max(0, totalHeal - immediateHeal)

    worker.selfTreatmentState = {
        tierID = tierID,
        label = tostring(tierDef.label or "bandage"),
        itemFullType = tostring(tierDef.iconFullType or consumed.fullType or "Base.Bandage"),
        healRemaining = remainingHeal,
        regenPerHour = remainingHeal / treatmentHours,
    }
    syncSelfTreatmentPresentation(worker, worker.selfTreatmentState)

    appendMedicalLog(
        worker,
        "Applied a " .. tostring(tierDef.label or "bandage") .. " while resting to recover."
    )

    return immediateHeal, worker.selfTreatmentState
end

local function applySelfTreatment(worker, supportedHours, currentHp, hpMax)
    if not worker then
        return currentHp, 0
    end

    if currentHp >= hpMax then
        clearSelfTreatmentState(worker)
        return currentHp, 0
    end

    if supportedHours <= 0 then
        return currentHp, 0
    end

    local state = getSelfTreatmentState(worker)
    local totalAdded = 0
    local missingHealth = math.max(0, hpMax - currentHp)

    if (not state or (tonumber(state.healRemaining) or 0) <= 0) and missingHealth > 0 then
        local immediateHeal, nextState = beginSelfTreatment(worker, missingHealth)
        if immediateHeal > 0 then
            totalAdded = totalAdded + immediateHeal
            currentHp = math.min(hpMax, currentHp + immediateHeal)
            missingHealth = math.max(0, hpMax - currentHp)
        end
        state = nextState
    end

    if not state or (tonumber(state.healRemaining) or 0) <= 0 or missingHealth <= 0 then
        if missingHealth <= 0 then
            clearSelfTreatmentState(worker)
        end
        return currentHp, totalAdded
    end

    local regenPerHour = math.max(0, tonumber(state.regenPerHour) or 0)
    local overTimeHeal = math.min(
        missingHealth,
        math.max(0, tonumber(state.healRemaining) or 0),
        supportedHours * regenPerHour
    )

    if overTimeHeal > 0 then
        totalAdded = totalAdded + overTimeHeal
        currentHp = math.min(hpMax, currentHp + overTimeHeal)
        state.healRemaining = math.max(0, (tonumber(state.healRemaining) or 0) - overTimeHeal)
    end

    if currentHp + 0.0001 >= hpMax or (tonumber(state.healRemaining) or 0) <= 0 then
        clearSelfTreatmentState(worker)
    else
        syncSelfTreatmentPresentation(worker, state)
    end

    return currentHp, totalAdded
end

function Health.ApplyDeprivationDamage(worker, deprivedHours)
    if not worker or deprivedHours <= 0 then
        return Health.GetCurrent(worker)
    end
    
    local damage = deprivedHours * (Config.GetHealthLossPerHour and Config.GetHealthLossPerHour() or 1)
    return Health.SetCurrent(worker, Health.GetCurrent(worker) - damage)
end

function Health.IsSleepEligible(worker, forcedRest)
    return worker
        and isHome(worker)
        and not isDead(worker)
        and (forcedRest == true or hasMedicalRecoveryNeed(worker))
end

function Health.GetSleepHealingRate(worker, forcedRest)
    if not Health.IsSleepEligible(worker, forcedRest) then
        return 0
    end

    local baseRate = getBaseSleepHealRate(worker)
    local healingRate = baseRate
    if isAssignedToInfirmary(worker) then
        healingRate = math.max(healingRate, getInfirmarySleepHealRate(worker))
    end
    if isDoctorCovered(worker) then
        healingRate = math.max(healingRate, getDoctorSleepHealRate(worker))
    end

    local treatmentState = getSelfTreatmentState(worker)
    if treatmentState and (tonumber(treatmentState.healRemaining) or 0) > 0 then
        healingRate = healingRate + math.max(0, tonumber(treatmentState.regenPerHour) or 0)
    end

    if baseRate <= 0 then
        return 0
    end

    return healingRate / baseRate
end

function Health.ApplySleepHealing(worker, forcedRest, supportedHours)
    local baseRate = getBaseSleepHealRate(worker)
    local infirmaryRate = getInfirmarySleepHealRate(worker)
    local treatedRate = getDoctorSleepHealRate(worker)
    local hp = Health.GetCurrent(worker)
    local hpMax = Health.GetMax(worker)
    local inInfirmary = isAssignedToInfirmary(worker)
    local healingRate = inInfirmary and math.max(baseRate, infirmaryRate) or baseRate

    worker.sleepHealingRate = 0
    worker.sleepHealingSource = "None"
    worker.medicalSupplyBlocked = false
    
    if not Health.IsSleepEligible(worker, forcedRest) then
        clearSelfTreatmentState(worker)
        return hp, supportedHours, 0
    end

    if supportedHours <= 0 then
        return hp, supportedHours, 0
    end

    if hp >= hpMax then
        clearSelfTreatmentState(worker)
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
    hp, selfTreatmentHealing = applySelfTreatment(worker, supportedHours, hp, hpMax)
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

    if isDoctorCovered(worker) and boostedHours < supportedHours then
        worker.medicalSupplyBlocked = true
    end

    return hp, supportedHours, boostedHours
end

return Health
