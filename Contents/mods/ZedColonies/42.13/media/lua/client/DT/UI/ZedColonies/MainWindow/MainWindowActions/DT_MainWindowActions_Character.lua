DT_MainWindow = DT_MainWindow or {}

function DT_MainWindow:onOpenCharacter()
    if not self.selectedWorkerSummary then
        self:updateStatus("Select a worker first.")
        return
    end

    DT_LabourCharacterWindow.OpenWorker(self.selectedWorker or self.selectedWorkerSummary)
    self:updateStatus("Opening character sheet...")
end
