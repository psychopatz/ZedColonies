DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

function DC_SupplyWindow:onRefresh()
    self:startInventoryScan()
    if self.workerID then
        self:sendColonyCommand("RequestWorkerDetails", {
            workerID = self.workerID,
            knownVersion = DC_MainWindow and DC_MainWindow.cachedDetailVersions and DC_MainWindow.cachedDetailVersions[self.workerID] or nil,
            includeWorkerLedgers = true
        })
        self:sendColonyCommand("RequestWarehouse", {
            knownVersion = self.warehouseVersion,
            includeLedgers = true
        })
    end
end

function DC_SupplyWindow:requestWorkerDetails()
    if not self.workerID then
        return
    end

    self:sendColonyCommand("RequestWorkerDetails", {
        workerID = self.workerID,
        knownVersion = DC_MainWindow and DC_MainWindow.cachedDetailVersions and DC_MainWindow.cachedDetailVersions[self.workerID] or nil,
        includeWorkerLedgers = true
    })
    self:sendColonyCommand("RequestWarehouse", {
        knownVersion = self.warehouseVersion,
        includeLedgers = true
    })
end
