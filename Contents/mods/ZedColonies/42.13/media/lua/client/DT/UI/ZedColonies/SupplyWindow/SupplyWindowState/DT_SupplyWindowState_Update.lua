DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

function DT_SupplyWindow:syncSearchFilters()
    local playerFilter = Internal.normalizeFilterText(Internal.getSearchText(self.playerSearch))
    if playerFilter ~= (self.lastPlayerFilter or "") then
        self.lastPlayerFilter = playerFilter
        self:rebuildPlayerList()
    end

    local workerFilter = Internal.normalizeFilterText(Internal.getSearchText(self.workerSearch))
    if workerFilter ~= (self.lastWorkerFilter or "") then
        self.lastWorkerFilter = workerFilter
        self:rebuildWorkerList()
    end
end

function DT_SupplyWindow:update()
    ISCollapsableWindow.update(self)
    self:syncSearchFilters()
    self.detailRefreshTicks = (tonumber(self.detailRefreshTicks) or 0) + 1

    if self.scanning then
        self:processInventoryScan(Internal.ENTRY_SCAN_BATCH_SIZE)
    end

    if self.workerID
        and (self.detailRefreshTicks % 180) == 0
        and not self.scanning
        and self.requestWorkerDetails then
        self.autoRefreshPending = true
        self:requestWorkerDetails()
    end
end

