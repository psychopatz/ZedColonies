DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

function DT_SupplyWindow:onRefresh()
    self:startInventoryScan()
    if self.workerID then
        local includeWarehouseLedgers = self.viewMode == ((DT_SupplyWindow.Internal.ViewModes or {}).Warehouse)
        self:sendLabourCommand("RequestWorkerDetails", {
            workerID = self.workerID,
            includeWarehouseLedgers = includeWarehouseLedgers
        })
    end
end

function DT_SupplyWindow:requestWorkerDetails()
    if not self.workerID then
        return
    end

    local includeWarehouseLedgers = self.viewMode == ((DT_SupplyWindow.Internal.ViewModes or {}).Warehouse)
    self:sendLabourCommand("RequestWorkerDetails", {
        workerID = self.workerID,
        includeWarehouseLedgers = includeWarehouseLedgers
    })
end
