require "DC/UI/Colony/DebugArchive/DC_DebugArchiveWindow"

function DC_MainWindow:onOpenDebugArchive()
    if DC_System and DC_System.CanUseDebug and not DC_System.CanUseDebug() then
        self:updateStatus("Debug archive is unavailable for this player.")
        return
    end

    if DC_DebugArchiveWindow and DC_DebugArchiveWindow.Open then
        DC_DebugArchiveWindow.Open(self)
        self:updateStatus("Opening debug archive...")
    end
end
