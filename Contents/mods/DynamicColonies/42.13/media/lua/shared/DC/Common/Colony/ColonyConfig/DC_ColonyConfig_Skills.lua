DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

Config.SKILL_MODEL_VERSION = 4

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
    if normalizedJob == Config.JobTypes.Builder then
        return "Construction"
    end
    if normalizedJob == Config.JobTypes.Doctor then
        return "Medical"
    end
    if normalizedJob == Config.JobTypes.Farm then
        return "Plants"
    end
    if normalizedJob == Config.JobTypes.Fish then
        return "Animals"
    end
    if normalizedJob == Config.JobTypes.Scavenge then
        return Config.GetScavengeSiteSkillID(worker and worker.scavengeSiteProfileID)
    end
    return nil
end

return Config
