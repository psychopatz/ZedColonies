DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function Internal.copyWarehouseDetailTable(source)
    if type(source) ~= "table" then
        return nil
    end

    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

function Internal.mergeWarehouseDetail(previousWarehouse, incomingWarehouse)
    if type(incomingWarehouse) ~= "table" then
        return Internal.copyWarehouseDetailTable(previousWarehouse) or incomingWarehouse
    end

    local merged = Internal.copyWarehouseDetailTable(previousWarehouse) or {}
    for key, value in pairs(incomingWarehouse) do
        merged[key] = value
    end

    if incomingWarehouse.ledgers == nil and type(previousWarehouse) == "table" and type(previousWarehouse.ledgers) == "table" then
        merged.ledgers = Internal.copyWarehouseDetailTable(previousWarehouse.ledgers)
    elseif type(incomingWarehouse.ledgers) == "table" then
        local previousLedgers = type(previousWarehouse) == "table" and type(previousWarehouse.ledgers) == "table" and previousWarehouse.ledgers or {}
        merged.ledgers = {
            provisions = type(incomingWarehouse.ledgers.provisions) == "table"
                and incomingWarehouse.ledgers.provisions
                or previousLedgers.provisions,
            equipment = type(incomingWarehouse.ledgers.equipment) == "table"
                and incomingWarehouse.ledgers.equipment
                or previousLedgers.equipment,
            output = type(incomingWarehouse.ledgers.output) == "table"
                and incomingWarehouse.ledgers.output
                or previousLedgers.output,
        }
    end

    return merged
end

function Internal.handleWarehouseSync(window, args)
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    if args and args.unchanged == true then
        if args.includeLedgers == true or type(args and args.ledgerMask) == "table" then
            window.warehouseVersionsByKey = window.warehouseVersionsByKey or {}
            window.warehouseVersionsByKey[Internal.getWarehouseSyncVersionKey and Internal.getWarehouseSyncVersionKey(args and args.ledgerMask) or "warehouse|summary"] = args and args.version or nil
        else
            window.warehouseSummaryVersion = args and args.version or window.warehouseSummaryVersion
        end
        if window.autoRefreshPending then
            window.autoRefreshPending = nil
        end
        if Internal.debugPerf then
            Internal.debugPerf("WarehouseSync", startedAt, 1, {
                token = window.debugOpenToken,
                unchanged = true,
                version = args and args.version or "nil",
            })
        end
        return true
    end

    local currentWorker = window.workerData or {}
    local previousInventoryVersion = currentWorker.warehouse and tostring(currentWorker.warehouse.inventoryVersion or "") or ""
    currentWorker.warehouse = Internal.mergeWarehouseDetail(currentWorker.warehouse, args and args.warehouse or nil)
    if args and (args.includeLedgers == true or type(args.ledgerMask) == "table") then
        window.warehouseVersionsByKey = window.warehouseVersionsByKey or {}
        window.warehouseVersionsByKey[Internal.getWarehouseSyncVersionKey and Internal.getWarehouseSyncVersionKey(args and args.ledgerMask) or "warehouse|summary"] = args and args.version or nil
    else
        window.warehouseSummaryVersion = args and args.version or nil
    end
    local nextInventoryVersion = currentWorker.warehouse and tostring(currentWorker.warehouse.inventoryVersion or "") or ""
    if previousInventoryVersion ~= nextInventoryVersion and window.invalidateWarehouseInventoryFeed then
        window:invalidateWarehouseInventoryFeed()
    end
    window:setWorkerData(currentWorker)
    if window.startWarehouseInventoryFeed and Internal.isWarehouseInventoryTab and Internal.isWarehouseInventoryTab(window) then
        window:startWarehouseInventoryFeed(previousInventoryVersion ~= nextInventoryVersion)
    end
    if window.refreshPlayerMoneyCache then
        window:refreshPlayerMoneyCache(true)
    end
    if not window.autoRefreshPending then
        window:updateStatus("Warehouse reserves refreshed.")
    end
    if Internal.debugPerf then
        Internal.debugPerf("WarehouseSync", startedAt, 4, {
            token = window.debugOpenToken,
            unchanged = false,
            version = args and args.version or "nil",
            inventoryVersion = currentWorker.warehouse and currentWorker.warehouse.inventoryVersion or "nil",
        })
    end
    return true
end

function Internal.handleWarehouseInventoryFeedSync(window, args)
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    local state = window.ensureWarehouseInventoryFeedState and window:ensureWarehouseInventoryFeedState() or nil
    if not state then
        return true
    end

    state.requestPending = false
    if args and args.unchanged == true then
        state.loading = false
        state.complete = true
        state.hasMore = false
        state.version = args and args.version or state.version
        if Internal.isWarehouseInventoryTab and Internal.isWarehouseInventoryTab(window) then
            window:refreshWorkerEntries()
        end
        if Internal.debugPerf then
            Internal.debugPerf("WarehouseFeedSync", startedAt, 1, {
                token = window.debugOpenToken,
                unchanged = true,
                version = args and args.version or "nil",
            })
        end
        return true
    end

    local responseFilter = Internal.normalizeFilterText(args and args.filterText or "")
    if responseFilter ~= state.filterText then
        return true
    end

    local cursor = math.max(0, math.floor(tonumber(args and args.cursor) or 0))
    if cursor <= 0 then
        state.rows = {}
    end

    for _, row in ipairs(args and args.rows or {}) do
        state.rows[#state.rows + 1] = row
    end

    state.version = args and args.version or state.version
    state.nextCursor = args and args.nextCursor or nil
    state.hasMore = args and args.hasMore == true
    state.totalRows = math.max(#(state.rows or {}), math.floor(tonumber(args and args.totalRows) or 0))
    state.complete = state.hasMore ~= true
    state.loading = state.hasMore == true

    if Internal.isWarehouseInventoryTab and Internal.isWarehouseInventoryTab(window) then
        window:refreshWorkerEntries()
    end
    if Internal.debugPerf then
        Internal.debugPerf("WarehouseFeedSync", startedAt, 4, {
            token = window.debugOpenToken,
            cursor = cursor,
            rows = #(args and args.rows or {}),
            totalRows = state.totalRows or 0,
            hasMore = state.hasMore == true,
            version = state.version or "nil",
        })
    end
    return true
end

