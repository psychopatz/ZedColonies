require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"

DT_Labour = DT_Labour or {}
DT_Labour.Skills = DT_Labour.Skills or {}

local Config = DT_Labour.Config
local Skills = DT_Labour.Skills

local HASH_MOD = 2147483647

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = deepCopy(entry)
    end
    return copy
end

local function clamp(value, minimum, maximum)
    local amount = tonumber(value) or 0
    if amount < minimum then
        return minimum
    end
    if amount > maximum then
        return maximum
    end
    return amount
end

local function stableHash(...)
    local parts = { ... }
    local hash = 17
    for _, part in ipairs(parts) do
        local text = tostring(part or "")
        for index = 1, #text do
            hash = ((hash * 31) + text:byte(index)) % HASH_MOD
        end
    end
    return hash
end

local function rollInclusive(archetypeID, identitySeed, skillID, tag, minValue, maxValue)
    local minLevel = math.floor(tonumber(minValue) or 0)
    local maxLevel = math.max(minLevel, math.floor(tonumber(maxValue) or minLevel))
    if maxLevel <= minLevel then
        return minLevel
    end

    local hash = stableHash(archetypeID, identitySeed, skillID, tag or "roll")
    return minLevel + (hash % (maxLevel - minLevel + 1))
end

local function getSkillOrder()
    return Config.SkillOrder or {}
end

local function getSkillLabel(skillID)
    return Config.GetSkillDisplayName and Config.GetSkillDisplayName(skillID) or tostring(skillID or "Unknown")
end

local function isSecondarySkill(profile, skillID)
    for _, secondarySkillID in ipairs(profile and profile.secondarySkills or {}) do
        if secondarySkillID == skillID then
            return true
        end
    end
    return false
end

function Skills.GetXPToNextLevel(level)
    local safeLevel = math.max(0, math.floor(tonumber(level) or 0))
    return math.floor(100 + (safeLevel * 50) + (safeLevel * safeLevel * 10))
end

function Skills.ResolvePreviewSkills(archetypeID, identitySeed)
    local profile = Config.GetArchetypeSkillProfile and Config.GetArchetypeSkillProfile(archetypeID) or nil
    local normalizedArchetypeID = Config.NormalizeArchetypeID and Config.NormalizeArchetypeID(archetypeID) or tostring(archetypeID or "General")
    local normalizedSeed = math.max(1, math.floor(tonumber(identitySeed) or 1))
    local preview = {}

    for _, skillID in ipairs(getSkillOrder()) do
        local capRange = profile and profile.baseRanges and profile.baseRanges[skillID] or { min = 0, max = 8 }
        local masteryChance = math.max(
            0,
            math.min(100, math.floor(tonumber(profile and profile.masteryChances and profile.masteryChances[skillID]) or 0))
        )
        local rangeMin = math.max(0, math.floor(tonumber(capRange.min or capRange[1]) or 0))
        local rangeMax = math.max(rangeMin, math.floor(tonumber(capRange.max or capRange[2]) or rangeMin))
        rangeMin = math.min(rangeMin, 19)
        rangeMax = math.min(rangeMax, 19)

        local cap = math.max(
            1,
            math.min(19, rollInclusive(normalizedArchetypeID, normalizedSeed, skillID, "cap", rangeMin, rangeMax))
        )
        local mastered = masteryChance > 0
            and rollInclusive(normalizedArchetypeID, normalizedSeed, skillID, "mastery", 1, 100) <= masteryChance
        if mastered then
            cap = 20
        end

        local levelMin = 0
        local levelMax = 0
        if profile and profile.primarySkill == skillID then
            levelMin = math.floor(cap * 0.20)
            levelMax = math.floor(cap * 0.75)
        elseif isSecondarySkill(profile, skillID) then
            levelMin = math.floor(cap * 0.05)
            levelMax = math.floor(cap * 0.45)
        else
            levelMin = 0
            levelMax = math.floor(cap * 0.25)
        end
        levelMax = math.max(levelMin, math.min(cap, levelMax))

        local level = rollInclusive(
            normalizedArchetypeID,
            normalizedSeed,
            skillID,
            "level",
            levelMin,
            levelMax
        )
        level = math.max(0, math.min(level, cap))

        preview[skillID] = {
            id = skillID,
            label = getSkillLabel(skillID),
            level = level,
            xp = 0,
            cap = cap,
            xpRate = math.max(0.1, tonumber(profile and profile.xpRate and profile.xpRate[skillID]) or 1.0),
            primary = profile and profile.primarySkill == skillID or false,
            secondary = isSecondarySkill(profile, skillID),
            mastery = masteryChance > 0,
            masteryChance = masteryChance,
            perfectCap = mastered,
            previewOnly = true
        }
    end

    return preview
end

function Skills.EnsureWorkerSkills(worker)
    if not worker then
        return nil
    end

    local targetVersion = tonumber(Config.SKILL_MODEL_VERSION) or 1
    local profile = Config.GetArchetypeSkillProfile and Config.GetArchetypeSkillProfile(worker.archetypeID) or nil
    local preview = Skills.ResolvePreviewSkills(worker.archetypeID, worker.identitySeed)
    local existing = type(worker.skills) == "table" and worker.skills or {}
    local normalized = {}

    for _, skillID in ipairs(getSkillOrder()) do
        local previewEntry = preview[skillID] or {}
        local storedEntry = type(existing[skillID]) == "table" and existing[skillID] or nil
        local cap = math.max(1, math.min(20, math.floor(tonumber(previewEntry.cap) or 10)))
        local level = storedEntry and storedEntry.level or previewEntry.level or 0
        local xp = storedEntry and storedEntry.xp or previewEntry.xp or 0

        normalized[skillID] = {
            id = skillID,
            label = getSkillLabel(skillID),
            level = math.floor(clamp(level, 0, cap)),
            xp = math.max(0, math.floor(tonumber(xp) or 0)),
            cap = cap,
            xpRate = math.max(0.1, tonumber(storedEntry and storedEntry.xpRate or previewEntry.xpRate) or 1.0),
            primary = profile and profile.primarySkill == skillID or previewEntry.primary == true,
            secondary = isSecondarySkill(profile, skillID) or previewEntry.secondary == true,
            mastery = (tonumber(storedEntry and storedEntry.masteryChance) or tonumber(previewEntry.masteryChance) or 0) > 0,
            masteryChance = math.max(
                0,
                math.min(100, math.floor(tonumber(storedEntry and storedEntry.masteryChance) or tonumber(previewEntry.masteryChance) or 0))
            ),
            perfectCap = previewEntry.perfectCap == true or tonumber(cap) >= 20
        }
    end

    worker.skills = normalized
    worker.skillModelVersion = targetVersion
    return worker.skills
end

function Skills.GetSkillEntry(source, skillID)
    if not source or not skillID then
        return nil
    end

    if type(source.skills) == "table" and source.skills[skillID] then
        return source.skills[skillID]
    end

    if source.workerID then
        local normalized = Skills.EnsureWorkerSkills(source)
        return normalized and normalized[skillID] or nil
    end

    local preview = Skills.ResolvePreviewSkills(source.archetypeID, source.identitySeed)
    return preview[skillID]
end

function Skills.GetPrimarySkillID(source)
    local profile = Config.GetArchetypeSkillProfile and Config.GetArchetypeSkillProfile(source and source.archetypeID) or nil
    return profile and profile.primarySkill or nil
end

function Skills.BuildClientSkillSnapshot(skillEntries, previewOnly)
    local snapshot = {}
    for _, skillID in ipairs(getSkillOrder()) do
        local entry = skillEntries and skillEntries[skillID] or nil
        if entry then
            local level = math.floor(tonumber(entry.level) or 0)
            local cap = math.max(1, math.floor(tonumber(entry.cap) or 10))
            local xpToNext = level >= cap and 0 or Skills.GetXPToNextLevel(level)
            local xp = level >= cap and 0 or math.max(0, math.floor(tonumber(entry.xp) or 0))
            snapshot[skillID] = {
                id = skillID,
                label = getSkillLabel(skillID),
                level = level,
                xp = xp,
                xpToNext = xpToNext,
                xpProgressRatio = xpToNext > 0 and clamp(xp / xpToNext, 0, 1) or 1,
                cap = cap,
                isCapped = level >= cap,
                primary = entry.primary == true,
                secondary = entry.secondary == true,
                mastery = entry.mastery == true,
                masteryChance = math.max(0, math.min(100, math.floor(tonumber(entry.masteryChance) or 0))),
                perfectCap = entry.perfectCap == true or cap >= 20,
                xpRate = math.max(0.1, tonumber(entry.xpRate) or 1.0),
                previewOnly = previewOnly == true or entry.previewOnly == true
            }
        end
    end
    return snapshot
end

function Skills.BuildClientSkillSnapshotForWorker(worker)
    local entries = Skills.EnsureWorkerSkills(worker)
    return Skills.BuildClientSkillSnapshot(entries, false)
end

function Skills.BuildPreviewSkillSnapshot(archetypeID, identitySeed)
    return Skills.BuildClientSkillSnapshot(Skills.ResolvePreviewSkills(archetypeID, identitySeed), true)
end

function Skills.GetWorkerJobEffects(worker, profile)
    local skillID = Config.GetWorkerJobSkillID and Config.GetWorkerJobSkillID(worker, profile) or nil
    local entry = skillID and Skills.GetSkillEntry(worker, skillID) or nil
    local level = math.max(0, math.floor(tonumber(entry and entry.level) or 0))

    return {
        skillID = skillID,
        skillLabel = skillID and getSkillLabel(skillID) or nil,
        level = level,
        speedMultiplier = clamp(0.70 + (0.04 * level), 0.70, 1.50),
        yieldMultiplier = clamp(0.85 + (0.02 * level), 0.85, 1.25),
        botchChanceMultiplier = clamp(1.20 - (0.04 * level), 0.35, 1.20)
    }
end

function Skills.GrantXP(worker, skillID, amount)
    if not worker or not worker.workerID or not skillID then
        return nil
    end

    local entries = Skills.EnsureWorkerSkills(worker)
    local entry = entries and entries[skillID] or nil
    local rawAmount = math.max(0, tonumber(amount) or 0)
    if not entry or rawAmount <= 0 then
        return nil
    end

    if tonumber(entry.level) >= tonumber(entry.cap) then
        entry.xp = 0
        return {
            skillID = skillID,
            granted = 0,
            oldLevel = entry.level,
            newLevel = entry.level,
            leveledUp = 0,
            reachedCap = true
        }
    end

    local scaledAmount = math.max(1, math.floor((rawAmount * (tonumber(entry.xpRate) or 1.0)) + 0.5))
    local oldLevel = entry.level
    local leveledUp = 0
    entry.xp = math.max(0, math.floor(tonumber(entry.xp) or 0)) + scaledAmount

    while entry.level < entry.cap do
        local threshold = Skills.GetXPToNextLevel(entry.level)
        if entry.xp < threshold then
            break
        end
        entry.xp = entry.xp - threshold
        entry.level = entry.level + 1
        leveledUp = leveledUp + 1
    end

    local reachedCap = entry.level >= entry.cap
    if reachedCap then
        entry.level = entry.cap
        entry.xp = 0
    end

    return {
        skillID = skillID,
        granted = scaledAmount,
        oldLevel = oldLevel,
        newLevel = entry.level,
        leveledUp = leveledUp,
        reachedCap = reachedCap
    }
end

return Skills
