DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.RecordCombatAttack(workerID, npcData, attackType, options)
    local registry = Internal.GetRegistry()
    local worker = workerID and registry and registry.GetWorkerRaw and registry.GetWorkerRaw(workerID) or nil
    if not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false
    end

    local skillID = Internal.GetCompanionCombatSkillID(attackType)
    if not skillID then
        return false
    end

    local energy = DC_Colony and DC_Colony.Energy or nil
    local beforeEnergy = energy and energy.GetCurrent and energy.GetCurrent(worker) or nil
    local drainAmount, _, skillLevel, drainMultiplier = Internal.GetCompanionCombatDrainPerAttack(worker, attackType)
    local energyApplied = false
    if energy and energy.SetCurrent and beforeEnergy ~= nil and drainAmount > 0 then
        energy.SetCurrent(worker, beforeEnergy - drainAmount)
        energyApplied = true
    end

    local skills = Internal.GetSkillsModule()
    local xpAmount = Config.GetCompanionCombatXPPerAttack and Config.GetCompanionCombatXPPerAttack(attackType, worker) or 1
    local xpResult = nil
    if skills and skills.EnsureWorkerSkills then
        skills.EnsureWorkerSkills(worker)
    end
    if skills and skills.GrantXP and xpAmount > 0 then
        xpResult = skills.GrantXP(worker, skillID, xpAmount)
    end

    if registry and registry.RecalculateWorker then
        registry.RecalculateWorker(worker)
    end

    local xpGranted = tonumber(xpResult and xpResult.granted) or 0
    local leveledUp = tonumber(xpResult and xpResult.leveledUp) or 0
    if energyApplied or xpGranted > 0 then
        local companionData = Internal.GetCompanionData(worker)
        local currentMs = Internal.GetCurrentMillis()
        local lastSavedAt = tonumber(companionData and companionData.combatProgressSavedAt) or 0
        local shouldSaveNow = leveledUp > 0
            or currentMs <= 0
            or lastSavedAt <= 0
            or (currentMs - lastSavedAt) >= 4000

        if shouldSaveNow then
            if companionData then
                companionData.combatProgressSavedAt = currentMs
            end
            Internal.SaveRegistry()
        end
    end

    if energy and energy.IsDepleted and energy.IsDepleted(worker) then
        local lowEnergyReason = Config.ReturnReasons and (Config.ReturnReasons.LowEnergy or Config.ReturnReasons.LowTiredness) or "LowEnergy"
        if energy.BeginForcedRest then
            energy.BeginForcedRest(worker, Internal.GetCurrentWorldHours(), lowEnergyReason, "Too tired for companion duty. Returning home to rest.")
        end
        Internal.BeginWorkerCompanionReturn(nil, worker, lowEnergyReason)
    end

    return true, {
        attackType = attackType,
        skillID = skillID,
        skillLevel = skillLevel,
        drainApplied = drainAmount,
        drainMultiplier = drainMultiplier,
        xpResult = xpResult,
    }
end