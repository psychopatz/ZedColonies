DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function Internal.populateWarehouseWorkerEntries(window, targetEntries, warehouse, activeTab)
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    local entries = targetEntries or {}
    local warehouseLedgers = warehouse and warehouse.ledgers or {}

    if activeTab == Internal.Tabs.Equipment then
        for index, ledgerEntry in ipairs(warehouseLedgers.equipment or {}) do
            local entry = Internal.buildWorkerToolEntry(ledgerEntry, index)
            if entry then
                entries[#entries + 1] = entry
            end
        end
    elseif activeTab == Internal.Tabs.Output then
        local feedState = window and window.ensureWarehouseInventoryFeedState and window:ensureWarehouseInventoryFeedState() or nil
        for _, entry in ipairs(feedState and feedState.rows or {}) do
            entries[#entries + 1] = entry
        end
        if window and feedState and feedState.loading == true and #entries <= 0 then
            window:updateStatus("Loading warehouse inventory...")
        end
    else
        for index, ledgerEntry in ipairs(warehouseLedgers.provisions or {}) do
            local entry = Internal.buildWorkerSupplyEntry(ledgerEntry, index)
            if entry then
                entries[#entries + 1] = entry
            end
        end
    end

    if Internal.debugPerf then
        Internal.debugPerf("WarehouseEntriesPopulate", startedAt, 5, {
            token = window and window.debugOpenToken or "nil",
            activeTab = activeTab,
            count = #entries,
            feedRows = window and window.warehouseInventoryFeedState and #(window.warehouseInventoryFeedState.rows or {}) or 0,
        })
    end
    return entries
end

