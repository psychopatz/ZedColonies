DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function DC_SupplyWindow:setActiveTab(tabID)
    local targetTab = tabID or Internal.Tabs.Provisions
    local wasSameTab = self.activeTab == targetTab

    self.activeTab = targetTab
    self.selectedWorkerEntry = nil
    self.selectedPlayerEntry = nil
    self.activeSelectionSide = targetTab == Internal.Tabs.Equipment and "worker" or nil
    if self.bumpPresentationCacheVersion then
        self:bumpPresentationCacheVersion()
    end

    if self.refreshTabButtons then
        self:refreshTabButtons()
    end
    if self.updateTransferControls then
        self:updateTransferControls()
    end

    if self.preparePlayerEntriesForActiveTab then
        self:preparePlayerEntriesForActiveTab()
    else
        self:rebuildPlayerList()
    end
    self:refreshWorkerEntries()

    if self.requestActiveTabDetails then
        self:requestActiveTabDetails(false)
    end

    if wasSameTab then
        return
    end
end

function DC_SupplyWindow:refreshDetailSelection()
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
