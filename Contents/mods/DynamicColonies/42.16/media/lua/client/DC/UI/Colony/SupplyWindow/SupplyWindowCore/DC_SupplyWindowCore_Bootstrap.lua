DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

Internal.Config = DC_Colony and DC_Colony.Config or Internal.Config or {}
Internal.Nutrition = DC_Colony and DC_Colony.Nutrition or Internal.Nutrition or {}
Internal.ENTRY_SCAN_BATCH_SIZE = 16
Internal.RAW_SCAN_STEP_LIMIT = 240
Internal.LIST_BUILD_BATCH_SIZE = 32
Internal.WAREHOUSE_FEED_PAGE_SIZE = 24
Internal.ICON_RESOLVE_BATCH_SIZE = 2
Internal.SCAN_TIME_BUDGET_MS = 2
Internal.HYDRATION_TIME_BUDGET_MS = 2
Internal.FINALIZE_TIME_BUDGET_MS = 2
Internal.LIST_BUILD_TIME_BUDGET_MS = 2
Internal.NutritionPreviewCache = Internal.NutritionPreviewCache or {}
Internal.InventoryEntryStaticCache = Internal.InventoryEntryStaticCache or {}
Internal.WeaponMetadataCache = Internal.WeaponMetadataCache or {}
Internal.TextureCache = Internal.TextureCache or {}
Internal.TextureQueue = Internal.TextureQueue or {}
Internal.TextureQueueSet = Internal.TextureQueueSet or {}
Internal.DETAIL_SUPPORT_PANEL_HEIGHT = 64
Internal.DETAIL_SUPPORT_PANEL_GAP = 6
Internal.DETAIL_SUPPORT_ICON_SIZE = 24
Internal.GROUP_TOGGLE_HIT_WIDTH = 18
Internal.GROUP_CHILD_INDENT = 14
Internal.ViewModes = {
    Inventory = "inventory",
    Warehouse = "warehouse",
}
Internal.Tabs = {
    Provisions = "provisions",
    Output = "output",
    Equipment = "equipment",
}

function Internal.isWarehouseView(window)
    return window and window.viewMode == Internal.ViewModes.Warehouse
end

function Internal.isInventoryView(window)
    return not Internal.isWarehouseView(window)
end

function Internal.getPerfNowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    if getTimestamp then
        return math.floor((tonumber(getTimestamp()) or 0) * 1000)
    end
    return math.floor(os.clock() * 1000)
end

function Internal.isTimeBudgetExceeded(startMs, budgetMs)
    local normalizedStart = tonumber(startMs)
    local normalizedBudget = math.max(0, tonumber(budgetMs) or 0)
    if not normalizedStart or normalizedBudget <= 0 then
        return false
    end
    return (Internal.getPerfNowMs() - normalizedStart) >= normalizedBudget
end

function Internal.isDebugLoggingEnabled()
    return DynamicTrading
        and DynamicTrading.ShouldLogLevel
        and DynamicTrading.ShouldLogLevel("debug", "DynamicColonies", "SupplyWindow")
end

local function buildDebugFields(fields)
    local parts = {}
    for key, value in pairs(fields or {}) do
        parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)
    end
    table.sort(parts)
    return table.concat(parts, " ")
end

function Internal.debugLog(tag, message, fields)
    if not Internal.isDebugLoggingEnabled() then
        return
    end

    local suffix = buildDebugFields(fields)
    local payload = tostring(message or "")
    if suffix ~= "" then
        payload = payload .. " " .. suffix
    end

    if DynamicTrading and DynamicTrading.LogDebug then
        DynamicTrading.LogDebug("DynamicColonies", "SupplyWindow", tostring(tag or "Log"), payload)
    elseif DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DynamicColonies", "SupplyWindow", tostring(tag or "Log"), payload)
    end
end

function Internal.debugPerf(tag, startMs, thresholdMs, fields)
    if not Internal.isDebugLoggingEnabled() then
        return 0
    end

    local elapsed = math.max(0, (Internal.getPerfNowMs() or 0) - math.max(0, tonumber(startMs) or 0))
    if elapsed < math.max(0, tonumber(thresholdMs) or 0) then
        return elapsed
    end

    local payload = {}
    for key, value in pairs(fields or {}) do
        payload[key] = value
    end
    payload.ms = elapsed
    Internal.debugLog(tag, "timing", payload)
    return elapsed
end
