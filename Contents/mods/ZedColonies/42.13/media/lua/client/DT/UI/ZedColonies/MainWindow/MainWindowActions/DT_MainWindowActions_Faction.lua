DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

function DT_MainWindow:updateFactionButton()
    if not self.btnFaction then
        return
    end

    local status = (DT_System and DT_System.GetOwnedFactionStatus and DT_System.GetOwnedFactionStatus()) or DT_MainWindow.cachedOwnedFactionStatus
    if status and status.faction then
        self.btnFaction:setTitle("Open Faction")
        self.btnFaction:setEnable(true)
        return
    end

    if status and status.canCreate == true then
        self.btnFaction:setTitle("Create Faction")
        self.btnFaction:setEnable(true)
        return
    end

    self.btnFaction:setTitle("Faction Locked")
    self.btnFaction:setEnable(false)
end

function DT_MainWindow:onOpenFaction()
    if not DT_System or not DT_System.OpenOwnedFactionManagement then
        self:updateStatus("Faction management is unavailable.")
        return
    end

    local ok, msg = DT_System.OpenOwnedFactionManagement()
    if msg and msg ~= "" then
        self:updateStatus(msg)
    elseif ok then
        self:updateStatus("Opening faction management...")
    end
end
