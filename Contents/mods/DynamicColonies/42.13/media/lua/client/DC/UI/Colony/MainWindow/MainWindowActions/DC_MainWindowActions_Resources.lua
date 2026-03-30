function DC_MainWindow:onOpenResources()
    if DC_ResourcesWindow and DC_ResourcesWindow.Open then
        DC_ResourcesWindow.Open(self)
        self:updateStatus("Opening Resources...")
    end
end
