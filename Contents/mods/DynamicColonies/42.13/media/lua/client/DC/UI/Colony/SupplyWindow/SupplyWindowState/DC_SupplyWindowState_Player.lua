DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function DC_SupplyWindow:registerVisiblePlayerEntry(entry)
    return entry ~= nil
end

function DC_SupplyWindow:addScannedItem(invItem)
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

function DC_SupplyWindow:rebuildPlayerList()
    if not self.playerList then
        return
    end

    local selectedKey = Internal.getEntrySelectionKey(self.selectedPlayerEntry)
    local filterText = Internal.getSearchText(self.playerSearch)
    local visibleEntries = {}
    if (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Provisions
        and Internal.isInventoryView
        and Internal.isInventoryView(self) then
        local moneyEntry = Internal.buildPlayerMoneyEntry(Internal.getLocalPlayer and Internal.getLocalPlayer() or nil)
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
end

function DC_SupplyWindow:removePlayerEntryByID(itemID)
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
