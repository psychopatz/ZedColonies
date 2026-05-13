DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegInternal or {}

function Internal.EnsureActivityLog(worker)
    if not worker then
        return {}
    end

    worker.activityLog = Internal.EnsureArray(worker.activityLog)
    local limit = math.max(1, tonumber(Config.WORKER_ACTIVITY_LOG_LIMIT) or 40)
    while #worker.activityLog > limit do
        table.remove(worker.activityLog, 1)
    end
    return worker.activityLog
end

function Internal.AppendActivityLog(worker, message, worldHour, category)
    if not worker or not message or tostring(message) == "" then
        return
    end

    local activityLog = Internal.EnsureActivityLog(worker)
    activityLog[#activityLog + 1] = {
        hour = tonumber(worldHour) or ((Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()),
        text = tostring(message),
        category = tostring(category or "general")
    }

    local limit = math.max(1, tonumber(Config.WORKER_ACTIVITY_LOG_LIMIT) or 40)
    while #activityLog > limit do
        table.remove(activityLog, 1)
    end
end

function Internal.EnsureWorkerCacheState(worker)
    if not worker then
        return
    end

    if worker.nutritionCacheDirty == nil then
        worker.nutritionCacheDirty = worker.storedCalories == nil or worker.storedHydration == nil
    end
    if worker.toolCacheDirty == nil then
        worker.toolCacheDirty = worker.assignedToolTags == nil
    end
    if worker.outputCacheDirty == nil then
        worker.outputCacheDirty = worker.outputCount == nil
    end
end

function Internal.MarkNutritionCacheDirty(worker)
    if worker then
        worker.nutritionCacheDirty = true
    end
end

function Internal.MarkToolCacheDirty(worker)
    if worker then
        worker.toolCacheDirty = true
    end
end

function Internal.MarkOutputCacheDirty(worker)
    if worker then
        worker.outputCacheDirty = true
    end
end

function Internal.ApplyNutritionCacheDelta(worker, caloriesDelta, hydrationDelta)
    if not worker then
        return false
    end

    Internal.EnsureWorkerCacheState(worker)
    if worker.nutritionCacheDirty then
        return false
    end

    worker.storedCalories = math.max(0, (tonumber(worker.storedCalories) or 0) + (tonumber(caloriesDelta) or 0))
    worker.storedHydration = math.max(0, (tonumber(worker.storedHydration) or 0) + (tonumber(hydrationDelta) or 0))
    return true
end

function Internal.ApplyToolTags(worker, tags)
    if not worker then
        return false
    end

    Internal.EnsureWorkerCacheState(worker)
    if worker.toolCacheDirty then
        return false
    end

    worker.assignedToolTags = type(worker.assignedToolTags) == "table" and worker.assignedToolTags or {}
    for _, tag in ipairs(tags or {}) do
        worker.assignedToolTags[tag] = true
    end
    return true
end

function Internal.ApplyOutputCountDelta(worker, qtyDelta)
    if not worker then
        return false
    end

    Internal.EnsureWorkerCacheState(worker)
    if worker.outputCacheDirty then
        return false
    end

    worker.outputCount = math.max(0, (tonumber(worker.outputCount) or 0) + (tonumber(qtyDelta) or 0))
    return true
end

function Internal.ResetOutputCount(worker)
    if not worker then
        return
    end

    worker.outputCount = 0
    worker.outputWeight = 0
    worker.outputCacheDirty = false
end

function Internal.BuildStarterNutritionLedger(template)
    local existing = Internal.CopyShallow(template and template.nutritionLedger or nil)
    if #existing > 0 then
        return existing
    end

    return existing
end

function Internal.GetStarterReserveTotals(template)
    local existing = Internal.CopyShallow(template and template.nutritionLedger or nil)
    local templateCalories = tonumber(template and template.caloriesCached) or 0
    local templateHydration = tonumber(template and template.hydrationCached) or 0
    if #existing > 0 then
        return templateCalories, templateHydration
    end
    if templateCalories > 0 or templateHydration > 0 then
        return templateCalories, templateHydration
    end

    local starterCalories = Config.RandomRangeInclusive(
        Config.RECRUIT_START_CALORIES_MIN,
        Config.RECRUIT_START_CALORIES_MAX
    )
    local starterHydration = Config.RandomRangeInclusive(
        Config.RECRUIT_START_HYDRATION_MIN,
        Config.RECRUIT_START_HYDRATION_MAX
    )

    return starterCalories, starterHydration
end

return Data