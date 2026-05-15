DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getListBuildFields(side)
    if side == "worker" then
        return {
            list = "workerList",
            selected = "selectedWorkerEntry",
            rows = "pendingWorkerListRows",
            nextIndex = "pendingWorkerListNextIndex",
            selectedKey = "pendingWorkerListSelectedKey",
            selectedRowIndex = "pendingWorkerListSelectedRowIndex",
        }
    end

    return {
        list = "playerList",
        selected = "selectedPlayerEntry",
        rows = "pendingPlayerListRows",
        nextIndex = "pendingPlayerListNextIndex",
        selectedKey = "pendingPlayerListSelectedKey",
        selectedRowIndex = "pendingPlayerListSelectedRowIndex",
    }
end

function DC_SupplyWindow:beginChunkedListBuild(side, rows, selectedKey)
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    local fields = getListBuildFields(side)
    local list = self[fields.list]
    if not list then
        return
    end

    list:clear()
    list.selected = -1
    list:setScrollHeight(0)
    list:setYScroll(0)

    self[fields.selected] = nil
    self[fields.rows] = rows or {}
    self[fields.nextIndex] = 1
    self[fields.selectedKey] = selectedKey
    self[fields.selectedRowIndex] = nil

    self:processChunkedListBuild(side, Internal.LIST_BUILD_BATCH_SIZE)
    if Internal.debugPerf then
        Internal.debugPerf("ListBuildStart", startedAt, 6, {
            token = self.debugOpenToken,
            side = side,
            rows = #(rows or {}),
            selectedKey = selectedKey and "yes" or "no",
        })
    end
end

function DC_SupplyWindow:processChunkedListBuild(side, batchSize)
    local fields = getListBuildFields(side)
    local list = self[fields.list]
    local rows = self[fields.rows]
    if not list or not rows then
        return false
    end

    local nextIndex = tonumber(self[fields.nextIndex]) or 1
    local selectedKey = self[fields.selectedKey]
    local selectedRowIndex = self[fields.selectedRowIndex]
    local limit = math.max(1, tonumber(batchSize) or Internal.LIST_BUILD_BATCH_SIZE or 1)
    local added = 0
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil

    while nextIndex <= #rows and added < limit do
        local entry = rows[nextIndex]
        if entry then
            list:addItem(Internal.formatEntryLabel(entry), entry)
            entry.rowIndex = #list.items
            if selectedKey and not selectedRowIndex and Internal.getEntrySelectionKey(entry) == selectedKey then
                selectedRowIndex = entry.rowIndex
            end
        end

        nextIndex = nextIndex + 1
        added = added + 1
        if Internal.isTimeBudgetExceeded
            and Internal.isTimeBudgetExceeded(startedAt, Internal.LIST_BUILD_TIME_BUDGET_MS) then
            break
        end
    end

    if Internal.debugPerf then
        Internal.debugPerf("ListBuildBatch", startedAt, 8, {
            token = self.debugOpenToken,
            side = side,
            added = added,
            nextIndex = nextIndex,
            totalRows = #rows,
        })
    end

    self[fields.nextIndex] = nextIndex
    self[fields.selectedRowIndex] = selectedRowIndex

    if list.items and #list.items > 0 and list.selected < 1 then
        local initialIndex = selectedRowIndex or 1
        list.selected = initialIndex
        self[fields.selected] = list.items[initialIndex].item
    end

    if nextIndex > #rows then
        if list.items and #list.items > 0 then
            local finalIndex = selectedRowIndex or 1
            list.selected = finalIndex
            self[fields.selected] = list.items[finalIndex].item
        else
            self[fields.selected] = nil
        end

        self[fields.rows] = nil
        self[fields.nextIndex] = nil
        self[fields.selectedKey] = nil
        self[fields.selectedRowIndex] = nil
        self:refreshDetailSelection()
        return false
    end

    return true
end

function DC_SupplyWindow:processPendingListBuilds(batchSize)
    local pending = false
    if self.pendingPlayerListRows then
        pending = self:processChunkedListBuild("player", batchSize) or pending
    end
    if self.pendingWorkerListRows then
        pending = self:processChunkedListBuild("worker", batchSize) or pending
    end
    return pending
end

function DC_SupplyWindow:syncSearchFilters()
    local playerFilter = Internal.normalizeFilterText(Internal.getSearchText(self.playerSearch))
    if playerFilter ~= (self.lastPlayerFilter or "") then
        self.lastPlayerFilter = playerFilter
        self:rebuildPlayerList()
    end

    local workerFilter = Internal.normalizeFilterText(Internal.getSearchText(self.workerSearch))
    if workerFilter ~= (self.lastWorkerFilter or "") then
        self.lastWorkerFilter = workerFilter
        if self.startWarehouseInventoryFeed
            and Internal.isWarehouseInventoryTab
            and Internal.isWarehouseInventoryTab(self) then
            self:startWarehouseInventoryFeed(true)
        else
            self:rebuildWorkerList()
        end
    end
end

function DC_SupplyWindow:update()
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    ISCollapsableWindow.update(self)
    self:syncSearchFilters()
    self.detailRefreshTicks = (tonumber(self.detailRefreshTicks) or 0) + 1

    if self.refreshPlayerMoneyCache
        and (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Provisions
        and Internal.isInventoryView
        and Internal.isInventoryView(self)
        and (self.detailRefreshTicks % 15) == 0 then
        self:refreshPlayerMoneyCache(false)
    end

    if self.playerMoneyDirty
        and self.refreshPlayerMoneyCache
        and (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Provisions
        and Internal.isInventoryView
        and Internal.isInventoryView(self)
        and not self.scanning
        and not self.playerHydrationState
        and not self.playerFinalizeState
        and not self.pendingPlayerListRows then
        self:refreshPlayerMoneyCache(true)
    end

    if self.initialSummarySyncPending
        and self.workerID
        and self.detailRefreshTicks >= 1
        and self.requestWorkerDetails then
        self.initialSummarySyncPending = nil
        self:requestWorkerDetails({
            includeWorkerLedgers = false,
            includeWarehouseLedgers = false
        })
        if self.requestActiveTabDetails then
            self:requestActiveTabDetails(self.forceRefresh == true)
        end
    end

    if self.scanning then
        self:processInventoryScan(Internal.ENTRY_SCAN_BATCH_SIZE)
    end

    if self.playerHydrationState and not self.scanning then
        self:processPlayerTabHydration(Internal.ENTRY_SCAN_BATCH_SIZE)
    end

    if self.playerFinalizeState and not self.scanning and not self.playerHydrationState then
        self:processPlayerEntryFinalize(Internal.LIST_BUILD_BATCH_SIZE)
    end

    if self.processWarehouseInventoryFeed then
        self:processWarehouseInventoryFeed()
    end

    self:processPendingListBuilds(Internal.LIST_BUILD_BATCH_SIZE)
    if Internal.processTextureQueue then
        Internal.processTextureQueue(Internal.ICON_RESOLVE_BATCH_SIZE)
    end

    if self.deferredEquipmentPreloadPending
        and self.activeTab == ((Internal.Tabs or {}).Equipment)
        and not self.scanning
        and not self.pendingPlayerListRows
        and not self.pendingWorkerListRows then
        self.deferredEquipmentPreloadTicks = math.max(0, math.floor(tonumber(self.deferredEquipmentPreloadTicks) or 0) + 1)
        if self.deferredEquipmentPreloadTicks >= 10 then
            if DC_EquipmentPickerModal and DC_EquipmentPickerModal.Preload and not DC_EquipmentPickerModal.instance then
                DC_EquipmentPickerModal.Preload()
            end
            self.deferredEquipmentPreloadPending = nil
        end
    end

    if self.workerID
        and (self.detailRefreshTicks % 180) == 0
        and not self.scanning
        and not self:hasPendingSupplyTransfers()
        and self.requestWorkerDetails then
        self.autoRefreshPending = true
        self:requestWorkerDetails({
            includeWorkerLedgers = false,
            includeWarehouseLedgers = false
        })
        if self.requestActiveTabDetails then
            self:requestActiveTabDetails(false)
        end
    end

    if Internal.debugPerf then
        Internal.debugPerf("WindowUpdate", startedAt, 12, {
            token = self.debugOpenToken,
            activeTab = self.activeTab,
            scanning = self.scanning == true,
            playerHydration = self.playerHydrationState and "yes" or "no",
            playerFinalize = self.playerFinalizeState and "yes" or "no",
            pendingPlayer = self.pendingPlayerListRows and "yes" or "no",
            pendingWorker = self.pendingWorkerListRows and "yes" or "no",
            warehouseFeedLoading = self.warehouseInventoryFeedState and self.warehouseInventoryFeedState.loading == true,
        })
    end
end
