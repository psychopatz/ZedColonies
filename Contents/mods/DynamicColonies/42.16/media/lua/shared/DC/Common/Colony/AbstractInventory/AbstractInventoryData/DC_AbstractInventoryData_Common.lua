DC_Colony = DC_Colony or {}
DC_Colony.AbstractInventory = DC_Colony.AbstractInventory or {}
DC_Colony.AbstractInventory.Internal = DC_Colony.AbstractInventory.Internal or {}

local Config = DC_Colony.Config
local AbstractInventory = DC_Colony.AbstractInventory
local Internal = AbstractInventory.Internal
local Data = Internal.Data or {}

Internal.Data = Data

local ABSTRACT_INVENTORY_SCHEMA_VERSION = 2

local function normalizePositiveInteger(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function normalizePositiveNumber(value)
    return math.max(0, tonumber(value) or 0)
end

local function copyShallow(source)
    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
    if registryInternal and registryInternal.CopyShallow then
        return registryInternal.CopyShallow(source)
    end

    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

function Data.GetSchemaVersion()
    return ABSTRACT_INVENTORY_SCHEMA_VERSION
end

function Data.GetDataKey(colonyID)
    return tostring(Config.MOD_DATA_ABSTRACT_INVENTORY_PREFIX or "DColony_AbstractInventory_") .. tostring(colonyID or "")
end

function Data.CopyArray(source)
    local copy = {}
    for index, entry in ipairs(source or {}) do
        if type(entry) == "table" then
            copy[index] = copyShallow(entry)
        else
            copy[index] = entry
        end
    end
    return copy
end

function Data.GetEntryWeight(fullType, qty)
    return math.max(0, tonumber(Config.GetItemWeight and Config.GetItemWeight(fullType)) or 0) * math.max(1, tonumber(qty) or 1)
end

function Data.BuildEmptyData(colonyID, ownerUsername)
    return {
        schemaVersion = ABSTRACT_INVENTORY_SCHEMA_VERSION,
        colonyID = tostring(colonyID or ""),
        ownerUsername = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or ""),
        version = 1,
        itemStock = {},
        categoryStock = {},
        foodNutritionPools = {},
        literalSpecialStock = {},
        summaryTotals = {
            ownerUsername = Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or ""),
            colonyID = tostring(colonyID or ""),
            version = 1,
            totalItemCount = 0,
            totalCategoryCount = 0,
            totalWeight = 0,
            totalCalories = 0,
            totalHydration = 0,
            literalSpecialCount = 0,
            literalSpecialEntryCount = 0,
            inventoryRowCount = 0,
        },
        summaryTotalsDirty = false,
        legacyWarehouseMigrationComplete = false,
    }
end

function Data.NormalizeSummaryTotals(summaryTotals, colonyID, ownerUsername, version)
    local normalized = type(summaryTotals) == "table" and summaryTotals or {}
    return {
        ownerUsername = Config.GetOwnerUsername and Config.GetOwnerUsername(normalized.ownerUsername or ownerUsername) or tostring(normalized.ownerUsername or ownerUsername or ""),
        colonyID = tostring(normalized.colonyID or colonyID or ""),
        version = math.max(1, math.floor(tonumber(normalized.version) or tonumber(version) or 1)),
        totalItemCount = normalizePositiveInteger(normalized.totalItemCount),
        totalCategoryCount = normalizePositiveInteger(normalized.totalCategoryCount),
        totalWeight = normalizePositiveNumber(normalized.totalWeight),
        totalCalories = normalizePositiveNumber(normalized.totalCalories),
        totalHydration = normalizePositiveNumber(normalized.totalHydration),
        literalSpecialCount = normalizePositiveInteger(normalized.literalSpecialCount),
        literalSpecialEntryCount = normalizePositiveInteger(normalized.literalSpecialEntryCount),
        inventoryRowCount = normalizePositiveInteger(normalized.inventoryRowCount),
    }
end

function Data.CopySummaryTotals(summaryTotals, ownerData)
    local normalized = Data.NormalizeSummaryTotals(
        summaryTotals,
        ownerData and ownerData.colonyID or nil,
        ownerData and ownerData.ownerUsername or nil,
        ownerData and ownerData.version or nil
    )
    local copy = {}
    for key, value in pairs(normalized) do
        copy[key] = value
    end
    return copy
end

function Data.RebuildSummaryTotals(ownerData)
    if type(ownerData) ~= "table" then
        return Data.NormalizeSummaryTotals(nil)
    end

    local totalItemCount = 0
    local totalCategoryCount = 0
    local totalWeight = 0
    local totalCalories = 0
    local totalHydration = 0
    local totalLiteralRowCount = 0
    local totalReserveRowCount = 0
    local literalSpecialCount = 0
    local literalSpecialEntryCount = 0
    local itemBackedCategoryStock = Data.BuildItemBackedCategoryStock(ownerData.itemStock)

    for _fullType, entry in pairs(ownerData.itemStock or {}) do
        local normalizedEntry = Data.NormalizeItemStockEntry(entry)
        if normalizedEntry.qty > 0 then
            totalLiteralRowCount = totalLiteralRowCount + 1
            totalItemCount = totalItemCount + normalizedEntry.qty
            totalWeight = totalWeight + normalizedEntry.totalWeight
        end
    end

    for _categoryId, entry in pairs(ownerData.categoryStock or {}) do
        local normalizedEntry = Data.NormalizeCategoryStockEntry(entry)
        local itemBackedEntry = Data.NormalizeCategoryStockEntry(itemBackedCategoryStock[_categoryId] or nil)
        if normalizedEntry.count > 0 then
            totalCategoryCount = totalCategoryCount + 1
        end
        if normalizedEntry.count > itemBackedEntry.count or normalizedEntry.totalWeight > itemBackedEntry.totalWeight then
            totalReserveRowCount = totalReserveRowCount + 1
            totalItemCount = totalItemCount + math.max(0, normalizedEntry.count - itemBackedEntry.count)
            totalWeight = totalWeight + math.max(0, normalizedEntry.totalWeight - itemBackedEntry.totalWeight)
        end
    end

    for _categoryId, entry in pairs(ownerData.foodNutritionPools or {}) do
        local normalizedEntry = Data.NormalizeFoodNutritionEntry(entry)
        totalCalories = totalCalories + normalizedEntry.calories
        totalHydration = totalHydration + normalizedEntry.hydration
    end

    for _, entry in ipairs(ownerData.literalSpecialStock or {}) do
        local qty = math.max(0, math.floor(tonumber(entry and entry.qty) or 0))
        if qty > 0 then
            literalSpecialEntryCount = literalSpecialEntryCount + 1
            literalSpecialCount = literalSpecialCount + qty
            totalItemCount = totalItemCount + qty
            totalWeight = totalWeight + Data.GetEntryWeight(entry and entry.fullType, qty)
        end
    end

    ownerData.summaryTotals = Data.NormalizeSummaryTotals({
        ownerUsername = ownerData.ownerUsername,
        colonyID = ownerData.colonyID,
        version = ownerData.version,
        totalItemCount = totalItemCount,
        totalCategoryCount = totalCategoryCount,
        totalWeight = totalWeight,
        totalCalories = totalCalories,
        totalHydration = totalHydration,
        literalSpecialCount = literalSpecialCount,
        literalSpecialEntryCount = literalSpecialEntryCount,
        inventoryRowCount = totalLiteralRowCount + totalReserveRowCount + literalSpecialEntryCount,
    }, ownerData.colonyID, ownerData.ownerUsername, ownerData.version)
    ownerData.summaryTotalsDirty = false
    return ownerData.summaryTotals
end

function Data.NormalizeItemStockEntry(entry)
    if type(entry) ~= "table" then
        return {
            fullType = "",
            qty = normalizePositiveInteger(entry),
            totalWeight = 0,
            category = "",
            group = "",
        }
    end

    local fullType = tostring(entry.fullType or "")
    local category = tostring(entry.category or "")
    local group = tostring(entry.group or "")
    local qty = normalizePositiveInteger(entry.qty or entry.count)
    local totalWeight = normalizePositiveNumber(entry.totalWeight)
    if totalWeight <= 0 and fullType ~= "" and qty > 0 then
        totalWeight = Data.GetEntryWeight(fullType, qty)
    end

    return {
        fullType = fullType,
        qty = qty,
        totalWeight = totalWeight,
        category = category,
        group = group,
    }
end

function Data.NormalizeItemStock(stock)
    local normalized = {}
    for fullType, entry in pairs(type(stock) == "table" and stock or {}) do
        local fallbackFullType = tostring(fullType or "")
        local normalizedEntry = Data.NormalizeItemStockEntry(entry)
        if normalizedEntry.fullType == "" then
            normalizedEntry.fullType = fallbackFullType
        end
        if normalizedEntry.fullType ~= "" and normalizedEntry.qty > 0 then
            normalized[normalizedEntry.fullType] = normalizedEntry
        end
    end
    return normalized
end

function Data.BuildItemBackedCategoryStock(stock)
    local snapshot = {}
    for fullType, entry in pairs(type(stock) == "table" and stock or {}) do
        local normalizedEntry = Data.NormalizeItemStockEntry(entry)
        local resolvedFullType = normalizedEntry.fullType ~= "" and normalizedEntry.fullType or tostring(fullType or "")
        local categoryId = tostring(normalizedEntry.category or "")
        if categoryId == "" and Config.GetItemCategoryData then
            local converted = Config.GetItemCategoryData(resolvedFullType)
            categoryId = tostring(converted and converted.category or "")
        end
        if resolvedFullType ~= "" and categoryId ~= "" and normalizedEntry.qty > 0 then
            local categoryEntry = Data.NormalizeCategoryStockEntry(snapshot[categoryId] or nil)
            categoryEntry.count = categoryEntry.count + normalizedEntry.qty
            categoryEntry.totalWeight = categoryEntry.totalWeight + normalizedEntry.totalWeight
            snapshot[categoryId] = categoryEntry
        end
    end
    return snapshot
end

function Data.NormalizeCategoryStockEntry(entry)
    if type(entry) ~= "table" then
        return {
            count = normalizePositiveInteger(entry),
            totalWeight = 0,
        }
    end

    return {
        count = normalizePositiveInteger(entry.count),
        totalWeight = normalizePositiveNumber(entry.totalWeight),
    }
end

function Data.NormalizeCategoryStock(stock)
    local normalized = {}
    for categoryId, entry in pairs(type(stock) == "table" and stock or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            local normalizedEntry = Data.NormalizeCategoryStockEntry(entry)
            if normalizedEntry.count > 0 or normalizedEntry.totalWeight > 0 then
                normalized[key] = normalizedEntry
            end
        end
    end
    return normalized
end

function Data.NormalizeFoodNutritionEntry(entry)
    if type(entry) ~= "table" then
        return {
            calories = 0,
            hydration = 0,
            count = normalizePositiveInteger(entry),
        }
    end

    return {
        calories = normalizePositiveNumber(entry.calories),
        hydration = normalizePositiveNumber(entry.hydration),
        count = normalizePositiveInteger(entry.count),
    }
end

function Data.NormalizeFoodNutritionPools(pools)
    local normalized = {}
    for categoryId, entry in pairs(type(pools) == "table" and pools or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            local normalizedEntry = Data.NormalizeFoodNutritionEntry(entry)
            if normalizedEntry.calories > 0 or normalizedEntry.hydration > 0 or normalizedEntry.count > 0 then
                normalized[key] = normalizedEntry
            end
        end
    end
    return normalized
end

function Data.NormalizeLiteralSpecialStock(entries)
    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
    local normalized = {}
    for _, entry in ipairs(type(entries) == "table" and entries or {}) do
        local normalizedEntry = registryInternal and registryInternal.NormalizeOutputEntry and registryInternal.NormalizeOutputEntry(entry) or nil
        if normalizedEntry then
            normalizedEntry.forceLiteral = true
            normalizedEntry.literalSpecial = true
            normalized[#normalized + 1] = normalizedEntry
        end
    end
    return normalized
end

function Data.BuildCategoryCountSnapshot(stock)
    local snapshot = {}
    for categoryId, entry in pairs(type(stock) == "table" and stock or {}) do
        local key = tostring(categoryId or "")
        local count = math.max(0, tonumber(entry and entry.count) or 0)
        if key ~= "" and count > 0 then
            snapshot[key] = count
        end
    end
    return snapshot
end

function Data.BuildItemCountSnapshot(stock)
    local snapshot = {}
    for fullType, entry in pairs(type(stock) == "table" and stock or {}) do
        local key = tostring(fullType or "")
        local normalizedEntry = Data.NormalizeItemStockEntry(entry)
        if key ~= "" and normalizedEntry.qty > 0 then
            snapshot[key] = normalizedEntry.qty
        end
    end
    return snapshot
end

function Data.BuildItemStockSnapshot(stock)
    local snapshot = {}
    for fullType, entry in pairs(type(stock) == "table" and stock or {}) do
        local normalizedEntry = Data.NormalizeItemStockEntry(entry)
        if normalizedEntry.fullType == "" then
            normalizedEntry.fullType = tostring(fullType or "")
        end
        if normalizedEntry.fullType ~= "" then
            snapshot[normalizedEntry.fullType] = normalizedEntry
        end
    end
    return snapshot
end

function Data.BuildCategoryStockSnapshot(stock)
    local snapshot = {}
    for categoryId, entry in pairs(type(stock) == "table" and stock or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            snapshot[key] = Data.NormalizeCategoryStockEntry(entry)
        end
    end
    return snapshot
end

function Data.BuildFoodNutritionSnapshot(pools)
    local snapshot = {}
    for categoryId, entry in pairs(type(pools) == "table" and pools or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            snapshot[key] = Data.NormalizeFoodNutritionEntry(entry)
        end
    end
    return snapshot
end

function Data.BuildLiteralSpecialSnapshot(entries)
    return Data.CopyArray(Data.NormalizeLiteralSpecialStock(entries))
end

function Data.GetLiteralSpecialCount(entries, fullType)
    local total = 0
    local normalizedFullType = tostring(fullType or "")
    for _, entry in ipairs(type(entries) == "table" and entries or {}) do
        if normalizedFullType == "" or tostring(entry and entry.fullType or "") == normalizedFullType then
            total = total + math.max(0, tonumber(entry and entry.qty) or 0)
        end
    end
    return total
end

function Data.GetLiteralSpecialTotalWeight(entries)
    local total = 0
    for _, entry in ipairs(type(entries) == "table" and entries or {}) do
        total = total + Data.GetEntryWeight(entry and entry.fullType, math.max(0, tonumber(entry and entry.qty) or 0))
    end
    return total
end

function Data.GetCategoryStockCount(stock, categoryId)
    local key = tostring(categoryId or "")
    local entry = type(stock) == "table" and stock[key] or nil
    return math.max(0, tonumber(entry and entry.count) or 0)
end

function Data.GetItemStockCount(stock, fullType)
    local key = tostring(fullType or "")
    local entry = type(stock) == "table" and stock[key] or nil
    return math.max(0, tonumber(entry and entry.qty) or tonumber(entry and entry.count) or 0)
end

function Data.GetCategoryStockTotalCount(stock)
    local total = 0
    for _, entry in pairs(type(stock) == "table" and stock or {}) do
        total = total + math.max(0, tonumber(entry and entry.count) or 0)
    end
    return total
end

function Data.GetItemStockTotalCount(stock)
    local total = 0
    for _, entry in pairs(type(stock) == "table" and stock or {}) do
        total = total + math.max(0, tonumber(entry and entry.qty) or tonumber(entry and entry.count) or 0)
    end
    return total
end

function Data.GetItemStockTotalWeight(stock)
    local total = 0
    for fullType, entry in pairs(type(stock) == "table" and stock or {}) do
        local normalizedEntry = Data.NormalizeItemStockEntry(entry)
        if normalizedEntry.fullType == "" then
            normalizedEntry.fullType = tostring(fullType or "")
        end
        total = total + normalizedEntry.totalWeight
    end
    return total
end

function Data.GetCategoryStockTotalWeight(stock)
    local total = 0
    for _, entry in pairs(type(stock) == "table" and stock or {}) do
        total = total + math.max(0, tonumber(entry and entry.totalWeight) or 0)
    end
    return total
end

return AbstractInventory
