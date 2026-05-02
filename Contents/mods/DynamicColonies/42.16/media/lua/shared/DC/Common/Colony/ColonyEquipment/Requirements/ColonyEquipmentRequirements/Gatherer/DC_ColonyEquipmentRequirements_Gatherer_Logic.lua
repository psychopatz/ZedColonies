DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

local function getGatherer()
    return DC_Colony and DC_Colony.Gatherer or nil
end

local gathererKeys = (getGatherer() and getGatherer().RequirementKeys) or {}
local gathererKeyMap = {
    [tostring(gathererKeys.Axe or "Gatherer.Tool.Axe")] = true,
    [tostring(gathererKeys.Pickaxe or "Gatherer.Tool.Pickaxe")] = true,
    [tostring(gathererKeys.Sack or "Gatherer.Tool.Sack")] = true,
    [tostring(gathererKeys.FluidContainer or "Gatherer.Tool.FluidContainer")] = true,
}

local previousCanWorkerUseEquipmentRequirement = Config.CanWorkerUseEquipmentRequirement
function Config.CanWorkerUseEquipmentRequirement(worker, requirementKey)
    if previousCanWorkerUseEquipmentRequirement and not previousCanWorkerUseEquipmentRequirement(worker, requirementKey) then
        return false
    end

    local key = tostring(requirementKey or "")
    if gathererKeyMap[key] ~= true then
        return true
    end

    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
    if normalizedJob ~= tostring((Config.JobTypes or {}).Gatherer or "Gatherer") then
        return false
    end

    local gatherer = getGatherer()
    if not gatherer or not gatherer.GetRequirementStatus then
        return true
    end

    local status = gatherer.GetRequirementStatus(worker, key)
    return status and status.relevant == true or false
end

local previousGetWorkerEquipmentRequirementDefinitions = Config.GetWorkerEquipmentRequirementDefinitions
function Config.GetWorkerEquipmentRequirementDefinitions(worker)
    local definitions = previousGetWorkerEquipmentRequirementDefinitions and previousGetWorkerEquipmentRequirementDefinitions(worker) or {}
    local gatherer = getGatherer()
    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
    if normalizedJob ~= tostring((Config.JobTypes or {}).Gatherer or "Gatherer")
        or not gatherer
        or not gatherer.GetRequirementStatus then
        return definitions
    end

    local decorated = {}
    for _, definition in ipairs(definitions or {}) do
        local copy = {}
        for key, value in pairs(definition or {}) do
            copy[key] = value
        end

        local status = gatherer.GetRequirementStatus(worker, copy.requirementKey)
        if status and status.relevant == true then
            copy.currentCount = math.max(0, tonumber(status.currentCount) or 0)
            copy.minimumCount = math.max(0, tonumber(status.minimumCount) or 0)
            copy.targetCount = math.max(0, tonumber(status.targetCount) or 0)
            copy.blocking = status.blocking == true
            copy.statusText = tostring(status.statusText or copy.hintText or "")
            decorated[#decorated + 1] = copy
        elseif gathererKeyMap[tostring(copy.requirementKey or "")] ~= true then
            decorated[#decorated + 1] = copy
        end
    end

    return decorated
end

return Config
