DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

function DT_SupplyWindow:registerVisiblePlayerEntry(entry)
    if not self.playerList or not entry then
        return
    end

    if not Internal.shouldShowPlayerEntry(entry, self.activeTab or Internal.Tabs.Provisions, self) then
        return
    end

    if not Internal.matchesFilter(entry, Internal.getSearchText(self.playerSearch)) then
        return
    end

    self.playerList:addItem(Internal.formatEntryLabel(entry), entry)
    entry.rowIndex = #self.playerList.items

    if not self.selectedPlayerEntry then
        self.playerList.selected = entry.rowIndex
        self.selectedPlayerEntry = entry
        if self.activeSelectionSide ~= "worker" then
            self.activeSelectionSide = "player"
            self:updateItemDetail(entry, "player")
        end
    end
end

function DT_SupplyWindow:addScannedItem(invItem)
    if not invItem then
        return false
    end

    local fullType = invItem.getFullType and invItem:getFullType() or nil
    if fullType == "Base.Money" or fullType == "Base.MoneyBundle" then
        return false
    end

    local entry = Internal.buildInventoryEntry(invItem)
    self.playerEntries[#self.playerEntries + 1] = entry
    self.playerEntriesByID[entry.itemID] = entry
    self:registerVisiblePlayerEntry(entry)
    return true
end

function DT_SupplyWindow:rebuildPlayerList()
    if not self.playerList then
        return
    end

    local selectedID = self.selectedPlayerEntry and self.selectedPlayerEntry.itemID or nil
    local filterText = Internal.getSearchText(self.playerSearch)

    self.playerList:clear()
    self.playerList.selected = -1
    self.selectedPlayerEntry = nil

    local selectedIndex = nil
    if (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Provisions
        and Internal.isInventoryView
        and Internal.isInventoryView(self) then
        local moneyEntry = Internal.buildPlayerMoneyEntry(Internal.getLocalPlayer and Internal.getLocalPlayer() or nil)
        if Internal.shouldShowPlayerEntry(moneyEntry, self.activeTab or Internal.Tabs.Provisions, self)
            and Internal.matchesFilter(moneyEntry, filterText) then
            self.playerList:addItem(Internal.formatEntryLabel(moneyEntry), moneyEntry)
            local rowIndex = #self.playerList.items
            moneyEntry.rowIndex = rowIndex
            if selectedID and moneyEntry.itemID == selectedID then
                selectedIndex = rowIndex
            end
        end
    end

    for _, entry in ipairs(self.playerEntries or {}) do
        if Internal.shouldShowPlayerEntry(entry, self.activeTab or Internal.Tabs.Provisions, self)
            and Internal.matchesFilter(entry, filterText) then
            self.playerList:addItem(Internal.formatEntryLabel(entry), entry)
            local rowIndex = #self.playerList.items
            entry.rowIndex = rowIndex
            if selectedID and entry.itemID == selectedID then
                selectedIndex = rowIndex
            end
        end
    end

    if self.playerList.items and #self.playerList.items > 0 then
        local targetIndex = selectedIndex or 1
        self.playerList.selected = targetIndex
        self.selectedPlayerEntry = self.playerList.items[targetIndex].item
    end

    self:refreshDetailSelection()
end

function DT_SupplyWindow:removePlayerEntryByID(itemID)
    if not itemID then
        return nil
    end

    self.playerEntriesByID[itemID] = nil
    for index = #self.playerEntries, 1, -1 do
        local entry = self.playerEntries[index]
        if entry and entry.itemID == itemID then
            return table.remove(self.playerEntries, index)
        end
    end

    return nil
end
