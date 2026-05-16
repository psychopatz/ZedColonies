DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

local Research = DC_Colony.Research
local Internal = Research.Internal
local AbstractInventory = DC_Colony.AbstractInventory

local function findQueuedJobByFullType(queue, fullType)
    local wanted = tostring(fullType or "")
    for _, job in ipairs(queue or {}) do
        if tostring(job and job.fullType or "") == wanted then
            return job
        end
    end
    return nil
end

function Research.SubmitResearchItem(ownerUsername, fullType, itemMeta)
    local normalizedFullType = tostring(fullType or "")
    if normalizedFullType == "" then
        return false, "Missing item fullType."
    end
    if Research.IsBlueprintUnlocked(ownerUsername, normalizedFullType) then
        return false, "Blueprint already unlocked."
    end

    local data = Internal.EnsureOwnerData(ownerUsername)
    local blueprint = Internal.BuildBlueprintRecord and Internal.BuildBlueprintRecord(normalizedFullType) or nil
    if not blueprint then
        return false, "That item needs a valid craft recipe before it can be researched."
    end

    local existingJob = findQueuedJobByFullType(data.queue, normalizedFullType)
    if not existingJob and #data.queue >= (Research.Config and Research.Config.GetMaxQueueSize and Research.Config.GetMaxQueueSize() or 1) then
        return false, "Research queue is full."
    end

    local jobID = existingJob and existingJob.jobID or Internal.NextJobID(ownerUsername)
    if itemMeta == nil or itemMeta.storeSpecimen ~= false then
        local added = AbstractInventory and AbstractInventory.AddLiteralSpecial and AbstractInventory.AddLiteralSpecial(ownerUsername, {
            fullType = normalizedFullType,
            qty = 1,
            forceLiteral = true,
            literalSpecial = true,
            specialStockType = "research_specimen",
            researchJobID = jobID,
        }) or 0
        if added <= 0 then
            return false, "No storage space for the research specimen."
        end
    end

    if existingJob then
        existingJob.sampleCount = math.max(1, math.floor(tonumber(existingJob.sampleCount) or 1)) + 1
        existingJob.submittedAt = itemMeta and itemMeta.submittedAt or existingJob.submittedAt
        existingJob.blueprint = blueprint
        existingJob.requiredWork = math.max(1, math.floor(tonumber(blueprint and blueprint.workCost) or 1))
        existingJob.buildingType = blueprint.buildingType
        existingJob.recipeName = blueprint.recipeName
        existingJob.category = blueprint.category
        existingJob.group = blueprint.group
    else
        data.queue[#data.queue + 1] = {
            jobID = jobID,
            fullType = normalizedFullType,
            submittedAt = itemMeta and itemMeta.submittedAt or 0,
            progressWork = 0,
            requiredWork = math.max(1, math.floor(tonumber(blueprint and blueprint.workCost) or 1)),
            sampleCount = 1,
            category = blueprint.category,
            group = blueprint.group,
            buildingType = blueprint.buildingType,
            recipeName = blueprint.recipeName,
            blueprint = blueprint,
            lastWorkRate = 0,
            lastSampleMultiplier = 1,
            lastIntelligenceMultiplier = 1,
            lastResearcherLevel = 0,
            lastResearcherName = "",
        }
    end
    Internal.Touch(ownerUsername)
    return true, nil
end

return Research
