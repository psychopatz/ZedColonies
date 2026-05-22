DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

Config.SKILL_MODEL_VERSION = 4
Config.DEFAULT_COMPANION_COMBAT_XP_MELEE_PER_ATTACK = 1
Config.DEFAULT_COMPANION_COMBAT_XP_RANGED_PER_ATTACK = 1

Config.SkillDefinitions = {}
Config.SkillOrder = {}
Config.SkillLabels = {}

for _, skillData in ipairs(DynamicTrading.SkillDefinitions or {}) do
    Config.SkillDefinitions[#Config.SkillDefinitions + 1] = {
        id = skillData.id,
        label = skillData.label or skillData.id
    }
    Config.SkillOrder[#Config.SkillOrder + 1] = skillData.id
    Config.SkillLabels[skillData.id] = skillData.label or skillData.id
end

Config.ScavengeSiteSkillMap = {
    Unknown = "Construction",
    Residential = "Construction",
    Warehouse = "Crafting",
    AutoShop = "Crafting",
    Medical = "Medical",
    ElectronicsStore = "Intellectual",
    Office = "Intellectual",
    GunStore = "Shooting"
}

function Config.GetSkillDefinition(skillID)
    for _, skillData in ipairs(Config.SkillDefinitions or {}) do
        if skillData.id == skillID then
            return skillData
        end
    end
    return nil
end

function Config.GetSkillDisplayName(skillID)
    return tostring((Config.SkillLabels and Config.SkillLabels[skillID]) or skillID or "Unknown")
end

function Config.GetArchetypeSkillProfile(archetypeID)
    if DynamicTrading and DynamicTrading.GetArchetypeSkillProfile then
        return DynamicTrading.GetArchetypeSkillProfile(Config.NormalizeArchetypeID(archetypeID))
    end
    return nil
end

function Config.GetScavengeSiteSkillID(siteProfileID)
    local profileID = tostring(siteProfileID or "Unknown")
    return (Config.ScavengeSiteSkillMap and Config.ScavengeSiteSkillMap[profileID]) or "Construction"
end

function Config.GetWorkerJobSkillID(worker, profile)
    local normalizedJob = Config.NormalizeJobType(worker and worker.jobType or profile and profile.jobType)
    if normalizedJob == Config.JobTypes.Unemployed then
        return nil
    end
    -- Dynamic cases that cannot be expressed as a static field in JobProfiles:
    if normalizedJob == Config.JobTypes.Scavenge then
        return Config.GetScavengeSiteSkillID(worker and worker.scavengeSiteProfileID)
    end
    if normalizedJob == Config.JobTypes.Gatherer then
        local gatherer = DC_Colony and DC_Colony.Gatherer or nil
        if gatherer and gatherer.GetPrimarySkillID then
            return gatherer.GetPrimarySkillID(worker)
        end
        return "Construction"
    end
    if normalizedJob == Config.JobTypes.ChopTrees then
        return "Plants"
    end
    if normalizedJob == Config.JobTypes.Guard then
        local meleeLevel = 0
        local shootingLevel = 0
        if DC_Colony and DC_Colony.Skills then
            local meleeEntry = DC_Colony.Skills.GetSkillEntry and DC_Colony.Skills.GetSkillEntry(worker, "Melee") or nil
            meleeLevel = math.max(0, math.floor(tonumber(meleeEntry and meleeEntry.level) or 0))
            local shootingEntry = DC_Colony.Skills.GetSkillEntry and DC_Colony.Skills.GetSkillEntry(worker, "Shooting") or nil
            shootingLevel = math.max(0, math.floor(tonumber(shootingEntry and shootingEntry.level) or 0))
        end
        if shootingLevel > meleeLevel then
            return "Shooting"
        end
        return "Melee"
    end
    -- Static cases: read skillID from the job profile definition.
    local jobProfile = Config.JobProfiles and Config.JobProfiles[normalizedJob] or nil
    return jobProfile and jobProfile.skillID or nil
end

function Config.GetCompanionCombatXPPerAttack(attackType, worker)
    local mode = tostring(attackType or "")
    if mode == "ranged" then
        return math.max(0, tonumber(Config.DEFAULT_COMPANION_COMBAT_XP_RANGED_PER_ATTACK) or 1)
    end
    if mode == "melee" then
        return math.max(0, tonumber(Config.DEFAULT_COMPANION_COMBAT_XP_MELEE_PER_ATTACK) or 1)
    end
    return 0
end

return Config
