DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

local Research = DC_Colony.Research
local Internal = Research.Internal
local AbstractInventory = DC_Colony.AbstractInventory
local Registry = DC_Colony.Registry
local Skills = DC_Colony.Skills
local Config = DC_Colony.Config

local function hasResearchStation(ownerUsername)
    local buildings = DC_Buildings
    for _, instance in ipairs(buildings and buildings.GetBuildingsForOwner and buildings.GetBuildingsForOwner(ownerUsername) or {}) do
        if tostring(instance and instance.buildingType or "") == "ResearchStation"
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            return true
        end
    end
    return false
end

local function releaseCompletedSpecimen(ownerUsername, job)
    if not (AbstractInventory and AbstractInventory.TakeLiteralSpecial and job and job.jobID) then
        return
    end

    AbstractInventory.TakeLiteralSpecial(ownerUsername, math.max(1, math.floor(tonumber(job.sampleCount) or 1)), function(entry)
        return tostring(entry and entry.researchJobID or "") == tostring(job.jobID)
            and tostring(entry and entry.specialStockType or "") == "research_specimen"
    end, {
        reason = "research_complete",
        jobID = job.jobID,
        fullType = job.fullType,
    })
end

function Internal.GetResearchLeadStats(ownerUsername)
    local bestName = ""
    local bestLevel = 0
    local deadState = tostring(Config and Config.States and Config.States.Dead or "Dead")

    for _, worker in ipairs(Registry and Registry.GetWorkersForOwnerRaw and Registry.GetWorkersForOwnerRaw(ownerUsername) or {}) do
        if tostring(worker and worker.state or "") ~= deadState then
            local entry = Skills and Skills.GetSkillEntry and Skills.GetSkillEntry(worker, "Intellectual") or nil
            local level = math.max(0, math.floor(tonumber(entry and entry.level) or 0))
            if level > bestLevel or bestName == "" then
                bestLevel = level
                bestName = tostring(worker and worker.name or worker and worker.workerID or "")
            end
        end
    end

    return {
        name = bestName,
        level = bestLevel,
    }
end

local function getWorkRate(ownerUsername, sampleCount)
    local lead = Internal.GetResearchLeadStats and Internal.GetResearchLeadStats(ownerUsername) or {
        name = "",
        level = 0,
    }
    local sampleMultiplier = Research.Config and Research.Config.GetSampleMultiplier
        and Research.Config.GetSampleMultiplier(sampleCount) or math.max(1, math.floor(tonumber(sampleCount) or 1))
    local intelligenceMultiplier = Research.Config and Research.Config.GetIntelligenceWorkMultiplier
        and Research.Config.GetIntelligenceWorkMultiplier(lead.level) or 1
    local baseRate = Research.Config and Research.Config.GetBaseWorkPerHour and Research.Config.GetBaseWorkPerHour() or 125

    return {
        leadResearcherName = tostring(lead and lead.name or ""),
        leadResearcherLevel = math.max(0, math.floor(tonumber(lead and lead.level) or 0)),
        sampleMultiplier = sampleMultiplier,
        intelligenceMultiplier = intelligenceMultiplier,
        workPerHour = math.max(1, tonumber(baseRate) or 125) * sampleMultiplier * intelligenceMultiplier,
    }
end

function Research.ProcessOwner(ownerUsername, currentHour)
    local data = Internal.EnsureOwnerData(ownerUsername)
    if not data then
        return 0
    end
    if not hasResearchStation(ownerUsername) then
        data.lastProcessedHour = tonumber(currentHour) or tonumber(data and data.lastProcessedHour) or -1
        return 0
    end

    local lastHour = tonumber(data.lastProcessedHour) or -1
    data.lastProcessedHour = tonumber(currentHour) or lastHour
    if lastHour < 0 then
        return 0
    end

    local deltaHours = math.max(0, (tonumber(currentHour) or lastHour) - lastHour)
    if deltaHours <= 0 then
        return 0
    end

    local completed = 0
    local index = 1
    while index <= #data.queue do
        local job = data.queue[index]
        local workRate = getWorkRate(ownerUsername, job and job.sampleCount)
        job.lastWorkRate = math.max(0, tonumber(workRate and workRate.workPerHour) or 0)
        job.lastSampleMultiplier = math.max(1, tonumber(workRate and workRate.sampleMultiplier) or 1)
        job.lastIntelligenceMultiplier = math.max(1, tonumber(workRate and workRate.intelligenceMultiplier) or 1)
        job.lastResearcherLevel = math.max(0, tonumber(workRate and workRate.leadResearcherLevel) or 0)
        job.lastResearcherName = tostring(workRate and workRate.leadResearcherName or "")
        job.progressWork = math.max(0, tonumber(job.progressWork) or 0) + (deltaHours * job.lastWorkRate)
        if job.progressWork + 0.0001 >= math.max(1, tonumber(job.requiredWork) or 1) then
            local blueprint = job.blueprint or (Internal.BuildBlueprintRecord and Internal.BuildBlueprintRecord(job.fullType)) or nil
            if blueprint then
                data.blueprints[job.fullType] = blueprint
            end
            releaseCompletedSpecimen(ownerUsername, job)
            table.remove(data.queue, index)
            completed = completed + 1
            Internal.Touch(ownerUsername)
        else
            index = index + 1
        end
    end

    return completed
end

function Research.ProcessAllOwners(currentHour)
    local registry = DC_Colony and DC_Colony.Registry or nil
    local completed = 0
    for _, ownerUsername in ipairs(registry and registry.GetOwnerUsernames and registry.GetOwnerUsernames() or {}) do
        completed = completed + Research.ProcessOwner(ownerUsername, currentHour)
    end
    return completed
end

return Research
