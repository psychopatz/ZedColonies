DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Data = Internal.Data or {}

Internal.Data = Data

local function normalizePositiveInteger(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function normalizePositiveNumber(value)
    return math.max(0, tonumber(value) or 0)
end

local function resolveCategoryDefinition(categoryId)
    return Config.GetItemCategoryDefinition and Config.GetItemCategoryDefinition(categoryId) or nil
end

function Data.NormalizeAbstractStockEntry(entry)
    if type(entry) ~= "table" then
        return {
            count = normalizePositiveInteger(entry),
            totalWeight = normalizePositiveNumber(entry),
        }
    end

    return {
        count = normalizePositiveInteger(entry.count),
        totalWeight = normalizePositiveNumber(entry.totalWeight),
    }
end

function Data.NormalizeAbstractStock(stock)
    local normalized = {}
    for categoryId, entry in pairs(type(stock) == "table" and stock or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            local normalizedEntry = Data.NormalizeAbstractStockEntry(entry)
            if normalizedEntry.count > 0 or normalizedEntry.totalWeight > 0 then
                normalized[key] = normalizedEntry
            end
        end
    end
    return normalized
end

function Data.NormalizeLiteralSpecialStock(entries)
    return Data.StackLiteralSpecialEntries(entries)
end

function Data.GetAbstractStockCount(stock, categoryId)
    local entry = type(stock) == "table" and stock[tostring(categoryId or "")] or nil
    return math.max(0, tonumber(entry and entry.count) or 0)
end

function Data.GetAbstractStockWeight(stock, categoryId)
    local entry = type(stock) == "table" and stock[tostring(categoryId or "")] or nil
    return math.max(0, tonumber(entry and entry.totalWeight) or 0)
end

function Data.AddAbstractStock(stock, categoryId, amount, totalWeight)
    local key = tostring(categoryId or "")
    if key == "" then
        return 0
    end

    local definition = resolveCategoryDefinition(key)
    if not definition then
        key = "Junk"
    end

    local count = normalizePositiveInteger(amount)
    if count <= 0 then
        return 0
    end

    local entry = Data.NormalizeAbstractStockEntry(stock[key] or {})
    entry.count = entry.count + count
    entry.totalWeight = entry.totalWeight + normalizePositiveNumber(totalWeight)
    stock[key] = entry
    return count
end

function Data.TakeAbstractStock(stock, categoryId, amount)
    local key = tostring(categoryId or "")
    local entry = Data.NormalizeAbstractStockEntry(type(stock) == "table" and stock[key] or nil)
    local requested = normalizePositiveInteger(amount)
    local taken = math.min(entry.count, requested)
    if taken <= 0 then
        return 0, 0
    end

    local averageWeight = 0
    if entry.count > 0 and entry.totalWeight > 0 then
        averageWeight = entry.totalWeight / entry.count
    end

    local takenWeight = averageWeight * taken
    entry.count = entry.count - taken
    entry.totalWeight = math.max(0, entry.totalWeight - takenWeight)

    if entry.count <= 0 then
        stock[key] = nil
    else
        stock[key] = entry
    end

    return taken, takenWeight
end

function Data.GetAbstractStockTotalCount(stock)
    local total = 0
    for _, entry in pairs(type(stock) == "table" and stock or {}) do
        total = total + math.max(0, tonumber(entry and entry.count) or 0)
    end
    return total
end

function Data.GetAbstractStockTotalWeight(stock)
    local total = 0
    for _, entry in pairs(type(stock) == "table" and stock or {}) do
        total = total + math.max(0, tonumber(entry and entry.totalWeight) or 0)
    end
    return total
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
            snapshot[key] = Data.NormalizeAbstractStockEntry(entry)
        end
    end
    return snapshot
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

function Data.BuildLiteralSpecialSnapshot(entries)
    return Data.CopyArray(Data.NormalizeLiteralSpecialStock(entries))
end

function Data.AddLiteralSpecialStockEntry(entries, entry)
    local normalized = Data.NormalizeOutputEntry(entry)
    if not normalized then
        return 0
    end

    normalized.forceLiteral = true
    normalized.literalSpecial = true
    local stackKey = Registry.Internal.GetOutputEntryStateSignature and Registry.Internal.GetOutputEntryStateSignature(normalized)
        or normalized.fullType
    for _, existing in ipairs(entries) do
        local existingKey = Registry.Internal.GetOutputEntryStateSignature and Registry.Internal.GetOutputEntryStateSignature(existing)
            or tostring(existing and existing.fullType or "")
        if existingKey == stackKey then
            existing.qty = math.max(1, tonumber(existing.qty) or 1) + normalized.qty
            return normalized.qty
        end
    end

    entries[#entries + 1] = normalized
    return normalized.qty
end

function Data.TakeLiteralSpecialStock(entries, requestedQty, filterFn)
    local removed = {}
    local taken = 0
    local remaining = math.max(0, math.floor(tonumber(requestedQty) or 0))
    if remaining <= 0 then
        return removed, taken
    end

    for index = #entries, 1, -1 do
        local entry = entries[index]
        if filterFn == nil or filterFn(entry) == true then
            local qty = math.max(0, math.floor(tonumber(entry and entry.qty) or 0))
            local toTake = math.min(qty, remaining)
            if toTake > 0 then
                local takenEntry = Data.NormalizeOutputEntry(entry)
                takenEntry.qty = toTake
                removed[#removed + 1] = takenEntry
                taken = taken + toTake
                remaining = remaining - toTake
                qty = qty - toTake
                if qty <= 0 then
                    table.remove(entries, index)
                else
                    entry.qty = qty
                end
                if remaining <= 0 then
                    break
                end
            end
        end
    end

    return removed, taken
end

function Data.ShouldStoreAsLiteralSpecial(entry)
    if type(entry) ~= "table" then
        return false
    end

    if entry.literalSpecial == true then
        return true
    end

    local fullType = tostring(entry.fullType or "")
    if fullType == "" then
        return false
    end

    local converted = Config.GetItemCategoryData and Config.GetItemCategoryData(fullType) or nil
    local category = tostring(converted and converted.category or "")
    return category == "QuestGoods"
        or category == "ContaminatedMaterial"
end

function Data.MigrateLegacyOutputLedger(items)
    if type(items) ~= "table" then
        return false
    end

    if items.legacyOutputMigrationComplete == true then
        return false
    end

    items.abstractStock = Data.NormalizeAbstractStock(items.abstractStock)
    local migrated = false
    local remainingOutput = {}

    for _, rawEntry in ipairs(items.ledgers and items.ledgers.output or {}) do
        local entry = Data.NormalizeOutputEntry and Data.NormalizeOutputEntry(rawEntry) or nil
        local fullType = tostring(entry and entry.fullType or "")
        local qty = math.max(0, tonumber(entry and entry.qty) or 0)

        if fullType ~= "" and qty > 0 and not Data.ShouldStoreAsLiteralSpecial(entry) and entry.forceLiteral ~= true then
            local converted = Config.GetItemCategoryData and Config.GetItemCategoryData(fullType) or nil
            local categoryId = tostring(converted and converted.category or "Junk")
            local totalWeight = Data.GetEntryWeight(fullType, qty)
            Data.AddAbstractStock(items.abstractStock, categoryId, qty, totalWeight)
            migrated = true
        elseif fullType ~= "" and qty > 0 and Data.ShouldStoreAsLiteralSpecial(entry) then
            Data.AddLiteralSpecialStockEntry(items.literalSpecialStock, entry)
            migrated = true
        elseif entry then
            remainingOutput[#remainingOutput + 1] = entry
        end
    end

    items.ledgers.output = remainingOutput
    items.legacyOutputMigrationComplete = true
    return migrated
end

function Warehouse.GetCategoryCount(ownerUsername, categoryId)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return Data.GetAbstractStockCount(warehouse and warehouse.abstractStock or nil, categoryId)
end

function Warehouse.GetCategoryStock(ownerUsername, categoryId)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local key = tostring(categoryId or "")
    return Data.NormalizeAbstractStockEntry(warehouse and warehouse.abstractStock and warehouse.abstractStock[key] or nil)
end

function Warehouse.GetCategoryCounts(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return Data.BuildCategoryCountSnapshot(warehouse and warehouse.abstractStock or nil)
end

function Warehouse.GetCategoryStockSnapshot(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return Data.BuildCategoryStockSnapshot(warehouse and warehouse.abstractStock or nil)
end

function Warehouse.AddCategory(ownerUsername, categoryId, amount, sourceMeta)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(owner)
    if not warehouse then
        return 0
    end

    local count = normalizePositiveInteger(amount)
    if count <= 0 then
        return 0
    end

    local totalWeight = normalizePositiveNumber(sourceMeta and sourceMeta.totalWeight)
    local remainingCapacity = Warehouse.GetRemainingCapacity(warehouse)
    if totalWeight > 0 and totalWeight > remainingCapacity then
        return 0
    end

    local added = Data.AddAbstractStock(warehouse.abstractStock, categoryId, count, totalWeight)
    if added > 0 then
        Warehouse.TouchItemsVersion(owner)
        Warehouse.TouchSummaryVersion(owner)
        Warehouse.Recalculate(warehouse)
    end
    return added
end

function Warehouse.GetLiteralSpecialCount(ownerUsername, fullType)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return Data.GetLiteralSpecialCount(warehouse and warehouse.literalSpecialStock or nil, fullType)
end

function Warehouse.GetLiteralSpecialStockSnapshot(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return Data.BuildLiteralSpecialSnapshot(warehouse and warehouse.literalSpecialStock or nil)
end

function Warehouse.AddLiteralSpecial(ownerUsername, entry)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(owner)
    if not warehouse then
        return 0
    end

    local normalized = Data.NormalizeOutputEntry(entry)
    if not normalized then
        return 0
    end

    normalized.forceLiteral = true
    normalized.literalSpecial = true
    local totalWeight = Data.GetEntryWeight(normalized.fullType, normalized.qty)
    if totalWeight > 0 and totalWeight > Warehouse.GetRemainingCapacity(warehouse) then
        return 0
    end

    local added = Data.AddLiteralSpecialStockEntry(warehouse.literalSpecialStock, normalized)
    if added > 0 then
        Warehouse.TouchItemsVersion(owner)
        Warehouse.TouchSummaryVersion(owner)
        Warehouse.Recalculate(warehouse)
    end
    return added
end

function Warehouse.TakeLiteralSpecial(ownerUsername, requestedQty, filterFn, _reasonMeta)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(owner)
    if not warehouse then
        return {}, 0
    end

    local removed, taken = Data.TakeLiteralSpecialStock(warehouse.literalSpecialStock, requestedQty, filterFn)
    if taken > 0 then
        Warehouse.TouchItemsVersion(owner)
        Warehouse.TouchSummaryVersion(owner)
        Warehouse.Recalculate(warehouse)
    end
    return removed, taken
end

function Warehouse.CanConsumeCategories(ownerUsername, requirements)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local stock = warehouse and warehouse.abstractStock or {}

    for _, requirement in ipairs(requirements or {}) do
        local categoryId = tostring(requirement and requirement.category or "")
        local needed = normalizePositiveInteger(requirement and requirement.count)
        if categoryId ~= "" and Data.GetAbstractStockCount(stock, categoryId) < needed then
            return false
        end
    end

    return true
end

function Warehouse.ConsumeCategories(ownerUsername, requirements, _reasonMeta)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(owner)
    if not warehouse or not Warehouse.CanConsumeCategories(owner, requirements) then
        return false
    end

    for _, requirement in ipairs(requirements or {}) do
        local categoryId = tostring(requirement and requirement.category or "")
        local needed = normalizePositiveInteger(requirement and requirement.count)
        if categoryId ~= "" and needed > 0 then
            Data.TakeAbstractStock(warehouse.abstractStock, categoryId, needed)
        end
    end

    Warehouse.TouchItemsVersion(owner)
    Warehouse.TouchSummaryVersion(owner)
    Warehouse.Recalculate(warehouse)
    return true
end

function Warehouse.TakeCategoryUnits(ownerUsername, categoryId, amount, _reasonMeta)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(owner)
    if not warehouse then
        return 0
    end

    local taken = 0
    local takenWeight = 0
    taken, takenWeight = Data.TakeAbstractStock(warehouse.abstractStock, categoryId, amount)
    if taken > 0 then
        Warehouse.TouchItemsVersion(owner)
        Warehouse.TouchSummaryVersion(owner)
        Warehouse.Recalculate(warehouse)
    end
    return taken, takenWeight
end

return Warehouse
