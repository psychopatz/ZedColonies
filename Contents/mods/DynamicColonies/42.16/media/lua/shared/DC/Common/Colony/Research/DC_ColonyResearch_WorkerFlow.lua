DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

local Research = DC_Colony.Research
local Internal = Research.Internal
local AbstractInventory = DC_Colony.AbstractInventory

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

    AbstractInventory.TakeLiteralSpecial(ownerUsername, 1, function(entry)
        return tostring(entry and entry.researchJobID or "") == tostring(job.jobID)
            and tostring(entry and entry.specialStockType or "") == "research_specimen"
    end, {
        reason = "research_complete",
        jobID = job.jobID,
        fullType = job.fullType,
    })
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
        job.progressHours = math.max(0, tonumber(job.progressHours) or 0) + deltaHours
        if job.progressHours + 0.0001 >= math.max(1, tonumber(job.requiredHours) or 1) then
            data.blueprints[job.fullType] = Internal.BuildBlueprintRecord(job.fullType)
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
