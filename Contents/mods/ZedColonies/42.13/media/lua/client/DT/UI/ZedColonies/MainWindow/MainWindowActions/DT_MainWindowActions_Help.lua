DT_MainWindow = DT_MainWindow or {}

function DT_MainWindow:onOpenHelp()
    DT_LabourHelpWindow.Open()
    self:updateStatus("Opened scavenging help.")
end
