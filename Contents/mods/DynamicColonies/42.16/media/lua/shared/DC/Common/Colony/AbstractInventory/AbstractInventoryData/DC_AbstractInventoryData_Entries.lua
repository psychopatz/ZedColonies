DC_Colony = DC_Colony or {}
DC_Colony.AbstractInventory = DC_Colony.AbstractInventory or {}
DC_Colony.AbstractInventory.Internal = DC_Colony.AbstractInventory.Internal or {}

local Config = DC_Colony.Config
local AbstractInventory = DC_Colony.AbstractInventory
local Internal = AbstractInventory.Internal
local Data = Internal.Data or {}

Internal.Data = Data

local function getWarehouse()
    return DC_Colony and DC_Colony.Warehouse or nil
end

local function getRegistryInternal()
    return DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
end

local function getCategoryDefinition(categoryId)
    return Config.GetItemCategoryDefinition and Config.GetItemCategoryDefinition(categoryId) or nil
end

local function isFoodGroup(group)
    return tostring(group or "") == "Food"
end

local function getRemainingWarehouseCapacity(ownerUsername)
    local warehouse = getWarehouse()
    local ownerWarehouse = warehouse and warehouse.GetOwnerWarehouse and warehouse.GetOwnerWarehouse(ownerUsername) or nil
    return warehouse and warehouse.GetRemainingCapacity and warehouse.GetRemainingCapacity(ownerWarehouse) or 0
end

local function resolveFoodCategory(categoryId)
    local key = tostring(categoryId or "")
    local definition = getCategoryDefinition(key)
    if definition and isFoodGroup(definition.group) then
        return key
    end
    return nil
end

local function addCategoryStockEntry(ownerData, categoryId, count, totalWeight)
    local key = tostring(categoryId or "")
    local addedCount = math.max(0, math.floor(tonumber(count) or 0))
    if key == "" or addedCount <= 0 then
        return 0
    end

    local entry = Data.NormalizeCategoryStockEntry(ownerData.categoryStock[key] or nil)
    entry.count = entry.count + addedCount
    entry.totalWeight = entry.totalWeight + math.max(0, tonumber(totalWeight) or 0)
    ownerData.categoryStock[key] = entry
    return addedCount
end

local function getStaticFoodNutrition(fullType)
    local nutrition = DC_Colony and DC_Colony.Nutrition and DC_Colony.Nutrition.Internal or nil
    if nutrition and nutrition.GetExpectedStaticNutritionForFullType then
        local calories, hydration = nutrition.GetExpectedStaticNutritionForFullType(fullType)
        return math.max(0, tonumber(calories) or 0), math.max(0, tonumber(hydration) or 0)
    end
    return 0, 0
end

local function getConvertedDepositData(fullType, meta)
    local converted = Config.GetItemCategoryData and Config.GetItemCategoryData(fullType) or nil
    local categoryId = tostring(meta and meta.overrideCategory or converted and converted.category or "Junk")
    local group = tostring(meta and meta.overrideGroup or converted and converted.group or "Waste")
    if categoryId == "" then
        categoryId = "Junk"
    end
    if group == "" then
        group = "Waste"
    end
    return categoryId, group, converted
end

local function getNormalizedQuantity(meta, fallbackQty)
    local qty = math.max(0, math.floor(tonumber(meta and meta.qty) or tonumber(fallbackQty) or 0))
    return qty
end

local function applyFoodNutrition(ownerData, categoryId, qty, fullType, meta)
    local foodCategory = resolveFoodCategory(categoryId)
    if not foodCategory then
        return
    end

    local calories = math.max(0, tonumber(meta and meta.totalCalories) or 0)
    local hydration = math.max(0, tonumber(meta and meta.totalHydration) or 0)
    if calories <= 0 and hydration <= 0 then
        local perItemCalories, perItemHydration = getStaticFoodNutrition(fullType)
        calories = perItemCalories * qty
        hydration = perItemHydration * qty
    end

    local entry = Data.NormalizeFoodNutritionEntry(ownerData.foodNutritionPools[foodCategory] or nil)
    entry.calories = entry.calories + calories
    entry.hydration = entry.hydration + hydration
    entry.count = entry.count + qty
    ownerData.foodNutritionPools[foodCategory] = entry
end

local function consumeFoodCategoryCount(ownerData, categoryId, estimatedCount)
    local key = tostring(categoryId or "")
    local toConsume = math.max(0, math.floor(tonumber(estimatedCount) or 0))
    if key == "" or toConsume <= 0 then
        return
    end

    local stockEntry = Data.NormalizeCategoryStockEntry(ownerData.categoryStock[key] or nil)
    if stockEntry.count <= 0 then
        return
    end

    local taken = math.min(stockEntry.count, toConsume)
    local averageWeight = stockEntry.count > 0 and (stockEntry.totalWeight / stockEntry.count) or 0
    stockEntry.count = math.max(0, stockEntry.count - taken)
    stockEntry.totalWeight = math.max(0, stockEntry.totalWeight - (averageWeight * taken))
    if stockEntry.count <= 0 then
        ownerData.categoryStock[key] = nil
    else
        ownerData.categoryStock[key] = stockEntry
    end
end

function AbstractInventory.DepositItem(ownerUsername, fullType, qty, meta)
    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "")
    local normalizedFullType = tostring(fullType or "")
    local count = getNormalizedQuantity(meta, qty)
    local requestedCount = count
    if normalizedFullType == "" or count <= 0 then
        return 0
    end

    local totalWeight = math.max(0, tonumber(meta and meta.totalWeight) or Data.GetEntryWeight(normalizedFullType, count))
    local unitWeight = count > 0 and (totalWeight / count) or 0
    if unitWeight > 0 then
        local fitQty = math.floor((getRemainingWarehouseCapacity(owner) + 0.0001) / unitWeight)
        if fitQty <= 0 then
            return 0
        end
        if fitQty < count then
            count = fitQty
            totalWeight = unitWeight * count
        end
    elseif totalWeight > getRemainingWarehouseCapacity(owner) and totalWeight > 0 then
        return 0
    end

    local appliedMeta = meta
    if meta and requestedCount > 0 and count < requestedCount then
        local ratio = count / requestedCount
        appliedMeta = {}
        for key, value in pairs(meta) do
            appliedMeta[key] = value
        end
        appliedMeta.qty = count
        appliedMeta.totalCalories = math.max(0, tonumber(meta.totalCalories) or 0) * ratio
        appliedMeta.totalHydration = math.max(0, tonumber(meta.totalHydration) or 0) * ratio
    end

    local ownerData = Data.EnsureOwnerData(owner)
    local categoryId, group = getConvertedDepositData(normalizedFullType, appliedMeta)
    addCategoryStockEntry(ownerData, categoryId, count, totalWeight)

    if isFoodGroup(group) and not (appliedMeta and appliedMeta.skipFoodNutrition == true) then
        applyFoodNutrition(ownerData, categoryId, count, normalizedFullType, appliedMeta)
    end

    Data.RebuildSummaryTotals(ownerData)
    Data.Touch(owner)
    local warehouse = getWarehouse()
    if warehouse and warehouse.TouchSummaryVersion then
        warehouse.TouchSummaryVersion(owner)
    end
    if warehouse and warehouse.Recalculate then
        warehouse.Recalculate(warehouse.GetOwnerWarehouse and warehouse.GetOwnerWarehouse(owner) or nil)
    end
    return count
end

function AbstractInventory.DepositOutputEntry(ownerUsername, entry, meta)
    local registryInternal = getRegistryInternal()
    local normalizedEntry = registryInternal and registryInternal.NormalizeOutputEntry and registryInternal.NormalizeOutputEntry(entry) or nil
    if not normalizedEntry then
        return 0
    end

    if normalizedEntry.forceLiteral == true or normalizedEntry.literalSpecial == true then
        return AbstractInventory.AddLiteralSpecial(ownerUsername, normalizedEntry)
    end

    local depositMeta = meta or {}
    depositMeta.qty = math.max(1, tonumber(normalizedEntry.qty) or 1)
    depositMeta.totalWeight = Data.GetEntryWeight(normalizedEntry.fullType, depositMeta.qty)
    return AbstractInventory.DepositItem(ownerUsername, normalizedEntry.fullType, depositMeta.qty, depositMeta)
end

function AbstractInventory.GetCategoryCount(ownerUsername, categoryId)
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    return Data.GetCategoryStockCount(ownerData and ownerData.categoryStock or nil, categoryId)
end

function AbstractInventory.GetCategoryStock(ownerUsername, categoryId)
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    local key = tostring(categoryId or "")
    return Data.NormalizeCategoryStockEntry(ownerData and ownerData.categoryStock and ownerData.categoryStock[key] or nil)
end

function AbstractInventory.GetCategoryCounts(ownerUsername)
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    return Data.BuildCategoryCountSnapshot(ownerData and ownerData.categoryStock or nil)
end

function AbstractInventory.GetCategoryStockSnapshot(ownerUsername)
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    return Data.BuildCategoryStockSnapshot(ownerData and ownerData.categoryStock or nil)
end

function AbstractInventory.AddCategory(ownerUsername, categoryId, amount, sourceMeta)
    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "")
    local key = tostring(categoryId or "")
    local count = math.max(0, math.floor(tonumber(amount) or 0))
    if key == "" or count <= 0 then
        return 0
    end

    local totalWeight = math.max(0, tonumber(sourceMeta and sourceMeta.totalWeight) or 0)
    if totalWeight > 0 and totalWeight > getRemainingWarehouseCapacity(owner) then
        return 0
    end

    local ownerData = Data.EnsureOwnerData(owner)
    addCategoryStockEntry(ownerData, key, count, totalWeight)
    if resolveFoodCategory(key) and sourceMeta and ((tonumber(sourceMeta.totalCalories) or 0) > 0 or (tonumber(sourceMeta.totalHydration) or 0) > 0) then
        applyFoodNutrition(ownerData, key, count, key, {
            totalCalories = sourceMeta.totalCalories,
            totalHydration = sourceMeta.totalHydration,
        })
    end

    Data.RebuildSummaryTotals(ownerData)
    Data.Touch(owner)
    local warehouse = getWarehouse()
    if warehouse and warehouse.TouchSummaryVersion then
        warehouse.TouchSummaryVersion(owner)
    end
    if warehouse and warehouse.Recalculate then
        warehouse.Recalculate(warehouse.GetOwnerWarehouse and warehouse.GetOwnerWarehouse(owner) or nil)
    end
    return count
end

function AbstractInventory.GetFoodNutritionSnapshot(ownerUsername)
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    return Data.BuildFoodNutritionSnapshot(ownerData and ownerData.foodNutritionPools or nil)
end

function AbstractInventory.CanConsumeFoodNutrition(ownerUsername, filters, calories, hydration)
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    local remainingCalories = math.max(0, tonumber(calories) or 0)
    local remainingHydration = math.max(0, tonumber(hydration) or 0)
    local allowed = {}
    local restrict = false

    for _, categoryId in ipairs(filters and filters.categories or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            allowed[key] = true
            restrict = true
        end
    end

    local totalCalories = 0
    local totalHydration = 0
    for categoryId, entry in pairs(ownerData and ownerData.foodNutritionPools or {}) do
        if restrict ~= true or allowed[tostring(categoryId or "")] == true then
            totalCalories = totalCalories + math.max(0, tonumber(entry and entry.calories) or 0)
            totalHydration = totalHydration + math.max(0, tonumber(entry and entry.hydration) or 0)
        end
    end

    return totalCalories + 0.0001 >= remainingCalories and totalHydration + 0.0001 >= remainingHydration
end

function AbstractInventory.ConsumeFoodNutrition(ownerUsername, filters, calories, hydration, _reasonMeta)
    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "")
    if not AbstractInventory.CanConsumeFoodNutrition(owner, filters, calories, hydration) then
        return false
    end

    local ownerData = Data.EnsureOwnerData(owner)
    local capture = type(_reasonMeta) == "table" and type(_reasonMeta.capture) == "table" and _reasonMeta.capture or nil
    local allowed = {}
    local categories = {}
    local restrict = false
    for _, categoryId in ipairs(filters and filters.categories or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            allowed[key] = true
            categories[#categories + 1] = key
            restrict = true
        end
    end
    if restrict ~= true then
        for categoryId, _entry in pairs(ownerData.foodNutritionPools or {}) do
            categories[#categories + 1] = tostring(categoryId or "")
        end
    end
    table.sort(categories)

    local remainingCalories = math.max(0, tonumber(calories) or 0)
    local remainingHydration = math.max(0, tonumber(hydration) or 0)
    for _, categoryId in ipairs(categories) do
        local key = tostring(categoryId or "")
        if key ~= "" and (restrict ~= true or allowed[key] == true) then
            local entry = Data.NormalizeFoodNutritionEntry(ownerData.foodNutritionPools[key] or nil)
            local caloriesBefore = math.max(0, tonumber(entry.calories) or 0)
            local hydrationBefore = math.max(0, tonumber(entry.hydration) or 0)
            local countBefore = math.max(0, math.floor(tonumber(entry.count) or 0))
            local usedCalories = 0
            local usedHydration = 0
            if remainingCalories > 0 then
                usedCalories = math.min(entry.calories, remainingCalories)
                entry.calories = math.max(0, entry.calories - usedCalories)
                remainingCalories = math.max(0, remainingCalories - usedCalories)
            end
            if remainingHydration > 0 then
                usedHydration = math.min(entry.hydration, remainingHydration)
                entry.hydration = math.max(0, entry.hydration - usedHydration)
                remainingHydration = math.max(0, remainingHydration - usedHydration)
            end
            if countBefore > 0 and (usedCalories > 0 or usedHydration > 0) then
                local estimatedByCalories = 0
                local estimatedByHydration = 0
                if caloriesBefore > 0 then
                    estimatedByCalories = (usedCalories / caloriesBefore) * countBefore
                end
                if hydrationBefore > 0 then
                    estimatedByHydration = (usedHydration / hydrationBefore) * countBefore
                end

                local estimatedCount = math.max(estimatedByCalories, estimatedByHydration)
                if estimatedCount <= 0 then
                    estimatedCount = 1
                else
                    estimatedCount = math.min(countBefore, math.max(1, math.ceil(estimatedCount - 0.0001)))
                end
                entry.count = math.max(0, countBefore - estimatedCount)
                local stockEntry = Data.NormalizeCategoryStockEntry(ownerData.categoryStock[key] or nil)
                local averageWeight = stockEntry.count > 0 and (stockEntry.totalWeight / stockEntry.count) or 0
                local actualTaken = math.min(stockEntry.count, estimatedCount)
                consumeFoodCategoryCount(ownerData, key, estimatedCount)
                if capture then
                    capture.totalWeightConsumed = math.max(0, tonumber(capture.totalWeightConsumed) or 0) + (averageWeight * actualTaken)
                    capture.totalItemCountConsumed = math.max(0, tonumber(capture.totalItemCountConsumed) or 0) + actualTaken
                end
            end
            if capture then
                capture.totalCaloriesConsumed = math.max(0, tonumber(capture.totalCaloriesConsumed) or 0) + usedCalories
                capture.totalHydrationConsumed = math.max(0, tonumber(capture.totalHydrationConsumed) or 0) + usedHydration
            end
            if entry.calories <= 0 and entry.hydration <= 0 and entry.count <= 0 then
                ownerData.foodNutritionPools[key] = nil
            else
                ownerData.foodNutritionPools[key] = entry
            end
        end
    end

    Data.RebuildSummaryTotals(ownerData)
    Data.Touch(owner)
    local warehouse = getWarehouse()
    if warehouse and warehouse.TouchSummaryVersion then
        warehouse.TouchSummaryVersion(owner)
    end
    if warehouse and warehouse.Recalculate then
        warehouse.Recalculate(warehouse.GetOwnerWarehouse and warehouse.GetOwnerWarehouse(owner) or nil)
    end
    return true
end

function AbstractInventory.GetLiteralSpecialCount(ownerUsername, fullType)
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    return Data.GetLiteralSpecialCount(ownerData and ownerData.literalSpecialStock or nil, fullType)
end

function AbstractInventory.GetLiteralSpecialStockSnapshot(ownerUsername)
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    return Data.BuildLiteralSpecialSnapshot(ownerData and ownerData.literalSpecialStock or nil)
end

function AbstractInventory.AddLiteralSpecial(ownerUsername, entry)
    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "")
    local registryInternal = getRegistryInternal()
    local normalized = registryInternal and registryInternal.NormalizeOutputEntry and registryInternal.NormalizeOutputEntry(entry) or nil
    if not normalized then
        return 0
    end

    normalized.forceLiteral = true
    normalized.literalSpecial = true
    local qty = math.max(1, tonumber(normalized.qty) or 1)
    local unitWeight = Data.GetEntryWeight(normalized.fullType, 1)
    if unitWeight > 0 then
        local fitQty = math.floor((getRemainingWarehouseCapacity(owner) + 0.0001) / unitWeight)
        if fitQty <= 0 then
            return 0
        end
        if fitQty < qty then
            qty = fitQty
        end
    end

    normalized.qty = qty
    local ownerData = Data.EnsureOwnerData(owner)
    ownerData.literalSpecialStock[#ownerData.literalSpecialStock + 1] = normalized
    Data.RebuildSummaryTotals(ownerData)
    Data.Touch(owner)
    local warehouse = getWarehouse()
    if warehouse and warehouse.TouchSummaryVersion then
        warehouse.TouchSummaryVersion(owner)
    end
    if warehouse and warehouse.Recalculate then
        warehouse.Recalculate(warehouse.GetOwnerWarehouse and warehouse.GetOwnerWarehouse(owner) or nil)
    end
    return qty
end

function AbstractInventory.TakeLiteralSpecial(ownerUsername, requestedQty, filterFn, _reasonMeta)
    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "")
    local ownerData = Data.EnsureOwnerData(owner)
    local removed = {}
    local taken = 0
    local remaining = math.max(0, math.floor(tonumber(requestedQty) or 0))
    if remaining <= 0 then
        return removed, taken
    end

    for index = #ownerData.literalSpecialStock, 1, -1 do
        local entry = ownerData.literalSpecialStock[index]
        if filterFn == nil or filterFn(entry) == true then
            local qty = math.max(0, math.floor(tonumber(entry and entry.qty) or 0))
            local toTake = math.min(qty, remaining)
            if toTake > 0 then
                local takenEntry = getRegistryInternal() and getRegistryInternal().NormalizeOutputEntry and getRegistryInternal().NormalizeOutputEntry(entry) or nil
                if takenEntry then
                    takenEntry.qty = toTake
                    removed[#removed + 1] = takenEntry
                    taken = taken + toTake
                    remaining = remaining - toTake
                    qty = qty - toTake
                    if qty <= 0 then
                        table.remove(ownerData.literalSpecialStock, index)
                    else
                        entry.qty = qty
                    end
                    if remaining <= 0 then
                        break
                    end
                end
            end
        end
    end

    if taken > 0 then
        Data.RebuildSummaryTotals(ownerData)
        Data.Touch(owner)
        local warehouse = getWarehouse()
        if warehouse and warehouse.TouchSummaryVersion then
            warehouse.TouchSummaryVersion(owner)
        end
        if warehouse and warehouse.Recalculate then
            warehouse.Recalculate(warehouse.GetOwnerWarehouse and warehouse.GetOwnerWarehouse(owner) or nil)
        end
    end
    return removed, taken
end

function AbstractInventory.CanConsumeCategories(ownerUsername, requirements)
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    for _, requirement in ipairs(requirements or {}) do
        local categoryId = tostring(requirement and requirement.category or "")
        local needed = math.max(0, math.floor(tonumber(requirement and requirement.count) or 0))
        if categoryId ~= "" and Data.GetCategoryStockCount(ownerData and ownerData.categoryStock or nil, categoryId) < needed then
            return false
        end
    end
    return true
end

function AbstractInventory.ConsumeCategories(ownerUsername, requirements, _reasonMeta)
    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "")
    if not AbstractInventory.CanConsumeCategories(owner, requirements) then
        return false
    end

    local ownerData = Data.EnsureOwnerData(owner)
    local capture = type(_reasonMeta) == "table" and type(_reasonMeta.capture) == "table" and _reasonMeta.capture or nil
    for _, requirement in ipairs(requirements or {}) do
        local categoryId = tostring(requirement and requirement.category or "")
        local needed = math.max(0, math.floor(tonumber(requirement and requirement.count) or 0))
        if categoryId ~= "" and needed > 0 then
            local entry = Data.NormalizeCategoryStockEntry(ownerData.categoryStock[categoryId] or nil)
            local countBefore = entry.count
            local totalWeightBefore = entry.totalWeight
            local averageWeight = countBefore > 0 and (totalWeightBefore / countBefore) or 0
            local taken = math.min(countBefore, needed)
            entry.count = math.max(0, entry.count - taken)
            entry.totalWeight = math.max(0, totalWeightBefore - (averageWeight * taken))
            if capture then
                capture.totalWeightConsumed = math.max(0, tonumber(capture.totalWeightConsumed) or 0) + (averageWeight * taken)
                capture.totalItemCountConsumed = math.max(0, tonumber(capture.totalItemCountConsumed) or 0) + taken
            end
            if entry.count <= 0 then
                ownerData.categoryStock[categoryId] = nil
            else
                ownerData.categoryStock[categoryId] = entry
            end
        end
    end

    Data.RebuildSummaryTotals(ownerData)
    Data.Touch(owner)
    local warehouse = getWarehouse()
    if warehouse and warehouse.TouchSummaryVersion then
        warehouse.TouchSummaryVersion(owner)
    end
    if warehouse and warehouse.Recalculate then
        warehouse.Recalculate(warehouse.GetOwnerWarehouse and warehouse.GetOwnerWarehouse(owner) or nil)
    end
    return true
end

function AbstractInventory.TakeCategoryUnits(ownerUsername, categoryId, amount)
    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "")
    local ownerData = Data.EnsureOwnerData(owner)
    local key = tostring(categoryId or "")
    local requested = math.max(0, math.floor(tonumber(amount) or 0))
    local entry = Data.NormalizeCategoryStockEntry(ownerData.categoryStock[key] or nil)
    local taken = math.min(entry.count, requested)
    if taken <= 0 then
        return 0
    end

    local totalCountBefore = entry.count
    local averageWeight = totalCountBefore > 0 and (entry.totalWeight / totalCountBefore) or 0
    entry.count = math.max(0, entry.count - taken)
    entry.totalWeight = math.max(0, entry.totalWeight - (averageWeight * taken))
    if entry.count <= 0 then
        ownerData.categoryStock[key] = nil
    else
        ownerData.categoryStock[key] = entry
    end

    Data.RebuildSummaryTotals(ownerData)
    Data.Touch(owner)
    local warehouse = getWarehouse()
    if warehouse and warehouse.TouchSummaryVersion then
        warehouse.TouchSummaryVersion(owner)
    end
    if warehouse and warehouse.Recalculate then
        warehouse.Recalculate(warehouse.GetOwnerWarehouse and warehouse.GetOwnerWarehouse(owner) or nil)
    end
    return taken
end

return AbstractInventory
