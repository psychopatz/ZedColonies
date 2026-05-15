DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function DC_SupplyWindow:refreshWorkerEntries()
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    self.workerEntries = {}

    local worker = self.workerData
    local isWarehouseView = Internal.isWarehouseView and Internal.isWarehouseView(self)
    local activeTab = self.activeTab or Internal.Tabs.Provisions
    local warehouse = worker and worker.warehouse or nil
    if isWarehouseView then
        Internal.populateWarehouseWorkerEntries(self, self.workerEntries, warehouse, activeTab)
    else
        Internal.populateCompanionWorkerEntries(self, self.workerEntries, worker, activeTab)
    end

    if not (isWarehouseView and activeTab == Internal.Tabs.Output) then
        table.sort(self.workerEntries, Internal.compareEntries)
    end
    if self.bumpPresentationCacheVersion then
        self:bumpPresentationCacheVersion()
    end
    self:rebuildWorkerList()
    if self.refreshRenderCaches then
        self:refreshRenderCaches()
    end
    if self.updateTransferControls then
        self:updateTransferControls()
    end
    if Internal.debugPerf then
        Internal.debugPerf("WorkerEntriesRefresh", startedAt, 6, {
            token = self.debugOpenToken,
            activeTab = activeTab,
            warehouseView = isWarehouseView == true,
            count = #(self.workerEntries or {}),
            feedRows = self.warehouseInventoryFeedState and #(self.warehouseInventoryFeedState.rows or {}) or 0,
        })
    end
end

function DC_SupplyWindow:rebuildWorkerList()
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    if not self.workerList then
        return
    end

    local selectedKey = Internal.getEntrySelectionKey(self.selectedWorkerEntry)
    local filterText = Internal.getSearchText(self.workerSearch)
    local visibleEntries = {}
    for _, entry in ipairs(self.workerEntries or {}) do
        if Internal.shouldShowWorkerEntry(entry, self.activeTab or Internal.Tabs.Provisions)
            and Internal.matchesFilter(entry, filterText) then
            visibleEntries[#visibleEntries + 1] = entry
        end
    end

    self.workerVisibleEntries = visibleEntries
    self:beginChunkedListBuild(
        "worker",
        Internal.buildGroupedRows(visibleEntries, self.activeTab or Internal.Tabs.Provisions, "worker", self),
        selectedKey
    )
    if Internal.debugPerf then
        Internal.debugPerf("WorkerListRebuild", startedAt, 6, {
            token = self.debugOpenToken,
            activeTab = self.activeTab,
            visible = #visibleEntries,
            total = #(self.workerEntries or {}),
        })
    end
end

function DC_SupplyWindow:setWorkerData(worker)
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    self.workerData = worker
    if Internal.isWarehouseView and Internal.isWarehouseView(self) then
        local warehouseName = Internal.getWarehouseDisplayName and Internal.getWarehouseDisplayName(self) or tostring(self.workerName or self.workerID or "Warehouse")
        self.title = "Warehouse - " .. warehouseName
    elseif self.workerName then
        self.title = "NPC Inventory - " .. tostring(self.workerName)
    end
    if self.refreshTabButtons then
        self:refreshTabButtons()
    end
    if self.bumpPresentationCacheVersion then
        self:bumpPresentationCacheVersion()
    end
    self:refreshWorkerEntries()
    if Internal.debugPerf then
        Internal.debugPerf("SetWorkerData", startedAt, 8, {
            token = self.debugOpenToken,
            activeTab = self.activeTab,
            hasWarehouse = type(worker and worker.warehouse) == "table",
        })
    end
end
