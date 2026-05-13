local Panel = DC_ColonySkillPanel
local Internal = Panel.Internal
local FlavorText = Internal.FlavorText or {}

function Internal.getPrimarySkill(subject)
    for _, skillID in ipairs(Internal.DISPLAY_ORDER or {}) do
        local skill = subject and subject.skills and subject.skills[skillID] or nil
        if skill and skill.primary then
            return skill
        end
    end

    local bestSkill = nil
    for _, skillID in ipairs(Internal.DISPLAY_ORDER or {}) do
        local skill = subject and subject.skills and subject.skills[skillID] or nil
        if skill and (not bestSkill or (tonumber(skill.level) or 0) > (tonumber(bestSkill.level) or 0)) then
            bestSkill = skill
        end
    end

    return bestSkill
end

function Internal.getBaselineLevel(subject, skill)
    local level = math.floor(tonumber(skill and skill.level) or 0)
    local baseSkill = subject and subject.baseSkills and subject.baseSkills[skill and skill.id or ""] or nil
    local baseLevel = math.floor(tonumber(baseSkill and baseSkill.level) or level)
    return math.max(0, math.min(level, baseLevel))
end

function Internal.getRemainingXPLabel(skill)
    if not skill or skill.isCapped then
        return tostring(FlavorText.capReached or "Cap reached")
    end

    local xpToNext = math.max(0, math.floor(tonumber(skill.xpToNext) or 0))
    local currentXP = math.max(0, math.floor(tonumber(skill.xp) or 0))
    local remainingXP = math.max(0, xpToNext - currentXP)
    return tostring(remainingXP) .. tostring(FlavorText.xpToNextSuffix or " XP to next")
end

return Panel