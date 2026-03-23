DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

function DT_SupplyWindow:setActiveTab(tabID)
    local targetTab = tabID or Internal.Tabs.Provisions
    if self.activeTab == targetTab then
        return
    end

    self.activeTab = targetTab
    self.selectedWorkerEntry = nil

    if self.refreshTabButtons then
        self:refreshTabButtons()
    end
    if self.updateTransferControls then
        self:updateTransferControls()
    end

    self:rebuildPlayerList()
    self:refreshWorkerEntries()
end

function DT_SupplyWindow:refreshDetailSelection()
    local entry = nil
    local side = self.activeSelectionSide

    if side == "worker" then
        entry = self.selectedWorkerEntry
    else
        side = "player"
        entry = self.selectedPlayerEntry
    end

    if not entry then
        if self.selectedPlayerEntry then
            side = "player"
            entry = self.selectedPlayerEntry
        elseif self.selectedWorkerEntry then
            side = "worker"
            entry = self.selectedWorkerEntry
        else
            side = nil
        end
    end

    self.activeSelectionSide = side
    self:updateItemDetail(entry, side)
end

