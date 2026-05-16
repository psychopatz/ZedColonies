DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getPlayerTabKey(window, tabID)
    local targetTab = tabID or (window and window.activeTab) or Internal.Tabs.Provisions
    if targetTab == Internal.Tabs.Equipment then
        return Internal.Tabs.Equipment
    end
    if targetTab == Internal.Tabs.Output
        and Internal.isWarehouseView
        and Internal.isWarehouseView(window) then
        return Internal.Tabs.Output
    end
    return Internal.Tabs.Provisions
end

local function getProvisionAggregateKey(entry)
    return table.concat({
        tostring(entry and entry.displayName or ""),
        tostring(entry and entry.fullType or ""),
        tostring(entry and entry.provisionType or ""),
        entry and entry.canDeposit == true and "1" or "0",
    }, "|")
end

local function addProvisionEntryToHeader(header, entry, invItem)
    header.totalWeight = header.totalWeight + math.max(0, tonumber(entry.totalWeight) or tonumber(entry.unitWeight) or 0)
    header.totalCalories = header.totalCalories + math.max(0, tonumber(entry.calories) or 0)
    header.totalHydration = header.totalHydration + math.max(0, tonumber(entry.hydration) or 0)
    header.totalTreatmentUnits = header.totalTreatmentUnits + math.max(0, tonumber(entry.treatmentUnits) or 0)
    header.totalQty = header.totalQty + math.max(1, tonumber(entry.qty) or 1)
    header.childCount = header.childCount + 1
    header.calories = header.totalCalories
    header.hydration = header.totalHydration
    header.treatmentUnits = header.totalTreatmentUnits
    header.qty = header.totalQty
    header.canDeposit = header.canDeposit or entry.canDeposit == true
    header.isRottenProvision = header.isRottenProvision or entry.isRottenProvision == true
    if tostring(header.provisionBlockedReason or "") == "" and tostring(entry.provisionBlockedReason or "") ~= "" then
        header.provisionBlockedReason = entry.provisionBlockedReason
    end
    header.sourceItems[#header.sourceItems + 1] = invItem
    if invItem and invItem.getID and type(header.sourceEntriesByID) == "table" then
        header.sourceEntriesByID[invItem:getID()] = entry
    end
    header.childEntries = nil
end

local function removeProvisionEntryFromHeader(header, entry)
    header.totalWeight = math.max(0, header.totalWeight - math.max(0, tonumber(entry.totalWeight) or tonumber(entry.unitWeight) or 0))
    header.totalCalories = math.max(0, header.totalCalories - math.max(0, tonumber(entry.calories) or 0))
    header.totalHydration = math.max(0, header.totalHydration - math.max(0, tonumber(entry.hydration) or 0))
    header.totalTreatmentUnits = math.max(0, header.totalTreatmentUnits - math.max(0, tonumber(entry.treatmentUnits) or 0))
    header.totalQty = math.max(0, header.totalQty - math.max(1, tonumber(entry.qty) or 1))
    header.childCount = math.max(0, header.childCount - 1)
    header.calories = header.totalCalories
    header.hydration = header.totalHydration
    header.treatmentUnits = header.totalTreatmentUnits
    header.qty = header.totalQty
end

local function getOutputAggregateKey(entry)
    return table.concat({
        tostring(entry and entry.displayName or ""),
        tostring(entry and entry.fullType or ""),
    }, "|")
end

local function addOutputEntryToHeader(header, entry, invItem)
    header.totalWeight = header.totalWeight + math.max(0, tonumber(entry.totalWeight) or tonumber(entry.unitWeight) or 0)
    header.totalQty = header.totalQty + math.max(1, tonumber(entry.qty) or 1)
    header.qty = header.totalQty
    header.pending = header.pending or entry.pending == true
    header.transferPending = header.transferPending or entry.transferPending == true
    header.sourceItems[#header.sourceItems + 1] = invItem
    if invItem and invItem.getID and type(header.sourceEntriesByID) == "table" then
        header.sourceEntriesByID[invItem:getID()] = entry
    end
    header.childEntries = nil
end

local function removeOutputEntryFromHeader(header, entry)
    header.totalWeight = math.max(0, header.totalWeight - math.max(0, tonumber(entry.totalWeight) or tonumber(entry.unitWeight) or 0))
    header.totalQty = math.max(0, header.totalQty - math.max(1, tonumber(entry.qty) or 1))
    header.qty = header.totalQty
end

function DC_SupplyWindow:bumpPresentationCacheVersion()
    self.presentationCacheVersion = math.max(0, math.floor(tonumber(self.presentationCacheVersion) or 0)) + 1
    self.cachedRightHeaderTitle = nil
    self.cachedRightSummary = nil
end

function DC_SupplyWindow:refreshRenderCaches()
    self.cachedRightHeaderTitle = Internal.getWorkerHeaderTitle and Internal.getWorkerHeaderTitle(self) or nil
    self.cachedRightSummary = (Internal.getActiveWorkerTabLabel and Internal.getActiveWorkerTabLabel(self) or "Provisions")
        .. " | "
        .. (Internal.getWorkerTabSummary and Internal.getWorkerTabSummary(self, self.workerEntries) or "")
end

function DC_SupplyWindow:refreshPlayerMoneyCache(forceRebuild)
    local looseCount = 0
    local bundleCount = 0
    if Internal.getPlayerMoneyBreakdown then
        looseCount, bundleCount = Internal.getPlayerMoneyBreakdown(Internal.getLocalPlayer and Internal.getLocalPlayer() or nil)
    end
    local normalizedLoose = math.max(0, tonumber(looseCount) or 0)
    local normalizedBundles = math.max(0, tonumber(bundleCount) or 0)
    local changed = normalizedLoose ~= math.max(0, tonumber(self.cachedLooseMoneyCount) or 0)
        or normalizedBundles ~= math.max(0, tonumber(self.cachedMoneyBundleCount) or 0)

    self.cachedLooseMoneyCount = normalizedLoose
    self.cachedMoneyBundleCount = normalizedBundles

    local shouldRefreshUI = (changed or forceRebuild == true)
    if shouldRefreshUI
        and (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Provisions
        and Internal.isInventoryView
        and Internal.isInventoryView(self)
        and not self.scanning
        and not self.playerHydrationState
        and not self.playerFinalizeState
        and not self.pendingPlayerListRows
        and not self.rebuildingPlayerList then
        self:rebuildPlayerList()
        self.playerMoneyDirty = nil
    elseif shouldRefreshUI then
        self.playerMoneyDirty = true
    end

    return changed
end

function DC_SupplyWindow:bindPlayerEntrySet(tabKey)
    tabKey = getPlayerTabKey(self, tabKey)
    self.playerEntrySets = self.playerEntrySets or {}
    self.playerEntryMaps = self.playerEntryMaps or {}
    self.playerEntrySets[tabKey] = self.playerEntrySets[tabKey] or {}
    self.playerEntryMaps[tabKey] = self.playerEntryMaps[tabKey] or {}
    self.playerEntries = self.playerEntrySets[tabKey]
    self.playerEntriesByID = self.playerEntryMaps[tabKey]
    self.activePlayerTabKey = tabKey
end

function DC_SupplyWindow:createProvisionAggregateHeader(entry, invItem)
    local groupKey = getProvisionAggregateKey(entry)
    local sourceEntriesByID = {}
    if invItem and invItem.getID then
        sourceEntriesByID[invItem:getID()] = entry
    end
    local header = {
        kind = "group",
        side = "player",
        groupKey = groupKey,
        displayName = entry.displayName,
        fullType = entry.fullType,
        provisionType = entry.provisionType,
        texture = nil,
        childEntries = nil,
        childEntriesLoader = function(groupEntry)
            local children = {}
            for _, sourceItem in ipairs(groupEntry.sourceItems or {}) do
                local sourceDescriptor = groupEntry.sourceEntriesByID
                    and sourceItem
                    and sourceItem.getID
                    and groupEntry.sourceEntriesByID[sourceItem:getID()]
                    or nil
                local childEntry = Internal.buildProvisionEntryFromDescriptor
                    and Internal.buildProvisionEntryFromDescriptor(sourceItem, sourceDescriptor)
                    or nil
                if childEntry then
                    children[#children + 1] = childEntry
                end
            end
            return children
        end,
        sourceItems = { invItem },
        sourceEntriesByID = sourceEntriesByID,
        childCount = 1,
        totalWeight = math.max(0, tonumber(entry.totalWeight) or tonumber(entry.unitWeight) or 0),
        totalCalories = math.max(0, tonumber(entry.calories) or 0),
        totalHydration = math.max(0, tonumber(entry.hydration) or 0),
        totalTreatmentUnits = math.max(0, tonumber(entry.treatmentUnits) or 0),
        totalQty = math.max(1, tonumber(entry.qty) or 1),
        calories = math.max(0, tonumber(entry.calories) or 0),
        hydration = math.max(0, tonumber(entry.hydration) or 0),
        treatmentUnits = math.max(0, tonumber(entry.treatmentUnits) or 0),
        qty = math.max(1, tonumber(entry.qty) or 1),
        amount = 0,
        canDeposit = entry.canDeposit == true,
        canAssignTool = false,
        provisionBlockedReason = entry.provisionBlockedReason,
        isRottenProvision = entry.isRottenProvision == true,
        hasEquipmentRequirementMatch = false,
        isUsableEquipment = false,
        pending = false,
        tags = {},
        transferPending = false,
    }
    return header
end

function DC_SupplyWindow:addProvisionAggregatedEntry(entry, invItem)
    self.playerProvisionGroups = self.playerProvisionGroups or {}
    local itemID = invItem and invItem.getID and invItem:getID() or nil
    if itemID ~= nil then
        self.playerEntriesByID[itemID] = entry or true
    end
    local groupKey = getProvisionAggregateKey(entry)
    local header = self.playerProvisionGroups[groupKey]
    if not header then
        header = self:createProvisionAggregateHeader(entry, invItem)
        self.playerProvisionGroups[groupKey] = header
        self.playerEntries[#self.playerEntries + 1] = header
        return true
    end

    addProvisionEntryToHeader(header, entry, invItem)
    return true
end

function DC_SupplyWindow:createOutputAggregateHeader(entry, invItem)
    local groupKey = getOutputAggregateKey(entry)
    local sourceEntriesByID = {}
    if invItem and invItem.getID then
        sourceEntriesByID[invItem:getID()] = entry
    end
    local header = {
        kind = "group",
        side = "player",
        groupKey = groupKey,
        displayName = entry.displayName,
        fullType = entry.fullType,
        texture = entry.texture,
        childEntries = nil,
        childEntriesLoader = function(groupEntry)
            local children = {}
            for _, sourceItem in ipairs(groupEntry.sourceItems or {}) do
                local childEntry = Internal.buildInventoryEntryForTab
                    and Internal.buildInventoryEntryForTab(sourceItem, Internal.Tabs.Output, self)
                    or nil
                if childEntry and Internal.canStoreInWarehouseOutput and Internal.canStoreInWarehouseOutput(childEntry) then
                    children[#children + 1] = childEntry
                end
            end
            return children
        end,
        sourceItems = { invItem },
        sourceEntriesByID = sourceEntriesByID,
        childCount = 1,
        totalWeight = math.max(0, tonumber(entry.totalWeight) or tonumber(entry.unitWeight) or 0),
        totalCalories = 0,
        totalHydration = 0,
        totalTreatmentUnits = 0,
        totalQty = math.max(1, tonumber(entry.qty) or 1),
        calories = 0,
        hydration = 0,
        treatmentUnits = 0,
        qty = math.max(1, tonumber(entry.qty) or 1),
        amount = 0,
        canDeposit = false,
        canAssignTool = false,
        provisionBlockedReason = entry.provisionBlockedReason,
        isRottenProvision = entry.isRottenProvision == true,
        hasEquipmentRequirementMatch = false,
        isUsableEquipment = false,
        pending = entry.pending == true,
        tags = entry.tags or {},
        condition = entry.condition,
        conditionMax = entry.conditionMax,
        isDrainable = entry.isDrainable == true,
        useDelta = entry.useDelta,
        usedDelta = entry.usedDelta,
        fluidAmount = entry.fluidAmount,
        fluidCapacity = entry.fluidCapacity,
        keepOnDeplete = entry.keepOnDeplete == true,
        transferPending = entry.transferPending == true,
    }
    return header
end

function DC_SupplyWindow:addOutputAggregatedEntry(entry, invItem)
    self.playerOutputGroups = self.playerOutputGroups or {}
    local itemID = invItem and invItem.getID and invItem:getID() or nil
    if itemID ~= nil then
        self.playerEntriesByID[itemID] = entry or true
    end
    local groupKey = getOutputAggregateKey(entry)
    local header = self.playerOutputGroups[groupKey]
    if not header then
        header = self:createOutputAggregateHeader(entry, invItem)
        self.playerOutputGroups[groupKey] = header
        self.playerEntries[#self.playerEntries + 1] = header
        return true
    end

    header.childCount = header.childCount + 1
    addOutputEntryToHeader(header, entry, invItem)
    return true
end

function DC_SupplyWindow:clearPlayerListUI()
    self.pendingPlayerListRows = nil
    self.pendingPlayerListNextIndex = nil
    self.pendingPlayerListSelectedKey = nil
    self.pendingPlayerListSelectedRowIndex = nil
    if self.playerList then
        self.playerList:clear()
        self.playerList.selected = -1
        self.playerList:setScrollHeight(0)
        self.playerList:setYScroll(0)
    end
end

function DC_SupplyWindow:beginPlayerEntryFinalize(tabKey, statusText)
    tabKey = getPlayerTabKey(self, tabKey)
    local sourceEntries = self.playerEntrySets and self.playerEntrySets[tabKey] or {}
    self.playerFinalizeState = {
        tabKey = tabKey,
        sourceEntries = sourceEntries,
        sortedEntries = {},
        visibleEntries = {},
        nextIndex = 1,
        phase = "sort",
        statusText = statusText,
    }
    self.playerDataReady = self.playerDataReady or {}
    self.playerDataReady[tabKey] = false
    if self.activePlayerTabKey == tabKey then
        self:clearPlayerListUI()
    end
end

local function binaryInsert(entries, entry)
    local low = 1
    local high = #entries
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if Internal.compareEntries(entry, entries[mid]) then
            high = mid - 1
        else
            low = mid + 1
        end
    end
    table.insert(entries, low, entry)
end

function DC_SupplyWindow:processPlayerEntryFinalize(batchSize)
    local state = self.playerFinalizeState
    if not state then
        return false
    end

    local limit = math.max(1, tonumber(batchSize) or Internal.LIST_BUILD_BATCH_SIZE or 1)
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    if state.phase == "sort" then
        local processed = 0
        while state.nextIndex <= #state.sourceEntries and processed < limit do
            binaryInsert(state.sortedEntries, state.sourceEntries[state.nextIndex])
            state.nextIndex = state.nextIndex + 1
            processed = processed + 1
            if Internal.isTimeBudgetExceeded
                and Internal.isTimeBudgetExceeded(startedAt, Internal.FINALIZE_TIME_BUDGET_MS) then
                break
            end
        end

        if state.nextIndex > #state.sourceEntries then
            self.playerEntrySets[state.tabKey] = state.sortedEntries
            if self.activePlayerTabKey == state.tabKey then
                self.playerEntries = state.sortedEntries
            end
            state.phase = "filter"
            state.nextIndex = 1
        end
        return true
    end

    if state.phase == "filter" then
        local processed = 0
        local filterText = Internal.getSearchText(self.playerSearch)
        while state.nextIndex <= #state.sortedEntries and processed < limit do
            local entry = state.sortedEntries[state.nextIndex]
            if Internal.shouldShowPlayerEntry(entry, state.tabKey, self)
                and Internal.matchesFilter(entry, filterText) then
                state.visibleEntries[#state.visibleEntries + 1] = entry
            end
            state.nextIndex = state.nextIndex + 1
            processed = processed + 1
            if Internal.isTimeBudgetExceeded
                and Internal.isTimeBudgetExceeded(startedAt, Internal.FINALIZE_TIME_BUDGET_MS) then
                break
            end
        end

        if state.nextIndex > #state.sortedEntries then
            if self.activePlayerTabKey == state.tabKey then
                local selectedKey = Internal.getEntrySelectionKey(self.selectedPlayerEntry)
                self.playerVisibleEntries = state.visibleEntries
                self:beginChunkedListBuild(
                    "player",
                    Internal.buildGroupedRows(state.visibleEntries, state.tabKey, "player", self),
                    selectedKey
                )
            end
            self.playerDataReady[state.tabKey] = true
            self.playerFinalizeState = nil
            self:bumpPresentationCacheVersion()
            if self.refreshRenderCaches then
                self:refreshRenderCaches()
            end
            if state.statusText and state.tabKey == self.activePlayerTabKey then
                self:updateStatus(state.statusText)
            end
            return false
        end

        return true
    end

    self.playerFinalizeState = nil
    return false
end

function DC_SupplyWindow:beginPlayerTabHydration(tabKey)
    tabKey = getPlayerTabKey(self, tabKey)
    self.playerEntrySets = self.playerEntrySets or {}
    self.playerEntryMaps = self.playerEntryMaps or {}
    self.playerDataReady = self.playerDataReady or {}
    self.playerEntrySets[tabKey] = {}
    self.playerEntryMaps[tabKey] = {}
    self:bindPlayerEntrySet(tabKey)
    self.playerVisibleEntries = {}
    self.selectedPlayerEntry = nil
    self.playerHydrationState = {
        tabKey = tabKey,
        nextIndex = 1,
    }
    self.playerFinalizeState = nil
    self.playerDataReady[tabKey] = false
    if tabKey == Internal.Tabs.Provisions then
        self.playerProvisionGroups = {}
    elseif tabKey == Internal.Tabs.Output then
        self.playerOutputGroups = {}
    end
    self:clearPlayerListUI()

    if tabKey == Internal.Tabs.Equipment then
        self:updateStatus("Preparing equipment candidates from player inventory...")
    elseif tabKey == Internal.Tabs.Output then
        self:updateStatus("Preparing warehouse storage candidates from player inventory...")
    else
        self:updateStatus("Preparing provision candidates from player inventory...")
    end
end

function DC_SupplyWindow:processPlayerTabHydration(batchSize)
    local state = self.playerHydrationState
    if not state then
        return false
    end

    local items = self.scannedInventoryItems or {}
    local limit = math.max(1, tonumber(batchSize) or Internal.ENTRY_SCAN_BATCH_SIZE or 1)
    local added = 0
    local inspected = 0
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    while state.nextIndex <= #items
        and added < limit
        and inspected < (Internal.RAW_SCAN_STEP_LIMIT or 240) do
        local invItem = items[state.nextIndex]
        local entry = nil
        if state.tabKey == Internal.Tabs.Provisions then
            local descriptor = invItem and Internal.buildProvisionDescriptor and Internal.buildProvisionDescriptor(invItem) or nil
            if descriptor and (descriptor.canDeposit == true or tostring(descriptor.provisionBlockedReason or "") ~= "") then
                entry = descriptor
            end
        elseif state.tabKey == Internal.Tabs.Output then
            entry = invItem and Internal.buildInventoryEntryForTab and Internal.buildInventoryEntryForTab(invItem, state.tabKey, self) or nil
        else
            entry = invItem and Internal.buildInventoryEntryForTab and Internal.buildInventoryEntryForTab(invItem, state.tabKey, self) or nil
        end
        if entry then
            if state.tabKey == Internal.Tabs.Provisions then
                self:addProvisionAggregatedEntry(entry, invItem)
            elseif state.tabKey == Internal.Tabs.Output then
                self:addOutputAggregatedEntry(entry, invItem)
            else
                self.playerEntries[#self.playerEntries + 1] = entry
                self.playerEntriesByID[entry.itemID] = entry
            end
            added = added + 1
        end
        state.nextIndex = state.nextIndex + 1
        inspected = inspected + 1
        if Internal.isTimeBudgetExceeded
            and Internal.isTimeBudgetExceeded(startedAt, Internal.HYDRATION_TIME_BUDGET_MS) then
            break
        end
    end

    if state.nextIndex > #items then
        local builtCount = #(self.playerEntries or {})
        local statusText = "Loaded " .. tostring(builtCount) .. " visible entries from " .. tostring(#items) .. " inventory items."
        self.playerHydrationState = nil
        self:beginPlayerEntryFinalize(state.tabKey, statusText)
        return false
    end

    return true
end

function DC_SupplyWindow:preparePlayerEntriesForActiveTab()
    local tabKey = getPlayerTabKey(self)
    self:bindPlayerEntrySet(tabKey)

    if self.scanning then
        self:startInventoryScan()
        return
    end

    if self.playerDataReady and self.playerDataReady[tabKey] == true then
        self:rebuildPlayerList()
        return
    end

    if self.scannedInventoryItems and #self.scannedInventoryItems > 0 then
        self:beginPlayerTabHydration(tabKey)
        return
    end

    self:startInventoryScan()
end

function DC_SupplyWindow:registerVisiblePlayerEntry(entry)
    return entry ~= nil
end

function DC_SupplyWindow:addScannedItem(invItem)
    if not invItem then
        return false
    end

    local fullType = invItem.getFullType and invItem:getFullType() or nil
    if fullType == "Base.Money" or fullType == "Base.MoneyBundle" then
        if fullType == "Base.MoneyBundle" then
            self.cachedMoneyBundleCount = math.max(0, tonumber(self.cachedMoneyBundleCount) or 0) + 1
        else
            self.cachedLooseMoneyCount = math.max(0, tonumber(self.cachedLooseMoneyCount) or 0) + 1
        end
        return false
    end

    self.scannedInventoryItems[#self.scannedInventoryItems + 1] = invItem

    local tabKey = getPlayerTabKey(self, self.scanTargetTabKey)
    local entry = nil
    if tabKey == Internal.Tabs.Provisions then
        local descriptor = Internal.buildProvisionDescriptor and Internal.buildProvisionDescriptor(invItem) or nil
        if descriptor and (descriptor.canDeposit == true or tostring(descriptor.provisionBlockedReason or "") ~= "") then
            entry = descriptor
        end
    else
        entry = Internal.buildInventoryEntryForTab and Internal.buildInventoryEntryForTab(invItem, tabKey, self) or nil
    end
    if not entry then
        return false
    end

    if tabKey == Internal.Tabs.Provisions then
        return self:addProvisionAggregatedEntry(entry, invItem)
    end
    if tabKey == Internal.Tabs.Output then
        return self:addOutputAggregatedEntry(entry, invItem)
    end

    self.playerEntries[#self.playerEntries + 1] = entry
    self.playerEntriesByID[entry.itemID] = entry
    self:registerVisiblePlayerEntry(entry)
    return true
end

function DC_SupplyWindow:rebuildPlayerList()
    if not self.playerList then
        return
    end
    if self.playerHydrationState and self.playerHydrationState.tabKey == self.activePlayerTabKey then
        return
    end
    if self.playerFinalizeState and self.playerFinalizeState.tabKey == self.activePlayerTabKey then
        return
    end

    self.rebuildingPlayerList = true
    self:bumpPresentationCacheVersion()

    if (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Provisions
        and Internal.isInventoryView
        and Internal.isInventoryView(self) then
        self:refreshPlayerMoneyCache(false)
    end

    local selectedKey = Internal.getEntrySelectionKey(self.selectedPlayerEntry)
    local filterText = Internal.getSearchText(self.playerSearch)
    local visibleEntries = {}
    if (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Provisions
        and Internal.isInventoryView
        and Internal.isInventoryView(self) then
        local moneyEntry = Internal.buildPlayerMoneyEntry(Internal.getLocalPlayer and Internal.getLocalPlayer() or nil, self)
        if Internal.shouldShowPlayerEntry(moneyEntry, self.activeTab or Internal.Tabs.Provisions, self)
            and Internal.matchesFilter(moneyEntry, filterText) then
            visibleEntries[#visibleEntries + 1] = moneyEntry
        end
    end

    for _, entry in ipairs(self.playerEntries or {}) do
        if Internal.shouldShowPlayerEntry(entry, self.activeTab or Internal.Tabs.Provisions, self)
            and Internal.matchesFilter(entry, filterText) then
            visibleEntries[#visibleEntries + 1] = entry
        end
    end

    self.playerVisibleEntries = visibleEntries
    self:beginChunkedListBuild(
        "player",
        Internal.buildGroupedRows(visibleEntries, self.activeTab or Internal.Tabs.Provisions, "player", self),
        selectedKey
    )
    self.rebuildingPlayerList = false
end

function DC_SupplyWindow:removePlayerEntryByID(itemID)
    if not itemID then
        return nil
    end

    local removedEntry = nil

    for tabKey, entryMap in pairs(self.playerEntryMaps or {}) do
        if type(entryMap) == "table" then
            entryMap[itemID] = nil
        end
        local entrySet = self.playerEntrySets and self.playerEntrySets[tabKey] or nil
        if type(entrySet) == "table" then
            for index = #entrySet, 1, -1 do
                local entry = entrySet[index]
                if entry and entry.itemID == itemID then
                    removedEntry = removedEntry or entry
                    table.remove(entrySet, index)
                end
            end
        end
    end

    local provisionSet = self.playerEntrySets and self.playerEntrySets[Internal.Tabs.Provisions] or nil
    if type(provisionSet) == "table" then
        for index = #provisionSet, 1, -1 do
            local header = provisionSet[index]
            if header and header.kind == "group" and type(header.sourceItems) == "table" then
                for sourceIndex = #header.sourceItems, 1, -1 do
                    local sourceItem = header.sourceItems[sourceIndex]
                    if sourceItem and sourceItem.getID and sourceItem:getID() == itemID then
                        local sourceEntry = header.sourceEntriesByID and header.sourceEntriesByID[itemID] or nil
                        if sourceEntry then
                            removeProvisionEntryFromHeader(header, sourceEntry)
                        else
                            header.childCount = math.max(0, header.childCount - 1)
                        end
                        if type(header.sourceEntriesByID) == "table" then
                            header.sourceEntriesByID[itemID] = nil
                        end
                        table.remove(header.sourceItems, sourceIndex)
                        if type(header.childEntries) == "table" then
                            for childIndex = #header.childEntries, 1, -1 do
                                local child = header.childEntries[childIndex]
                                if child and child.itemID == itemID then
                                    table.remove(header.childEntries, childIndex)
                                    break
                                end
                            end
                        end
                        if header.childCount <= 0 or #(header.sourceItems or {}) <= 0 then
                            if self.playerProvisionGroups then
                                self.playerProvisionGroups[header.groupKey] = nil
                            end
                            table.remove(provisionSet, index)
                        end
                        break
                    end
                end
            end
        end
    end

    local outputSet = self.playerEntrySets and self.playerEntrySets[Internal.Tabs.Output] or nil
    if type(outputSet) == "table" then
        for index = #outputSet, 1, -1 do
            local header = outputSet[index]
            if header and header.kind == "group" and type(header.sourceItems) == "table" then
                for sourceIndex = #header.sourceItems, 1, -1 do
                    local sourceItem = header.sourceItems[sourceIndex]
                    if sourceItem and sourceItem.getID and sourceItem:getID() == itemID then
                        local sourceEntry = header.sourceEntriesByID and header.sourceEntriesByID[itemID] or nil
                        if sourceEntry then
                            removeOutputEntryFromHeader(header, sourceEntry)
                        else
                            header.childCount = math.max(0, header.childCount - 1)
                        end
                        if type(header.sourceEntriesByID) == "table" then
                            header.sourceEntriesByID[itemID] = nil
                        end
                        table.remove(header.sourceItems, sourceIndex)
                        if type(header.childEntries) == "table" then
                            for childIndex = #header.childEntries, 1, -1 do
                                local child = header.childEntries[childIndex]
                                if child and child.itemID == itemID then
                                    table.remove(header.childEntries, childIndex)
                                    break
                                end
                            end
                        end
                        header.childCount = math.max(0, #(header.sourceItems or {}))
                        if header.childCount <= 0 then
                            if self.playerOutputGroups then
                                self.playerOutputGroups[header.groupKey] = nil
                            end
                            table.remove(outputSet, index)
                        end
                        break
                    end
                end
            end
        end
    end

    for index = #(self.scannedInventoryItems or {}), 1, -1 do
        local invItem = self.scannedInventoryItems[index]
        if invItem and invItem.getID and invItem:getID() == itemID then
            table.remove(self.scannedInventoryItems, index)
        end
    end

    return removedEntry
end
