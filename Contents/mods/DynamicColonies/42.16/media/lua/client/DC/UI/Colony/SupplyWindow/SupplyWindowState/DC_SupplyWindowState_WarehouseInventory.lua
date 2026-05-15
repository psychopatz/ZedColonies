DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function Internal.isWarehouseInventoryTab(window)
    return Internal.isWarehouseView
        and Internal.isWarehouseView(window)
        and (window and window.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Output
end

function DC_SupplyWindow:ensureWarehouseInventoryFeedState()
    self.warehouseInventoryFeedState = self.warehouseInventoryFeedState or {
        rows = {},
        version = nil,
        filterText = "",
        nextCursor = 0,
        hasMore = false,
        totalRows = 0,
        loading = false,
        requestPending = false,
        complete = false,
    }
    return self.warehouseInventoryFeedState
end

function DC_SupplyWindow:getWarehouseInventoryFilterText()
    return Internal.normalizeFilterText(Internal.getSearchText(self.workerSearch))
end

function DC_SupplyWindow:invalidateWarehouseInventoryFeed()
    local state = self:ensureWarehouseInventoryFeedState()
    state.rows = {}
    state.version = nil
    state.filterText = self:getWarehouseInventoryFilterText()
    state.nextCursor = 0
    state.hasMore = false
    state.totalRows = 0
    state.loading = false
    state.requestPending = false
    state.complete = false
end

function DC_SupplyWindow:hasWarehouseInventoryFeed()
    local state = self:ensureWarehouseInventoryFeedState()
    local warehouse = self.workerData and self.workerData.warehouse or nil
    local expectedVersion = tostring(warehouse and warehouse.inventoryVersion or "")
    return state.complete == true
        and tostring(state.version or "") == expectedVersion
        and state.filterText == self:getWarehouseInventoryFilterText()
end

function DC_SupplyWindow:requestWarehouseInventoryFeedPage(bypassKnownVersion)
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    if not (self.sendColonyCommand and Internal.isWarehouseInventoryTab(self)) then
        return false
    end

    local warehouse = self.workerData and self.workerData.warehouse or nil
    if type(warehouse) ~= "table" then
        return false
    end

    local state = self:ensureWarehouseInventoryFeedState()
    if state.requestPending == true or state.complete == true then
        return false
    end

    local cursor = math.max(0, math.floor(tonumber(state.nextCursor) or 0))
    local filterText = state.filterText or self:getWarehouseInventoryFilterText()
    local knownVersion = nil
    if bypassKnownVersion ~= true and cursor <= 0 and state.complete == true then
        knownVersion = state.version
    end

    if not self:sendColonyCommand("RequestWarehouseInventoryFeed", {
        knownVersion = knownVersion,
        cursor = cursor,
        limit = math.max(1, tonumber(Internal.WAREHOUSE_FEED_PAGE_SIZE) or 24),
        filterText = filterText ~= "" and filterText or nil,
    }) then
        return false
    end

    state.requestPending = true
    state.loading = true
    if Internal.debugPerf then
        Internal.debugPerf("WarehouseFeedRequest", startedAt, 1, {
            token = self.debugOpenToken,
            cursor = cursor,
            knownVersion = knownVersion or "nil",
            filter = filterText ~= "" and filterText or "none",
            pageSize = math.max(1, tonumber(Internal.WAREHOUSE_FEED_PAGE_SIZE) or 24),
        })
    end
    return true
end

function DC_SupplyWindow:startWarehouseInventoryFeed(forceRefresh)
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    local state = self:ensureWarehouseInventoryFeedState()
    local warehouse = self.workerData and self.workerData.warehouse or nil
    local expectedVersion = tostring(warehouse and warehouse.inventoryVersion or "")
    local filterText = self:getWarehouseInventoryFilterText()
    if forceRefresh ~= true
        and state.complete == true
        and tostring(state.version or "") == expectedVersion
        and state.filterText == filterText then
        if Internal.debugLog then
            Internal.debugLog("WarehouseFeed", "reused cached inventory feed", {
                token = self.debugOpenToken,
                version = expectedVersion,
                rows = #(state.rows or {}),
                filter = filterText ~= "" and filterText or "none",
            })
        end
        return
    end

    state.rows = {}
    state.version = nil
    state.filterText = filterText
    state.nextCursor = 0
    state.hasMore = true
    state.totalRows = 0
    state.loading = true
    state.requestPending = false
    state.complete = false

    if Internal.isWarehouseInventoryTab(self) then
        self:refreshWorkerEntries()
        self:updateStatus("Loading warehouse inventory...")
        self:requestWarehouseInventoryFeedPage(forceRefresh == true)
    end
    if Internal.debugPerf then
        Internal.debugPerf("WarehouseFeedStart", startedAt, 1, {
            token = self.debugOpenToken,
            forceRefresh = forceRefresh == true,
            expectedVersion = expectedVersion,
            filter = filterText ~= "" and filterText or "none",
        })
    end
end

function DC_SupplyWindow:processWarehouseInventoryFeed()
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    if not Internal.isWarehouseInventoryTab(self) then
        return false
    end

    local state = self:ensureWarehouseInventoryFeedState()
    if state.requestPending == true or state.complete == true or state.hasMore ~= true then
        return false
    end
    if self.scanning or self.playerHydrationState or self.playerFinalizeState then
        return false
    end
    if self.pendingWorkerListRows or self.pendingPlayerListRows then
        return false
    end
    local requested = self:requestWarehouseInventoryFeedPage(false)
    if Internal.debugPerf then
        Internal.debugPerf("WarehouseFeedProcess", startedAt, 2, {
            token = self.debugOpenToken,
            requested = requested == true,
            nextCursor = state.nextCursor or 0,
            loadedRows = #(state.rows or {}),
            totalRows = state.totalRows or 0,
        })
    end
    return requested
end
