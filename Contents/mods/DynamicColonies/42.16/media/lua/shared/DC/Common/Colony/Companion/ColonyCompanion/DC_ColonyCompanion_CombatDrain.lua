DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.GetCompanionCombatSkillID(attackType)
    local mode = tostring(attackType or "")
    if mode == "ranged" then
        return "Shooting"
    end
    if mode == "melee" then
        return "Melee"
    end
    return nil
end

function Internal.GetCompanionCombatDrainPerAttack(worker, attackType)
    local skillID = Internal.GetCompanionCombatSkillID(attackType)
    if not skillID then
        return 0, nil, 0, 1
    end

    local skillLevel = Internal.GetWorkerSkillLevel(worker, skillID)
    local baseDrain
    if skillID == "Shooting" then
        baseDrain = (Config.GetEnergyRangedCombatDrainPerAttack and Config.GetEnergyRangedCombatDrainPerAttack(worker))
            or (Config.GetTirednessRangedCombatDrainPerAttack and Config.GetTirednessRangedCombatDrainPerAttack(worker))
            or 0.70
    else
        baseDrain = (Config.GetEnergyMeleeCombatDrainPerAttack and Config.GetEnergyMeleeCombatDrainPerAttack(worker))
            or (Config.GetTirednessMeleeCombatDrainPerAttack and Config.GetTirednessMeleeCombatDrainPerAttack(worker))
            or 0.90
    end

    local reductionPerLevel = (Config.GetEnergyCombatDrainReductionPerSkillLevel and Config.GetEnergyCombatDrainReductionPerSkillLevel(worker))
        or (Config.GetTirednessCombatDrainReductionPerSkillLevel and Config.GetTirednessCombatDrainReductionPerSkillLevel(worker))
        or 0.025
    local minMultiplier = (Config.GetEnergyCombatDrainMinMultiplier and Config.GetEnergyCombatDrainMinMultiplier(worker))
        or (Config.GetTirednessCombatDrainMinMultiplier and Config.GetTirednessCombatDrainMinMultiplier(worker))
        or 0.35

    local multiplier = math.max(minMultiplier, 1 - (skillLevel * reductionPerLevel))
    return math.max(0, baseDrain * multiplier), skillID, skillLevel, multiplier
end