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
