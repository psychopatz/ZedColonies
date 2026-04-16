DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.ResolveWorkerFromCommandContext(workerOrNPC)
    local registry = Internal.GetRegistry()
    if type(workerOrNPC) ~= "table" then
        return nil
    end
    if workerOrNPC.workerID then
        return workerOrNPC
    end
    local linkedWorkerID = workerOrNPC.linkedWorkerID
    if linkedWorkerID and registry and registry.GetWorkerRaw then
        return registry.GetWorkerRaw(linkedWorkerID)
    end
    return nil
end

function Internal.GetWorkerSkillLevel(worker, skillID)
    local common = Config and Config.Common or nil
    if common and common.GetWorkerSkillLevel then
        return math.max(0, math.floor(tonumber(common.GetWorkerSkillLevel(worker, skillID)) or 0))
    end

    local skills = DC_Colony and DC_Colony.Skills or nil
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, skillID) or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

function Internal.GetSkillsModule()
    local skills = DC_Colony and DC_Colony.Skills or nil
    if skills and skills.GrantXP and skills.EnsureWorkerSkills then
        return skills
    end

    pcall(function()
        require "DC/Common/Colony/ColonySkills/DC_ColonySkills"
    end)

    skills = DC_Colony and DC_Colony.Skills or nil
    if skills and skills.GrantXP and skills.EnsureWorkerSkills then
        return skills
    end

    return nil
end