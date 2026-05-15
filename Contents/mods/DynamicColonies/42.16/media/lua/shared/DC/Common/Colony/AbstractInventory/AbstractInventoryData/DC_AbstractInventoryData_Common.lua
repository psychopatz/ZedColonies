DC_Colony = DC_Colony or {}
DC_Colony.AbstractInventory = DC_Colony.AbstractInventory or {}
DC_Colony.AbstractInventory.Internal = DC_Colony.AbstractInventory.Internal or {}

local Config = DC_Colony.Config
local AbstractInventory = DC_Colony.AbstractInventory
local Internal = AbstractInventory.Internal
local Data = Internal.Data or {}

Internal.Data = Data

local ABSTRACT_INVENTORY_SCHEMA_VERSION = 1

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
        categoryStock = {},
        foodNutritionPools = {},
        literalSpecialStock = {},
        legacyWarehouseMigrationComplete = false,
    }
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

function Data.GetCategoryStockTotalCount(stock)
    local total = 0
    for _, entry in pairs(type(stock) == "table" and stock or {}) do
        total = total + math.max(0, tonumber(entry and entry.count) or 0)
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
