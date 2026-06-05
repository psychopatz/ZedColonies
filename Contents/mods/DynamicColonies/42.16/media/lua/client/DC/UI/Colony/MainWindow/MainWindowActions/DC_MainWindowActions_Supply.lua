DC_MainWindow = DC_MainWindow or {}

local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return fallback or key
end

function DC_MainWindow:onOpenInventory()
    if not self.selectedWorkerSummary then
        self:updateStatus(T("DCCommon_UI_MainWindow_SelectWorkerFirst", "Select a worker first."))
        return
    end

    DC_SupplyWindow.Open(self.selectedWorker or self.selectedWorkerSummary, "inventory")
    self:updateStatus(T("DCCommon_UI_MainWindow_OpeningNpcInventory", "Opening NPC inventory..."))
end

function DC_MainWindow:onOpenWarehouse()
    if not self.selectedWorkerSummary then
        self:updateStatus(T("DCCommon_UI_MainWindow_SelectWorkerFirst", "Select a worker first."))
        return
    end

    DC_SupplyWindow.Open(self.selectedWorker or self.selectedWorkerSummary, "warehouse")
    self:updateStatus(T("DCCommon_UI_MainWindow_OpeningWarehouse", "Opening warehouse..."))
end
