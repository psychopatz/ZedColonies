DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Validation = Internal.ProjectValidation or {}

Internal.ProjectValidation = Validation

function Validation.GetColonyConfig()
    return DC_Colony and DC_Colony.Config or {}
end

function Validation.GetRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

function Validation.GetSkills()
    return DC_Colony and DC_Colony.Skills or nil
end

function Validation.GetOwnerUsername(playerOrUsername)
    local labourConfig = Validation.GetColonyConfig()
    return labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(playerOrUsername) or tostring(playerOrUsername or "local")
end

function Validation.GetWorkerConstructionLevel(worker)
    local skills = Validation.GetSkills()
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, "Construction") or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

function Validation.NormalizeMode(mode)
    local normalized = tostring(mode or "build")
    if normalized == "upgrade" or normalized == "install" then
        return normalized
    end
    return "build"
end

function Validation.GetProjectDefinition(buildingType, targetLevel, mode, installKey, plotX, plotY)
    local config = Validation.Config or Buildings.Config
    if Validation.NormalizeMode(mode) == "install" then
        return config.GetInstallDefinition and config.GetInstallDefinition(buildingType, installKey) or nil
    end
    if tostring(buildingType or "") == "Barricade"
        and config.Frontier
        and config.Frontier.GetBarricadeLevelDefinition then
        return config.Frontier.GetBarricadeLevelDefinition(targetLevel, plotX, plotY)
    end
    return config.GetLevelDefinition(buildingType, targetLevel)
end

Internal.NormalizeMode = Validation.NormalizeMode
Internal.GetProjectDefinition = Validation.GetProjectDefinition

return Buildings