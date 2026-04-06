DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}

local Config = DC_Colony.Config

Config.HEALTH_BASE_HP_BY_ARCHETYPE = Config.HEALTH_BASE_HP_BY_ARCHETYPE or {
    General = 120,
    Teacher = 110,
    Librarian = 110,
    Tailor = 115,
    Bartender = 120,
    Chef = 125,
    Doctor = 125,
    Angler = 130,
    Burglar = 130,
    Welder = 130,
    Mechanic = 135,
    Hiker = 135,
    Foreman = 140,
    Athlete = 145,
    Sheriff = 160,
    Survivalist = 170,
}

local function getWorkerSkillLevel(worker, skillID)
    local common = Config and Config.Common or nil
    if common and common.GetWorkerSkillLevel then
        return math.max(0, math.floor(tonumber(common.GetWorkerSkillLevel(worker, skillID)) or 0))
    end

    local skills = DC_Colony and DC_Colony.Skills or nil
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, skillID) or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

function Config.GetHealthMax(worker)
    local archetypeID = Config.NormalizeArchetypeID and Config.NormalizeArchetypeID(worker and worker.archetypeID) or tostring(worker and worker.archetypeID or "General")
    local baseTemplate = tonumber(Config.HEALTH_BASE_HP_BY_ARCHETYPE[archetypeID])
        or tonumber(Config.HEALTH_BASE_HP_BY_ARCHETYPE.General)
        or tonumber(Config.DEFAULT_WORKER_MAX_HP)
        or 100
    local baseMultiplier = 1.0
    local sandbox = SandboxVars and SandboxVars.DynamicTrading or nil
    if sandbox and tonumber(sandbox.NPCBaseHealthMultiplier) and tonumber(sandbox.NPCBaseHealthMultiplier) > 0 then
        baseMultiplier = tonumber(sandbox.NPCBaseHealthMultiplier)
    end

    local skills = DC_Colony and DC_Colony.Skills or nil
    if skills and skills.EnsureWorkerSkills and worker then
        skills.EnsureWorkerSkills(worker)
    end

    local baseMax = math.max(1, math.floor((baseTemplate * baseMultiplier) + 0.5))
    local melee = getWorkerSkillLevel(worker, "Melee")
    local shooting = getWorkerSkillLevel(worker, "Shooting")
    local maintenance = getWorkerSkillLevel(worker, "Maintenance")
    local skillBonus = math.min(50, math.floor((melee * 2) + (shooting * 2) + maintenance))
    local computedMax = math.max(1, math.floor(baseMax + skillBonus))
    local seededMax = math.max(0, tonumber(worker and worker.maxHp) or tonumber(worker and worker.healthMax) or 0)
    return math.max(seededMax, computedMax)
end

function Config.GetHealthLossPerHour(worker)
    return math.max(0, tonumber(Config.WORKER_HP_LOSS_PER_HOUR) or 1)
end

function Config.GetHealthRegenPerHour(worker)
    return math.max(0, tonumber(Config.WORKER_HP_REGEN_PER_HOUR) or 1)
end

-- Fallback constants if not loaded from Core yet
Config.DEFAULT_WORKER_MAX_HP = Config.DEFAULT_WORKER_MAX_HP or 100
Config.WORKER_HP_LOSS_PER_HOUR = Config.WORKER_HP_LOSS_PER_HOUR or 1
Config.WORKER_HP_REGEN_PER_HOUR = Config.WORKER_HP_REGEN_PER_HOUR or 1

return DC_Colony.Health
