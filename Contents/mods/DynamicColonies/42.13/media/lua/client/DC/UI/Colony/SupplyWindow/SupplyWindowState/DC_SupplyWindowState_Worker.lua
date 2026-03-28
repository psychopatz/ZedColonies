DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function DC_SupplyWindow:refreshWorkerEntries()
    self.workerEntries = {}

    if self.pruneOptimisticEquipmentDuplicates then
        self:pruneOptimisticEquipmentDuplicates()
    end

    local worker = self.workerData
    local isWarehouseView = Internal.isWarehouseView and Internal.isWarehouseView(self)
    local activeTab = self.activeTab or Internal.Tabs.Provisions
    local warehouse = worker and worker.warehouse or nil
    local warehouseLedgers = warehouse and warehouse.ledgers or {}
    local config = Internal.Config or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")

    if activeTab == Internal.Tabs.Equipment then
        local ledger = isWarehouseView and (warehouseLedgers.equipment or {}) or (worker and worker.toolLedger or {})
        for index, ledgerEntry in ipairs(ledger) do
            local entry = Internal.buildWorkerToolEntry(ledgerEntry, index)
            if entry then
                self.workerEntries[#self.workerEntries + 1] = entry
            end
        end

        if not isWarehouseView then
            for _, placeholderEntry in ipairs(Internal.getMissingEquipmentPlaceholderEntries(worker)) do
                self.workerEntries[#self.workerEntries + 1] = placeholderEntry
            end
        end
    elseif activeTab == Internal.Tabs.Output then
        local ledger = nil
        if isWarehouseView then
            ledger = warehouseLedgers.output or {}
        elseif normalizedJob == ((config.JobTypes or {}).Scavenge) then
            ledger = worker and worker.haulLedger or {}
        else
            ledger = worker and worker.outputLedger or {}
        end
        for index, ledgerEntry in ipairs(ledger) do
            local entry = Internal.buildWorkerOutputEntry(ledgerEntry, index)
            if entry then
                self.workerEntries[#self.workerEntries + 1] = entry
            end
        end
    else
        local moneyEntry = (not isWarehouseView) and Internal.buildWorkerMoneyEntry(worker) or nil
        if moneyEntry then
            self.workerEntries[#self.workerEntries + 1] = moneyEntry
        end
        local ledger = isWarehouseView and (warehouseLedgers.provisions or {}) or (worker and worker.nutritionLedger or {})
        for index, ledgerEntry in ipairs(ledger) do
            local entry = Internal.buildWorkerSupplyEntry(ledgerEntry, index)
            if entry then
                self.workerEntries[#self.workerEntries + 1] = entry
            end
        end
    end

    table.sort(self.workerEntries, Internal.compareEntries)
    self:rebuildWorkerList()
    if self.updateTransferControls then
        self:updateTransferControls()
    end
end

function DC_SupplyWindow:rebuildWorkerList()
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
end

function DC_SupplyWindow:setWorkerData(worker)
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
    self:refreshWorkerEntries()
end
