DC_Colony = DC_Colony or {}
DC_Colony.AbstractInventory = DC_Colony.AbstractInventory or {}
DC_Colony.AbstractInventory.Internal = DC_Colony.AbstractInventory.Internal or {}

local Config = DC_Colony.Config
local AbstractInventory = DC_Colony.AbstractInventory
local Internal = AbstractInventory.Internal
local Data = Internal.Data or {}

Internal.Data = Data

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getRegistryInternal()
    local registry = getRegistry()
    return registry and registry.Internal or nil
end

local function getWarehouse()
    return DC_Colony and DC_Colony.Warehouse or nil
end

local function getWarehouseInternalData()
    local warehouse = getWarehouse()
    return warehouse and warehouse.Internal and warehouse.Internal.Data or nil
end

local function getConvertedItem(fullType)
    local config = DC_Colony and DC_Colony.Config or nil
    return config and config.GetItemCategoryData and config.GetItemCategoryData(fullType) or nil
end

local function isFoodGroup(group)
    return tostring(group or "") == "Food"
end

local function isFoodCategory(categoryId, group)
    if isFoodGroup(group) then
        return true
    end
    local converted = getConvertedItem(categoryId)
    return tostring(converted and converted.group or "") == "Food"
end

local function mergeItemStock(target, source)
    for fullType, entry in pairs(source or {}) do
        local fallbackFullType = tostring(fullType or "")
        local sourceEntry = Data.NormalizeItemStockEntry(entry)
        if sourceEntry.fullType == "" then
            sourceEntry.fullType = fallbackFullType
        end
        if sourceEntry.fullType ~= "" and sourceEntry.qty > 0 then
            local existing = Data.NormalizeItemStockEntry(target[sourceEntry.fullType] or nil)
            existing.fullType = sourceEntry.fullType
            existing.category = sourceEntry.category ~= "" and sourceEntry.category or existing.category
            existing.group = sourceEntry.group ~= "" and sourceEntry.group or existing.group
            existing.qty = existing.qty + sourceEntry.qty
            existing.totalWeight = existing.totalWeight + sourceEntry.totalWeight
            target[sourceEntry.fullType] = existing
        end
    end
end

local function mergeCategoryStock(target, source)
    for categoryId, entry in pairs(source or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            local sourceEntry = Data.NormalizeCategoryStockEntry(entry)
            if sourceEntry.count > 0 then
                local existing = Data.NormalizeCategoryStockEntry(target[key] or nil)
                existing.count = existing.count + sourceEntry.count
                existing.totalWeight = existing.totalWeight + sourceEntry.totalWeight
                target[key] = existing
            end
        end
    end
end

local function mergeFoodPools(target, source)
    for categoryId, entry in pairs(source or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            local sourceEntry = Data.NormalizeFoodNutritionEntry(entry)
            if sourceEntry.calories > 0 or sourceEntry.hydration > 0 or sourceEntry.count > 0 then
                local existing = Data.NormalizeFoodNutritionEntry(target[key] or nil)
                existing.calories = existing.calories + sourceEntry.calories
                existing.hydration = existing.hydration + sourceEntry.hydration
                existing.count = existing.count + sourceEntry.count
                target[key] = existing
            end
        end
    end
end

local function mergeLiteralSpecial(target, source)
    for _, entry in ipairs(Data.NormalizeLiteralSpecialStock(source)) do
        target[#target + 1] = entry
    end
end

local function hasAnyEntries(map)
    for _key, _value in pairs(map or {}) do
        return true
    end
    return false
end

local function getStaticFoodNutrition(fullType)
    local nutrition = DC_Colony and DC_Colony.Nutrition and DC_Colony.Nutrition.Internal or nil
    if nutrition and nutrition.GetExpectedStaticNutritionForFullType then
        local calories, hydration = nutrition.GetExpectedStaticNutritionForFullType(fullType)
        return math.max(0, tonumber(calories) or 0), math.max(0, tonumber(hydration) or 0)
    end
    return 0, 0
end

local function addMigratedLiteralItem(data, fullType, qty, categoryId, group)
    local key = tostring(fullType or "")
    local count = math.max(0, math.floor(tonumber(qty) or 0))
    if key == "" or count <= 0 then
        return
    end

    local normalizedCategory = tostring(categoryId or "")
    local normalizedGroup = tostring(group or "")
    local totalWeight = Data.GetEntryWeight(key, count)
    local itemEntry = Data.NormalizeItemStockEntry(data.itemStock[key] or nil)
    itemEntry.fullType = key
    itemEntry.category = normalizedCategory
    itemEntry.group = normalizedGroup
    itemEntry.qty = itemEntry.qty + count
    itemEntry.totalWeight = itemEntry.totalWeight + totalWeight
    data.itemStock[key] = itemEntry

    local categoryEntry = Data.NormalizeCategoryStockEntry(data.categoryStock[normalizedCategory] or nil)
    categoryEntry.count = categoryEntry.count + count
    categoryEntry.totalWeight = categoryEntry.totalWeight + totalWeight
    data.categoryStock[normalizedCategory] = categoryEntry

    if isFoodGroup(normalizedGroup) then
        local caloriesPerItem, hydrationPerItem = getStaticFoodNutrition(key)
        local foodEntry = Data.NormalizeFoodNutritionEntry(data.foodNutritionPools[normalizedCategory] or nil)
        foodEntry.calories = foodEntry.calories + (caloriesPerItem * count)
        foodEntry.hydration = foodEntry.hydration + (hydrationPerItem * count)
        foodEntry.count = foodEntry.count + count
        data.foodNutritionPools[normalizedCategory] = foodEntry
    end
end

function Data.NormalizeData(colonyID, ownerUsername, data)
    local hadSummaryTotals = type(data.summaryTotals) == "table"
    data.schemaVersion = math.max(Data.GetSchemaVersion(), math.floor(tonumber(data.schemaVersion) or 0))
    data.colonyID = tostring(colonyID or data.colonyID or "")
    data.ownerUsername = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername or data.ownerUsername) or tostring(ownerUsername or data.ownerUsername or "")
    data.version = math.max(1, math.floor(tonumber(data.version) or 1))
    data.itemStock = Data.NormalizeItemStock(data.itemStock)
    data.categoryStock = Data.NormalizeCategoryStock(data.categoryStock)
    data.foodNutritionPools = Data.NormalizeFoodNutritionPools(data.foodNutritionPools)
    data.literalSpecialStock = Data.NormalizeLiteralSpecialStock(data.literalSpecialStock)
    data.summaryTotals = Data.NormalizeSummaryTotals(data.summaryTotals, data.colonyID, data.ownerUsername, data.version)
    data.summaryTotalsDirty = data.summaryTotalsDirty == true or hadSummaryTotals ~= true
    data.legacyWarehouseMigrationComplete = data.legacyWarehouseMigrationComplete == true
    return data
end

function Data.Touch(ownerUsername)
    local data = Data.EnsureOwnerData(ownerUsername)
    data.version = math.max(1, math.floor(tonumber(data.version) or 1)) + 1
    if type(data.summaryTotals) == "table" then
        data.summaryTotals.version = data.version
    end
    return data.version
end

function Data.MigrateWarehouseData(ownerUsername, data)
    if not data or data.legacyWarehouseMigrationComplete == true then
        return false
    end

    local registry = getRegistry()
    local registryInternal = getRegistryInternal()
    local warehouseData = getWarehouseInternalData()
    if not (registry and registryInternal and warehouseData) then
        return false
    end

    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "")
    local colonyID = registry.GetColonyIDForOwner and registry.GetColonyIDForOwner(owner, true) or tostring(owner or "")
    local itemsKey = warehouseData.GetItemsKey and warehouseData.GetItemsKey(colonyID) or nil
    if not itemsKey then
        data.legacyWarehouseMigrationComplete = true
        return false
    end

    local rawItems = registryInternal.EnsureModDataTable and registryInternal.EnsureModDataTable(itemsKey, warehouseData.BuildEmptyItems and warehouseData.BuildEmptyItems(colonyID) or {}) or nil
    if type(rawItems) ~= "table" then
        data.legacyWarehouseMigrationComplete = true
        return false
    end

    local changed = false

    if type(rawItems.itemStock) == "table" then
        mergeItemStock(data.itemStock, rawItems.itemStock)
        if hasAnyEntries(rawItems.itemStock) then
            changed = true
        end
        rawItems.itemStock = {}
    end

    if type(rawItems.abstractStock) == "table" then
        mergeCategoryStock(data.categoryStock, rawItems.abstractStock)
        if hasAnyEntries(rawItems.abstractStock) then
            changed = true
        end
        rawItems.abstractStock = {}
    end

    if type(rawItems.literalSpecialStock) == "table" and #rawItems.literalSpecialStock > 0 then
        mergeLiteralSpecial(data.literalSpecialStock, rawItems.literalSpecialStock)
        rawItems.literalSpecialStock = {}
        changed = true
    end

    local remainingOutput = {}
    for _, rawEntry in ipairs(rawItems.ledgers and rawItems.ledgers.output or {}) do
        local entry = registryInternal.NormalizeOutputEntry and registryInternal.NormalizeOutputEntry(rawEntry) or nil
        local qty = math.max(0, tonumber(entry and entry.qty) or 0)
        local fullType = tostring(entry and entry.fullType or "")
        if entry and fullType ~= "" and qty > 0 then
            changed = true
            if (warehouseData.ShouldStoreAsLiteralSpecial and warehouseData.ShouldStoreAsLiteralSpecial(entry) == true)
                or entry.forceLiteral == true then
                data.literalSpecialStock[#data.literalSpecialStock + 1] = entry
            else
                local converted = getConvertedItem(fullType)
                local categoryId = tostring(converted and converted.category or "Junk")
                local group = tostring(converted and converted.group or "Waste")
                addMigratedLiteralItem(data, fullType, qty, categoryId, group)
            end
        else
            remainingOutput[#remainingOutput + 1] = rawEntry
        end
    end

    rawItems.ledgers = rawItems.ledgers or {}
    rawItems.ledgers.output = remainingOutput
    rawItems.legacyOutputMigrationComplete = true
    data.legacyWarehouseMigrationComplete = true

    return changed
end

function Data.EnsureOwnerData(ownerUsername)
    local registry = getRegistry()
    local registryInternal = getRegistryInternal()
    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "")
    local colonyID = registry and registry.GetColonyIDForOwner and registry.GetColonyIDForOwner(owner, true) or owner
    local key = Data.GetDataKey(colonyID)
    local data = registryInternal and registryInternal.EnsureModDataTable and registryInternal.EnsureModDataTable(key, Data.BuildEmptyData(colonyID, owner)) or Data.BuildEmptyData(colonyID, owner)
    Data.NormalizeData(colonyID, owner, data)
    if Data.MigrateWarehouseData(owner, data) then
        Data.RebuildSummaryTotals(data)
        Data.Touch(owner)
        local warehouse = getWarehouse()
        if warehouse and warehouse.TouchItemsVersion then
            warehouse.TouchItemsVersion(owner)
        end
        if warehouse and warehouse.TouchSummaryVersion then
            warehouse.TouchSummaryVersion(owner)
        end
    elseif data.summaryTotalsDirty == true then
        Data.RebuildSummaryTotals(data)
    end
    return data
end

return AbstractInventory
