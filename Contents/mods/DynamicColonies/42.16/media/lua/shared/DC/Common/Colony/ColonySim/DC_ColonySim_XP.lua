local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Skills = DC_Colony.Skills

local function buildXPAmount(totalQuantity)
    return math.max(10, 20 + math.min(20, math.floor(tonumber(totalQuantity) or 0) * 3))
end

function Sim.grantWorkerJobXP(worker, currentHour, skillEffects, totalQuantity)
    if not Skills or not Skills.GrantXP or not skillEffects or not skillEffects.skillID then
        return
    end

    local result = Skills.GrantXP(worker, skillEffects.skillID, buildXPAmount(totalQuantity))
    if not result or (tonumber(result.granted) or 0) <= 0 then
        return
    end

    local message = "Earned "
        .. tostring(math.floor((tonumber(result.granted) or 0) + 0.5))
        .. " "
        .. tostring(skillEffects.skillLabel or skillEffects.skillID or "Skill")
        .. " XP."

    if (tonumber(result.leveledUp) or 0) > 0 then
        message = message
            .. " "
            .. tostring(skillEffects.skillLabel or skillEffects.skillID or "Skill")
            .. " increased to level "
            .. tostring(result.newLevel)
            .. "."
    end

    Internal.appendWorkerLog(worker, message, currentHour, "skills")
end
