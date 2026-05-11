DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local function getKnownWorkerVersion(window, includeWorkerLedgers, bypassKnownVersion)
    if bypassKnownVersion then
        return nil
    end

    if includeWorkerLedgers == true then
        return window.workerDetailVersion
            or (DC_MainWindow and DC_MainWindow.cachedDetailVersions and DC_MainWindow.cachedDetailVersions[window.workerID])
            or nil
    end

    return window.workerSummaryVersion
end

local function getKnownWarehouseVersion(window, includeLedgers, bypassKnownVersion)
    if bypassKnownVersion then
        return nil
    end

    if includeLedgers == true then
        return window.warehouseVersion
    end

    return window.warehouseSummaryVersion
end

local function hasWorkerLedgerTables(worker)
    return type(worker) == "table"
        and type(worker.nutritionLedger) == "table"
        and type(worker.toolLedger) == "table"
        and type(worker.skills) == "table"
end

local function hasWarehouseLedgerTables(worker)
    local warehouse = type(worker) == "table" and worker.warehouse or nil
    local ledgers = type(warehouse) == "table" and warehouse.ledgers or nil
    return type(ledgers) == "table"
        and type(ledgers.provisions) == "table"
        and type(ledgers.equipment) == "table"
        and type(ledgers.output) == "table"
end

function DC_SupplyWindow:onRefresh()
    self:startInventoryScan()
    self.autoRefreshPending = true
    self.initialSummarySyncPending = nil
    self.fullHydrationPending = true
    self.fullHydrationDelayTicks = 6
    self.fullHydrationRequested = false
    self:requestWorkerDetails({
        includeWorkerLedgers = false,
        includeWarehouseLedgers = false
    })
end

function DC_SupplyWindow:requestWorkerDetails(options)
    if not self.workerID then
        return
    end

    options = options or {}
    local includeWorkerLedgers = options.includeWorkerLedgers ~= false
    local includeWarehouseLedgers = options.includeWarehouseLedgers ~= false

    self:sendColonyCommand("RequestWorkerDetails", {
        workerID = self.workerID,
        knownVersion = getKnownWorkerVersion(self, includeWorkerLedgers, options.bypassWorkerKnownVersion == true),
        includeWorkerLedgers = includeWorkerLedgers
    })
    self:sendColonyCommand("RequestWarehouse", {
        knownVersion = getKnownWarehouseVersion(self, includeWarehouseLedgers, options.bypassWarehouseKnownVersion == true),
        includeLedgers = includeWarehouseLedgers
    })
end

function DC_SupplyWindow:hasCanonicalWorkerDetail()
    if hasWorkerLedgerTables(self.workerData) and hasWarehouseLedgerTables(self.workerData) then
        return true
    end

    local resolver = DC_SupplyWindow.Internal and DC_SupplyWindow.Internal.resolveWorkerDetail or nil
    local resolvedWorker = resolver and resolver(self.workerID) or nil
    if resolvedWorker and hasWorkerLedgerTables(resolvedWorker) and hasWarehouseLedgerTables(resolvedWorker) then
        if self.workerData ~= resolvedWorker then
            self:setWorkerData(resolvedWorker)
        end
        return true
    end

    return false
end

function DC_SupplyWindow:isPlayerInventoryReady()
    return self.scanning ~= true
end

function DC_SupplyWindow:ensureCanonicalWorkerDetail(showStatus, bypassKnownVersions)
    if self:hasCanonicalWorkerDetail() then
        return true
    end

    if self.requestWorkerDetails then
        self:requestWorkerDetails({
            includeWorkerLedgers = true,
            includeWarehouseLedgers = true,
            bypassWorkerKnownVersion = bypassKnownVersions == true,
            bypassWarehouseKnownVersion = bypassKnownVersions == true,
        })
    end

    if showStatus ~= false then
        self:updateStatus("Companion inventory is still loading. Please wait a moment.")
    end
    return false
end

function DC_SupplyWindow:refreshAfterMissingTransfer()
    self:startInventoryScan()
    self:ensureCanonicalWorkerDetail(false, true)
end
