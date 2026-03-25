DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getListBuildFields(side)
    if side == "worker" then
        return {
            list = "workerList",
            selected = "selectedWorkerEntry",
            rows = "pendingWorkerListRows",
            nextIndex = "pendingWorkerListNextIndex",
            selectedKey = "pendingWorkerListSelectedKey",
            selectedRowIndex = "pendingWorkerListSelectedRowIndex",
        }
    end

    return {
        list = "playerList",
        selected = "selectedPlayerEntry",
        rows = "pendingPlayerListRows",
        nextIndex = "pendingPlayerListNextIndex",
        selectedKey = "pendingPlayerListSelectedKey",
        selectedRowIndex = "pendingPlayerListSelectedRowIndex",
    }
end

function DC_SupplyWindow:beginChunkedListBuild(side, rows, selectedKey)
    local fields = getListBuildFields(side)
    local list = self[fields.list]
    if not list then
        return
    end

    list:clear()
    list.selected = -1
    list:setScrollHeight(0)
    list:setYScroll(0)

    self[fields.selected] = nil
    self[fields.rows] = rows or {}
    self[fields.nextIndex] = 1
    self[fields.selectedKey] = selectedKey
    self[fields.selectedRowIndex] = nil

    self:processChunkedListBuild(side, Internal.LIST_BUILD_BATCH_SIZE)
end

function DC_SupplyWindow:processChunkedListBuild(side, batchSize)
    local fields = getListBuildFields(side)
    local list = self[fields.list]
    local rows = self[fields.rows]
    if not list or not rows then
        return false
    end

    local nextIndex = tonumber(self[fields.nextIndex]) or 1
    local selectedKey = self[fields.selectedKey]
    local selectedRowIndex = self[fields.selectedRowIndex]
    local limit = math.max(1, tonumber(batchSize) or Internal.LIST_BUILD_BATCH_SIZE or 1)
    local added = 0

    while nextIndex <= #rows and added < limit do
        local entry = rows[nextIndex]
        if entry then
            list:addItem(Internal.formatEntryLabel(entry), entry)
            entry.rowIndex = #list.items
            if selectedKey and not selectedRowIndex and Internal.getEntrySelectionKey(entry) == selectedKey then
                selectedRowIndex = entry.rowIndex
            end
        end

        nextIndex = nextIndex + 1
        added = added + 1
    end

    self[fields.nextIndex] = nextIndex
    self[fields.selectedRowIndex] = selectedRowIndex

    if list.items and #list.items > 0 and list.selected < 1 then
        local initialIndex = selectedRowIndex or 1
        list.selected = initialIndex
        self[fields.selected] = list.items[initialIndex].item
    end

    if nextIndex > #rows then
        if list.items and #list.items > 0 then
            local finalIndex = selectedRowIndex or 1
            list.selected = finalIndex
            self[fields.selected] = list.items[finalIndex].item
        else
            self[fields.selected] = nil
        end

        self[fields.rows] = nil
        self[fields.nextIndex] = nil
        self[fields.selectedKey] = nil
        self[fields.selectedRowIndex] = nil
        self:refreshDetailSelection()
        return false
    end

    return true
end

function DC_SupplyWindow:processPendingListBuilds(batchSize)
    local pending = false
    if self.pendingPlayerListRows then
        pending = self:processChunkedListBuild("player", batchSize) or pending
    end
    if self.pendingWorkerListRows then
        pending = self:processChunkedListBuild("worker", batchSize) or pending
    end
    return pending
end

function DC_SupplyWindow:syncSearchFilters()
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

function DC_SupplyWindow:update()
    ISCollapsableWindow.update(self)
    self:syncSearchFilters()
    self.detailRefreshTicks = (tonumber(self.detailRefreshTicks) or 0) + 1

    if self.scanning then
        self:processInventoryScan(Internal.ENTRY_SCAN_BATCH_SIZE)
    end

    self:processPendingListBuilds(Internal.LIST_BUILD_BATCH_SIZE)

    if self.workerID
        and (self.detailRefreshTicks % 180) == 0
        and not self.scanning
        and self.requestWorkerDetails then
        self.autoRefreshPending = true
        self:requestWorkerDetails()
    end
end
