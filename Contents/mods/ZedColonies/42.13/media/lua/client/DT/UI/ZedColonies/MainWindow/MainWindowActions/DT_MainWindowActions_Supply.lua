DT_MainWindow = DT_MainWindow or {}

function DT_MainWindow:onOpenInventory()
    if not self.selectedWorkerSummary then
        self:updateStatus("Select a worker first.")
        return
    end

    DT_SupplyWindow.Open(self.selectedWorker or self.selectedWorkerSummary, "inventory")
    self:updateStatus("Opening NPC inventory...")
end

function DT_MainWindow:onOpenWarehouse()
    if not self.selectedWorkerSummary then
        self:updateStatus("Select a worker first.")
        return
    end

    DT_SupplyWindow.Open(self.selectedWorker or self.selectedWorkerSummary, "warehouse")
    self:updateStatus("Opening warehouse...")
end
