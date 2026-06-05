DC_MainWindow = DC_MainWindow or {}

local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return fallback or key
end

function DC_MainWindow:onOpenCharacter()
    if not self.selectedWorkerSummary then
        self:updateStatus(T("DCCommon_UI_MainWindow_SelectWorkerFirst", "Select a worker first."))
        return
    end

    DC_ColonyCharacterWindow.OpenWorker(self.selectedWorker or self.selectedWorkerSummary)
    self:updateStatus(T("DCCommon_UI_MainWindow_OpeningCharacterSheet", "Opening character sheet..."))
end
