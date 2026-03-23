function DT_MainWindow:onOpenBuildings()
    if DT_BuildingsWindow and DT_BuildingsWindow.Open then
        DT_BuildingsWindow.Open(self)
        self:updateStatus("Opening Buildings management...")
    end
end
