DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Research = DC_Colony.Research
local Internal = Research.Internal

local function getOwnerKey(ownerUsername)
    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

local function getDataKey(ownerUsername)
    local owner = getOwnerKey(ownerUsername)
    local colonyID = Registry.GetColonyIDForOwner and Registry.GetColonyIDForOwner(owner, true) or owner
    return "DColony_Research_" .. tostring(colonyID)
end

function Internal.EnsureOwnerData(ownerUsername)
    local key = getDataKey(ownerUsername)
    local data = Registry and Registry.Internal and Registry.Internal.EnsureModDataTable
        and Registry.Internal.EnsureModDataTable(key, {
            ownerUsername = getOwnerKey(ownerUsername),
            queue = {},
            blueprints = {},
            version = 1,
            lastProcessedHour = -1,
            nextJobID = 1,
        }) or nil
    if data then
        data.ownerUsername = getOwnerKey(ownerUsername)
        data.queue = type(data.queue) == "table" and data.queue or {}
        data.blueprints = type(data.blueprints) == "table" and data.blueprints or {}
        data.version = math.max(1, math.floor(tonumber(data.version) or 1))
        data.lastProcessedHour = tonumber(data.lastProcessedHour) or -1
        data.nextJobID = math.max(1, math.floor(tonumber(data.nextJobID) or 1))

        for index, job in ipairs(data.queue) do
            local blueprint = job and job.blueprint or nil
            if (not blueprint or tostring(blueprint.fullType or "") == "") and Research and Research.Internal and Research.Internal.BuildBlueprintRecord then
                blueprint = Research.Internal.BuildBlueprintRecord(job and job.fullType)
                if blueprint then
                    job.blueprint = blueprint
                end
            end

            local requiredWork = math.max(
                1,
                math.floor(
                    tonumber(job and job.requiredWork)
                    or tonumber(blueprint and blueprint.workCost)
                    or tonumber(Research and Research.Config and Research.Config.GetBaseWork and Research.Config.GetBaseWork())
                    or 1000
                )
            )
            if tonumber(job and job.progressWork) == nil then
                local oldProgress = math.max(0, tonumber(job and job.progressHours) or 0)
                local oldRequired = math.max(1, tonumber(job and job.requiredHours) or 1)
                job.progressWork = requiredWork * math.max(0, math.min(1, oldProgress / oldRequired))
            end

            job.requiredWork = requiredWork
            job.sampleCount = math.max(1, math.floor(tonumber(job and job.sampleCount) or 1))
            job.category = tostring(job and job.category or blueprint and blueprint.category or "")
            job.group = tostring(job and job.group or blueprint and blueprint.group or "")
            job.buildingType = tostring(job and job.buildingType or blueprint and blueprint.buildingType or "")
            job.recipeName = tostring(job and job.recipeName or blueprint and blueprint.recipeName or "")
            job.lastWorkRate = math.max(0, tonumber(job and job.lastWorkRate) or 0)
            job.lastSampleMultiplier = math.max(1, tonumber(job and job.lastSampleMultiplier) or job.sampleCount)
            job.lastIntelligenceMultiplier = math.max(1, tonumber(job and job.lastIntelligenceMultiplier) or 1)
            job.lastResearcherLevel = math.max(0, tonumber(job and job.lastResearcherLevel) or 0)
            job.lastResearcherName = tostring(job and job.lastResearcherName or "")
            data.queue[index] = job
        end

        for fullType, blueprint in pairs(data.blueprints) do
            if Research and Research.Internal and Research.Internal.BuildBlueprintRecord then
                local refreshed = Research.Internal.BuildBlueprintRecord(fullType)
                if refreshed then
                    data.blueprints[fullType] = refreshed
                else
                    data.blueprints[fullType] = blueprint
                end
            end
        end
    end
    return data
end

function Internal.Touch(ownerUsername)
    local data = Internal.EnsureOwnerData(ownerUsername)
    if data then
        data.version = math.max(1, math.floor(tonumber(data.version) or 1)) + 1
    end
    return data
end

function Internal.NextJobID(ownerUsername)
    local data = Internal.EnsureOwnerData(ownerUsername)
    if not data then
        return ""
    end

    local nextID = math.max(1, math.floor(tonumber(data.nextJobID) or 1))
    data.nextJobID = nextID + 1
    return tostring(data.ownerUsername or getOwnerKey(ownerUsername)) .. "_research_" .. tostring(nextID)
end

return Research
