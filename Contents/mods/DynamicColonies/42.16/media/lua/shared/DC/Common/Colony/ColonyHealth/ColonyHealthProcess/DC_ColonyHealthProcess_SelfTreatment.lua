DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}

local Health = DC_Colony.Health
local FlavorText = DC_Colony.Health.ProcessFlavorText or {}

Health.Internal = Health.Internal or {}
Health.Internal.Process = Health.Internal.Process or {}

local Process = Health.Internal.Process

local SELF_TREATMENT_TIERS = {
    clean_rag = {
        label = tostring(((FlavorText.selfTreatmentLabels or {}).clean_rag) or "clean rag"),
        totalHeal = 20,
        applyHeal = 2,
        iconFullType = "Base.RippedSheets",
    },
    sterilized_rag = {
        label = tostring(((FlavorText.selfTreatmentLabels or {}).sterilized_rag) or "sterilized rag"),
        totalHeal = 28,
        applyHeal = 3,
        iconFullType = "Base.AlcoholRippedSheets",
    },
    bandage = {
        label = tostring(((FlavorText.selfTreatmentLabels or {}).bandage) or "bandage"),
        totalHeal = 36,
        applyHeal = 4,
        iconFullType = "Base.Bandage",
    },
}

function Process.getSelfTreatmentTierDef(tierID)
    local resolvedID = tostring(tierID or "clean_rag")
    local tierDef = SELF_TREATMENT_TIERS[resolvedID]
    if tierDef then
        return resolvedID, tierDef
    end

    return "clean_rag", SELF_TREATMENT_TIERS.clean_rag
end

function Process.clearSelfTreatmentPresentation(worker)
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

function Process.syncSelfTreatmentPresentation(worker, state)
    if not worker then
        return
    end

    if type(state) ~= "table" then
        Process.clearSelfTreatmentPresentation(worker)
        return
    end

    worker.selfTreatmentActive = true
    worker.selfTreatmentTierID = state.tierID
    worker.selfTreatmentLabel = state.label
    worker.selfTreatmentItemFullType = state.itemFullType
    worker.selfTreatmentHealRemaining = math.max(0, tonumber(state.healRemaining) or 0)
    worker.selfTreatmentRegenPerHour = math.max(0, tonumber(state.regenPerHour) or 0)
end

function Process.getSelfTreatmentState(worker)
    local state = type(worker and worker.selfTreatmentState) == "table" and worker.selfTreatmentState or nil
    if state then
        local tierID, tierDef = Process.getSelfTreatmentTierDef(state.tierID)
        local treatmentHours = Process.getSelfTreatmentHours()
        state.tierID = tierID
        state.label = tostring(state.label or tierDef.label or FlavorText.selfTreatmentFallbackLabel or "bandage")
        state.itemFullType = tostring(state.itemFullType or tierDef.iconFullType or "Base.Bandage")
        state.healRemaining = math.max(0, tonumber(state.healRemaining) or 0)
        state.regenPerHour = math.max(
            0,
            tonumber(state.regenPerHour)
                or ((math.max(0, tonumber(tierDef.totalHeal) or 0) - math.max(0, tonumber(tierDef.applyHeal) or 0))
                    / treatmentHours)
        )
        worker.selfTreatmentState = state
        Process.syncSelfTreatmentPresentation(worker, state)
    else
        Process.clearSelfTreatmentPresentation(worker)
    end
    return state
end

function Process.clearSelfTreatmentState(worker)
    if worker then
        worker.selfTreatmentState = nil
        Process.clearSelfTreatmentPresentation(worker)
    end
end

function Process.beginSelfTreatment(worker, missingHealth)
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

    local tierID, tierDef = Process.getSelfTreatmentTierDef(consumed.tierID)
    local treatmentHours = Process.getSelfTreatmentHours()
    local immediateHeal = math.min(
        missingHealth,
        math.max(0, tonumber(tierDef.applyHeal) or 0)
    )
    local totalHeal = math.max(0, tonumber(tierDef.totalHeal) or 0)
    local remainingHeal = math.max(0, totalHeal - immediateHeal)

    worker.selfTreatmentState = {
        tierID = tierID,
        label = tostring(tierDef.label or FlavorText.selfTreatmentFallbackLabel or "bandage"),
        itemFullType = tostring(tierDef.iconFullType or consumed.fullType or "Base.Bandage"),
        healRemaining = remainingHeal,
        regenPerHour = remainingHeal / treatmentHours,
    }
    Process.syncSelfTreatmentPresentation(worker, worker.selfTreatmentState)

    Process.appendMedicalLog(
        worker,
        string.format(
            tostring(FlavorText.selfTreatmentAppliedMessage or "Applied a %s while resting to recover."),
            tostring(tierDef.label or FlavorText.selfTreatmentFallbackLabel or "bandage")
        )
    )

    return immediateHeal, worker.selfTreatmentState
end

function Process.applySelfTreatment(worker, supportedHours, currentHp, hpMax)
    if not worker then
        return currentHp, 0
    end

    if currentHp >= hpMax then
        Process.clearSelfTreatmentState(worker)
        return currentHp, 0
    end

    if supportedHours <= 0 then
        return currentHp, 0
    end

    local state = Process.getSelfTreatmentState(worker)
    local totalAdded = 0
    local missingHealth = math.max(0, hpMax - currentHp)

    if (not state or (tonumber(state.healRemaining) or 0) <= 0) and missingHealth > 0 then
        local immediateHeal, nextState = Process.beginSelfTreatment(worker, missingHealth)
        if immediateHeal > 0 then
            totalAdded = totalAdded + immediateHeal
            currentHp = math.min(hpMax, currentHp + immediateHeal)
            missingHealth = math.max(0, hpMax - currentHp)
        end
        state = nextState
    end

    if not state or (tonumber(state.healRemaining) or 0) <= 0 or missingHealth <= 0 then
        if missingHealth <= 0 then
            Process.clearSelfTreatmentState(worker)
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
        Process.clearSelfTreatmentState(worker)
    else
        Process.syncSelfTreatmentPresentation(worker, state)
    end

    return currentHp, totalAdded
end

return Process