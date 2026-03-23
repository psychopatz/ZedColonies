DT_Labour = DT_Labour or {}
DT_Labour.Warehouse = DT_Labour.Warehouse or {}
DT_Labour.Warehouse.Internal = DT_Labour.Warehouse.Internal or {}

local Config = DT_Labour.Config
local Nutrition = DT_Labour.Nutrition
local Registry = DT_Labour.Registry
local Warehouse = DT_Labour.Warehouse
local AUTO_SCAVENGE_TOOL_TAGS = {
    "Scavenge.Haul.Bag"
}

local function workerHasToolTag(worker, requiredTag)
    Registry.RecalculateWorker(worker)
    local tagMap = worker and worker.assignedToolTags or {}
    for itemTag, enabled in pairs(tagMap or {}) do
        if enabled and Config.TagMatches and Config.TagMatches(itemTag, requiredTag) then
            return true
        end
    end
    return false
end

local function takeFirstEquipmentEntry(ownerUsername, predicate)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    for index, entry in ipairs(warehouse.ledgers.equipment or {}) do
        if predicate(entry) then
            local removed = table.remove(warehouse.ledgers.equipment, index)
            Warehouse.Recalculate(warehouse)
            return removed
        end
    end
    return nil
end

local function getEntryTags(entry)
    if not entry then
        return {}
    end

    if type(entry.tags) == "table" and #entry.tags > 0 then
        return entry.tags
    end

    if Config.GetItemCombinedTags and entry.fullType then
        return Config.GetItemCombinedTags(entry.fullType) or {}
    end

    return entry.tags or {}
end

local function entryHasToolTag(entry, requiredTag)
    for _, itemTag in ipairs(getEntryTags(entry)) do
        if Config.TagMatches and Config.TagMatches(itemTag, requiredTag) then
            return true
        end
    end
    return false
end

local function takeFirstEquipmentEntryByTag(ownerUsername, requiredTag)
    return takeFirstEquipmentEntry(ownerUsername, function(candidate)
        return entryHasToolTag(candidate, requiredTag)
    end)
end

local function restockRequiredTools(worker)
    if not worker then
        return 0
    end

    local added = 0
    local profile = Config.GetJobProfile and Config.GetJobProfile(worker.jobType) or {}

    for _, requiredTag in ipairs(profile.requiredToolTags or {}) do
        if not workerHasToolTag(worker, requiredTag) then
            local entry = takeFirstEquipmentEntryByTag(worker.ownerUsername, requiredTag)
            if entry then
                Registry.AddToolEntry(worker, entry)
                added = added + 1
            end
        end
    end

    if Config.NormalizeJobType and Config.NormalizeJobType(worker.jobType) == ((Config.JobTypes or {}).Scavenge) then
        local hasScavengeTool = workerHasToolTag(worker, "Labour.Tool.Scavenge")
        if not hasScavengeTool then
            local entry = takeFirstEquipmentEntryByTag(worker.ownerUsername, "Labour.Tool.Scavenge")
            if entry then
                Registry.AddToolEntry(worker, entry)
                added = added + 1
            end
        end

        for _, requiredTag in ipairs(AUTO_SCAVENGE_TOOL_TAGS) do
            if not workerHasToolTag(worker, requiredTag) then
                local entry = takeFirstEquipmentEntryByTag(worker.ownerUsername, requiredTag)
                if entry then
                    Registry.AddToolEntry(worker, entry)
                    added = added + 1
                end
            end
        end
    end

    return added
end

local function findBestProvisionIndex(warehouse, needCalories, needHydration)
    local bestIndex = nil
    local bestScore = -1

    for index, entry in ipairs(warehouse and warehouse.ledgers and warehouse.ledgers.provisions or {}) do
        if not (Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry)) then
            local calories = math.max(0, tonumber(entry.caloriesRemaining) or 0)
            local hydration = math.max(0, tonumber(entry.hydrationRemaining) or 0)
            local score = 0

            if needCalories > 0 then
                score = score + math.min(needCalories, calories)
            end
            if needHydration > 0 then
                score = score + math.min(needHydration, hydration)
            end
            if score > bestScore then
                bestIndex = index
                bestScore = score
            end
        end
    end

    return bestIndex
end

local function recordProvisionName(sampleNames, entry, hiddenCount)
    local displayName = tostring(entry and (entry.displayName or entry.fullType) or "provisions")
    if #sampleNames < 2 then
        sampleNames[#sampleNames + 1] = displayName
        return hiddenCount
    end
    return hiddenCount + 1
end

local function restockProvisions(worker, dailyCaloriesNeed, dailyHydrationNeed)
    if not worker then
        return 0, 0, 0, {}, 0
    end

    local targetCalories = math.max(0, tonumber(dailyCaloriesNeed) or 0) * 2
    local targetHydration = math.max(0, tonumber(dailyHydrationNeed) or 0) * 2
    local totalCalories, totalHydration = Nutrition.GetTotalAvailableAmounts(worker)
    local warehouse = Warehouse.GetOwnerWarehouse(worker.ownerUsername)
    local movedCalories = 0
    local movedHydration = 0
    local movedCount = 0
    local sampleNames = {}
    local hiddenCount = 0
    local safetyCounter = 0

    while safetyCounter < 512 and (totalCalories < targetCalories or totalHydration < targetHydration) do
        local index = findBestProvisionIndex(
            warehouse,
            math.max(0, targetCalories - totalCalories),
            math.max(0, targetHydration - totalHydration)
        )
        if not index then
            break
        end

        local entry = table.remove(warehouse.ledgers.provisions, index)
        if not entry then
            break
        end

        Registry.AddNutritionEntry(worker, entry)
        movedCalories = movedCalories + math.max(0, tonumber(entry.caloriesRemaining) or 0)
        movedHydration = movedHydration + math.max(0, tonumber(entry.hydrationRemaining) or 0)
        movedCount = movedCount + 1
        hiddenCount = recordProvisionName(sampleNames, entry, hiddenCount)
        totalCalories = totalCalories + math.max(0, tonumber(entry.caloriesRemaining) or 0)
        totalHydration = totalHydration + math.max(0, tonumber(entry.hydrationRemaining) or 0)
        safetyCounter = safetyCounter + 1
    end

    Warehouse.Recalculate(warehouse)
    return movedCalories, movedHydration, movedCount, sampleNames, hiddenCount
end

function Warehouse.RestockWorker(worker, dailyCaloriesNeed, dailyHydrationNeed)
    if not worker then
        return {
            calories = 0,
            hydration = 0,
            tools = 0,
            provisionCount = 0,
            provisionSampleNames = {},
            provisionHiddenCount = 0,
        }
    end

    local calories, hydration, provisionCount, provisionSampleNames, provisionHiddenCount =
        restockProvisions(worker, dailyCaloriesNeed, dailyHydrationNeed)
    local tools = restockRequiredTools(worker)
    Registry.RecalculateWorker(worker)
    return {
        calories = calories,
        hydration = hydration,
        tools = tools,
        provisionCount = provisionCount,
        provisionSampleNames = provisionSampleNames,
        provisionHiddenCount = provisionHiddenCount,
    }
end

return Warehouse
