DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

local Research = DC_Colony.Research
local Internal = Research.Internal

local function getDisplayName(fullType)
    local registry = DC_Colony and DC_Colony.Registry or nil
    local internal = registry and registry.Internal or nil
    return internal and internal.GetDisplayNameForFullType and internal.GetDisplayNameForFullType(fullType) or tostring(fullType or "Unknown")
end

local function getCategoryDisplayName(categoryId)
    local config = DC_Colony and DC_Colony.Config or nil
    local definition = config and config.GetItemCategoryDefinition and config.GetItemCategoryDefinition(categoryId) or nil
    return tostring(definition and definition.displayName or categoryId or "Unknown")
end

local function copyInputEntries(inputs)
    local entries = {}
    for _, input in ipairs(inputs or {}) do
        local categoryId = tostring(input and input.category or "")
        entries[#entries + 1] = {
            category = categoryId,
            displayName = getCategoryDisplayName(categoryId),
            count = math.max(0, math.floor(tonumber(input and input.count) or 0)),
        }
    end
    return entries
end

local function countBlueprintsByBuilding(blueprints)
    local counts = {}
    for _, blueprint in ipairs(blueprints or {}) do
        local buildingType = tostring(blueprint and blueprint.buildingType or "")
        if buildingType ~= "" then
            counts[buildingType] = math.max(0, tonumber(counts[buildingType]) or 0) + 1
        end
    end
    return counts
end

function Research.GetClientSnapshot(ownerUsername)
    local data = Internal.EnsureOwnerData(ownerUsername)
    if not data then
        return nil
    end

    local queue = {}
    for _, job in ipairs(data.queue or {}) do
        local progressHours = math.max(0, tonumber(job and job.progressHours) or 0)
        local requiredHours = math.max(1, tonumber(job and job.requiredHours) or 1)
        queue[#queue + 1] = {
            jobID = tostring(job and job.jobID or ""),
            fullType = tostring(job and job.fullType or ""),
            displayName = getDisplayName(job and job.fullType),
            category = tostring(job and job.category or ""),
            categoryDisplayName = getCategoryDisplayName(job and job.category),
            group = tostring(job and job.group or ""),
            progressHours = progressHours,
            requiredHours = requiredHours,
            progressRatio = math.max(0, math.min(1, progressHours / requiredHours)),
        }
    end

    local blueprints = {}
    for fullType, blueprint in pairs(data.blueprints or {}) do
        blueprints[#blueprints + 1] = {
            fullType = tostring(fullType or ""),
            displayName = getDisplayName(fullType),
            buildingType = tostring(blueprint and blueprint.buildingType or ""),
            category = tostring(blueprint and blueprint.category or ""),
            categoryDisplayName = getCategoryDisplayName(blueprint and blueprint.category),
            group = tostring(blueprint and blueprint.group or ""),
            inputs = copyInputEntries(blueprint and blueprint.inputs),
            workCost = math.max(1, math.floor(tonumber(blueprint and blueprint.workCost) or 1)),
        }
    end

    table.sort(queue, function(a, b)
        local aRatio = tonumber(a and a.progressRatio) or 0
        local bRatio = tonumber(b and b.progressRatio) or 0
        if aRatio == bRatio then
            return tostring(a and a.displayName or a and a.fullType or "") < tostring(b and b.displayName or b and b.fullType or "")
        end
        return aRatio > bRatio
    end)

    table.sort(blueprints, function(a, b)
        return tostring(a and a.displayName or a and a.fullType or "") < tostring(b and b.displayName or b and b.fullType or "")
    end)

    return {
        ownerUsername = tostring(data.ownerUsername or ""),
        version = math.max(1, math.floor(tonumber(data.version) or 1)),
        queueCount = #queue,
        unlockedCount = #blueprints,
        queue = queue,
        blueprints = blueprints,
        blueprintCountsByBuilding = countBlueprintsByBuilding(blueprints),
    }
end

function Research.GetBuildingMetrics(ownerUsername, instance)
    if type(instance) ~= "table" then
        return {}
    end

    local buildingType = tostring(instance.buildingType or "")
    local snapshot = Research.GetClientSnapshot(ownerUsername)
    if not snapshot then
        return {}
    end

    local metrics = {
        unlockedBlueprintCountForBuilding = math.max(0, tonumber(snapshot.blueprintCountsByBuilding and snapshot.blueprintCountsByBuilding[buildingType]) or 0),
    }

    if buildingType == "ResearchStation" then
        local activeJob = snapshot.queue and snapshot.queue[1] or nil
        metrics.researchQueueCount = snapshot.queueCount
        metrics.unlockedBlueprintCount = snapshot.unlockedCount
        metrics.activeResearch = activeJob
        metrics.researchQueue = {}
        metrics.unlockedBlueprintPreview = {}

        for index = 1, math.min(5, #snapshot.queue) do
            metrics.researchQueue[#metrics.researchQueue + 1] = snapshot.queue[index]
        end
        for index = 1, math.min(8, #snapshot.blueprints) do
            metrics.unlockedBlueprintPreview[#metrics.unlockedBlueprintPreview + 1] = snapshot.blueprints[index]
        end
    end

    return metrics
end

return Research
