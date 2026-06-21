DC_Colony = DC_Colony or {}
DC_Colony.AbstractInventory = DC_Colony.AbstractInventory or {}
DC_Colony.AbstractInventory.Internal = DC_Colony.AbstractInventory.Internal or {}

local AbstractInventory = DC_Colony.AbstractInventory
local Internal = AbstractInventory.Internal
local Data = Internal.Data or {}

Internal.Data = Data

local function getPerfNowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    if getTimestamp then
        return math.floor((tonumber(getTimestamp()) or 0) * 1000)
    end
    return math.floor(os.clock() * 1000)
end

local function isDebugLoggingEnabled()
    return DynamicTrading
        and DynamicTrading.ShouldLogLevel
        and DynamicTrading.ShouldLogLevel("trace", "DynamicColonies", "AbstractInventory")
end

local function debugPerf(tag, startMs, thresholdMs, fields)
    if not isDebugLoggingEnabled() then
        return 0
    end

    local elapsed = math.max(0, getPerfNowMs() - math.max(0, tonumber(startMs) or 0))
    if elapsed < math.max(0, tonumber(thresholdMs) or 0) then
        return elapsed
    end

    local parts = {}
    for key, value in pairs(fields or {}) do
        parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)
    end
    table.sort(parts)
    local message = table.concat(parts, " ") .. " ms=" .. tostring(elapsed)
    if DynamicTrading and DynamicTrading.LogTrace then
        DynamicTrading.LogTrace("DynamicColonies", "AbstractInventory", tostring(tag or "Perf"), message)
    elseif DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DynamicColonies", "AbstractInventory", tostring(tag or "Perf"), message)
    end
    return elapsed
end

local function getCategoryDefinition(categoryId)
    local config = DC_Colony and DC_Colony.Config or nil
    return config and config.GetItemCategoryDefinition and config.GetItemCategoryDefinition(categoryId) or nil
end

local function getDisplayNameForFullType(fullType)
    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
    return registryInternal and registryInternal.GetDisplayNameForFullType and registryInternal.GetDisplayNameForFullType(fullType) or tostring(fullType or "")
end

local function copyRow(row)
    local copy = {}
    for key, value in pairs(row or {}) do
        copy[key] = value
    end
    return copy
end

local function normalizeFilterText(text)
    local value = string.lower(tostring(text or ""))
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function matchesFilter(row, filterText)
    local filter = normalizeFilterText(filterText)
    if filter == "" then
        return true
    end

    local haystacks = {
        string.lower(tostring(row and row.displayName or "")),
        string.lower(tostring(row and row.fullType or "")),
        string.lower(tostring(row and row.category or "")),
        string.lower(tostring(row and row.group or "")),
        string.lower(tostring(row and row.searchText or "")),
        string.lower(tostring(row and row.specialStockType or "")),
    }

    for _, haystack in ipairs(haystacks) do
        if haystack ~= "" and string.find(haystack, filter, 1, true) then
            return true
        end
    end

    return false
end

local function buildItemRows(ownerData)
    local rows = {}
    for fullType, entry in pairs(ownerData and ownerData.itemStock or {}) do
        local normalizedEntry = Data.NormalizeItemStockEntry(entry)
        local resolvedFullType = normalizedEntry.fullType ~= "" and normalizedEntry.fullType or tostring(fullType or "")
        if resolvedFullType ~= "" and normalizedEntry.qty > 0 then
            local categoryId = tostring(normalizedEntry.category or "")
            local group = tostring(normalizedEntry.group or "")
            if categoryId == "" or group == "" then
                local converted = DC_Colony and DC_Colony.Config and DC_Colony.Config.GetItemCategoryData
                    and DC_Colony.Config.GetItemCategoryData(resolvedFullType) or nil
                if categoryId == "" then
                    categoryId = tostring(converted and converted.category or "")
                end
                if group == "" then
                    group = tostring(converted and converted.group or "Waste")
                end
            end

            rows[#rows + 1] = {
                kind = "inventory",
                itemID = "item:" .. resolvedFullType,
                ledgerIndex = "item:" .. resolvedFullType,
                displayName = getDisplayNameForFullType(resolvedFullType),
                fullType = resolvedFullType,
                category = categoryId,
                group = group,
                qty = normalizedEntry.qty,
                unitWeight = normalizedEntry.qty > 0 and (normalizedEntry.totalWeight / normalizedEntry.qty) or 0,
                totalWeight = normalizedEntry.totalWeight,
                texture = nil,
                searchText = table.concat({
                    resolvedFullType,
                    categoryId,
                    group,
                }, " "),
                readOnly = true,
            }
        end
    end

    table.sort(rows, function(a, b)
        local aName = string.lower(tostring(a and a.displayName or ""))
        local bName = string.lower(tostring(b and b.displayName or ""))
        if aName == bName then
            return tostring(a and a.fullType or "") < tostring(b and b.fullType or "")
        end
        return aName < bName
    end)

    return rows
end

local function buildCategoryReserveRows(ownerData)
    local rows = {}
    local itemBackedCategoryStock = Data.BuildItemBackedCategoryStock(ownerData and ownerData.itemStock or nil)
    for categoryId, stockEntry in pairs(ownerData and ownerData.categoryStock or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            local normalizedStock = Data.NormalizeCategoryStockEntry(stockEntry)
            local itemBackedEntry = Data.NormalizeCategoryStockEntry(itemBackedCategoryStock[key] or nil)
            local remainingCount = math.max(0, normalizedStock.count - itemBackedEntry.count)
            local remainingWeight = math.max(0, normalizedStock.totalWeight - itemBackedEntry.totalWeight)
            if remainingCount > 0 or remainingWeight > 0 then
                local definition = getCategoryDefinition(key) or {}
                local foodEntry = Data.NormalizeFoodNutritionEntry(ownerData.foodNutritionPools and ownerData.foodNutritionPools[key] or nil)
                rows[#rows + 1] = {
                    kind = "category",
                    itemID = "category:" .. key,
                    ledgerIndex = "category:" .. key,
                    displayName = tostring(definition.displayName or key) .. " Reserve",
                    category = key,
                    group = tostring(definition.group or "Waste"),
                    qty = remainingCount,
                    unitWeight = remainingCount > 0 and (remainingWeight / remainingCount) or 0,
                    totalWeight = remainingWeight,
                    totalCalories = foodEntry.calories,
                    totalHydration = foodEntry.hydration,
                    texture = nil,
                    searchText = tostring(definition.group or "") .. " " .. key .. " reserve",
                    readOnly = true,
                }
            end
        end
    end

    table.sort(rows, function(a, b)
        local aName = string.lower(tostring(a and a.displayName or ""))
        local bName = string.lower(tostring(b and b.displayName or ""))
        if aName == bName then
            return tostring(a and a.category or "") < tostring(b and b.category or "")
        end
        return aName < bName
    end)

    return rows
end

local function buildLiteralSpecialRows(ownerData)
    local rows = {}
    for index, entry in ipairs(ownerData and ownerData.literalSpecialStock or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        rows[#rows + 1] = {
            kind = "special",
            itemID = "special:" .. tostring(index) .. ":" .. tostring(entry and entry.fullType or ""),
            ledgerIndex = "special:" .. tostring(index),
            displayName = tostring(entry and entry.displayName or getDisplayNameForFullType(entry and entry.fullType)),
            fullType = tostring(entry and entry.fullType or ""),
            qty = qty,
            unitWeight = math.max(0, tonumber(Data.GetEntryWeight(entry and entry.fullType, 1)) or 0),
            totalWeight = math.max(0, tonumber(Data.GetEntryWeight(entry and entry.fullType, qty)) or 0),
            texture = nil,
            entryID = entry and entry.entryID or nil,
            literalSpecial = true,
            specialStockType = entry and entry.specialStockType or nil,
            researchJobID = entry and entry.researchJobID or nil,
            searchText = tostring(entry and entry.specialStockType or ""),
            readOnly = true,
        }
    end

    table.sort(rows, function(a, b)
        local aName = string.lower(tostring(a and a.displayName or ""))
        local bName = string.lower(tostring(b and b.displayName or ""))
        if aName == bName then
            return tostring(a and a.fullType or "") < tostring(b and b.fullType or "")
        end
        return aName < bName
    end)

    return rows
end

function AbstractInventory.GetSummary(ownerUsername)
    local startedAt = getPerfNowMs()
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    if not ownerData then
        return nil
    end

    local summary = Data.CopySummaryTotals(ownerData.summaryTotals, ownerData)
    debugPerf("GetSummary", startedAt, 4, {
        owner = ownerUsername,
        totalItemCount = summary and summary.totalItemCount or 0,
        totalCategoryCount = summary and summary.totalCategoryCount or 0,
        totalWeight = summary and summary.totalWeight or 0,
    })
    return summary
end

function AbstractInventory.GetInventoryRows(ownerUsername, cursor, limit, filterText)
    local startedAt = getPerfNowMs()
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    if not ownerData then
        return {
            version = 1,
            cursor = 0,
            nextCursor = nil,
            hasMore = false,
            totalRows = 0,
            rows = {},
        }
    end

    local rows = buildItemRows(ownerData)
    local reserveRows = buildCategoryReserveRows(ownerData)
    local specialRows = buildLiteralSpecialRows(ownerData)
    for _, row in ipairs(reserveRows) do
        rows[#rows + 1] = row
    end
    for _, row in ipairs(specialRows) do
        rows[#rows + 1] = row
    end

    local filteredRows = {}
    for _, row in ipairs(rows) do
        if matchesFilter(row, filterText) then
            filteredRows[#filteredRows + 1] = row
        end
    end

    local normalizedCursor = math.max(0, math.floor(tonumber(cursor) or 0))
    local normalizedLimit = math.max(1, math.floor(tonumber(limit) or 32))
    local startIndex = normalizedCursor + 1
    local endIndex = math.min(#filteredRows, normalizedCursor + normalizedLimit)
    local pageRows = {}
    for index = startIndex, endIndex do
        pageRows[#pageRows + 1] = copyRow(filteredRows[index])
    end

    local nextCursor = endIndex < #filteredRows and endIndex or nil
    local response = {
        version = math.max(1, math.floor(tonumber(ownerData.version) or 1)),
        cursor = normalizedCursor,
        nextCursor = nextCursor,
        hasMore = nextCursor ~= nil,
        totalRows = #filteredRows,
        rows = pageRows,
        filterText = normalizeFilterText(filterText),
    }
    debugPerf("GetInventoryRows", startedAt, 8, {
        owner = ownerUsername,
        itemRows = #rows - #reserveRows - #specialRows,
        reserveRows = #reserveRows,
        specialRows = #specialRows,
        filteredRows = #filteredRows,
        pageRows = #pageRows,
        cursor = normalizedCursor,
        limit = normalizedLimit,
    })
    return response
end

return AbstractInventory
