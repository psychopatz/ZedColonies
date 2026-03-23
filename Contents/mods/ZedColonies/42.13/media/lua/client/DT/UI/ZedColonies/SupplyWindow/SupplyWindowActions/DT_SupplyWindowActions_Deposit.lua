DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

local function getSupplyDepositCommand(window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return "DepositWarehouseSupplies"
    end
    return "DepositWorkerSupplies"
end

local function getOutputDepositCommand(window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return "DepositWarehouseOutput"
    end
    return nil
end

local function getEquipmentDepositCommand(window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return "AssignWarehouseToolset"
    end
    return "AssignWorkerToolset"
end

local function getDepositTargetLabel(window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return "warehouse"
    end
    return "NPC inventory"
end

function DT_SupplyWindow:depositEntries(entries)
    if not self.workerID then
        self:updateStatus("No worker selected.")
        return
    end
    if not self:canTransferWithWorker(true) then
        return
    end

    local activeTab = self.activeTab or Internal.Tabs.Provisions
    local payload = {}
    local selectedEntries = {}
    local seenIDs = {}

    for _, entry in ipairs(entries or {}) do
        local itemID = entry and entry.itemID or nil
        if itemID and not seenIDs[itemID] and self.playerEntriesByID[itemID] then
            seenIDs[itemID] = true
            local validForTab = false
            if activeTab == Internal.Tabs.Output then
                validForTab = Internal.canStoreInWarehouseOutput and Internal.canStoreInWarehouseOutput(entry)
            else
                validForTab = entry.canDeposit
            end
            if validForTab then
                payload[#payload + 1] = itemID
                selectedEntries[#selectedEntries + 1] = entry
            end
        end
    end

    if #selectedEntries <= 0 then
        if activeTab == Internal.Tabs.Output then
            self:updateStatus("No valid warehouse storage items selected.")
        else
            self:updateStatus("No valid provisions selected.")
        end
        return
    end

    local command = activeTab == Internal.Tabs.Output and getOutputDepositCommand(self) or getSupplyDepositCommand(self)
    if not command or not self:sendLabourCommand(command, {
            workerID = self.workerID,
            itemIDs = payload
        }) then
        self:updateStatus("Unable to send transfer to " .. getDepositTargetLabel(self) .. ".")
        return
    end

    self:applyOptimisticDeposit(selectedEntries)

    if #selectedEntries == 1 then
        local entry = selectedEntries[1]
        if activeTab == Internal.Tabs.Output then
            self:updateStatus("Storing " .. tostring(entry.displayName or entry.fullType or "selected item") .. " in warehouse storage...")
        else
            self:updateStatus(
                "Depositing " .. tostring(entry.displayName or entry.fullType or "selected item") .. " into " .. getDepositTargetLabel(self) .. "..."
            )
        end
    else
        if activeTab == Internal.Tabs.Output then
            self:updateStatus("Storing " .. tostring(#selectedEntries) .. " visible items in warehouse storage...")
        else
            self:updateStatus("Depositing " .. tostring(#selectedEntries) .. " visible supplies into " .. getDepositTargetLabel(self) .. "...")
        end
    end
end

function DT_SupplyWindow:assignToolEntries(entries)
    if not self.workerID then
        self:updateStatus("No worker selected.")
        return
    end
    if not self:canTransferWithWorker(true) then
        return
    end

    local selectedEntries = {}
    local seenIDs = {}

    for _, entry in ipairs(entries or {}) do
        local itemID = entry and entry.itemID or nil
        if itemID and not seenIDs[itemID] and self.playerEntriesByID[itemID] and entry.canAssignTool then
            seenIDs[itemID] = true
            selectedEntries[#selectedEntries + 1] = entry
        end
    end

    if #selectedEntries <= 0 then
        self:updateStatus("No valid labour tools selected.")
        return
    end

    local sentEntries = {}
    for _, entry in ipairs(selectedEntries) do
        if self:sendLabourCommand(getEquipmentDepositCommand(self), {
                workerID = self.workerID,
                itemID = entry.itemID
            }) then
            sentEntries[#sentEntries + 1] = entry
        end
    end

    if #sentEntries <= 0 then
        self:updateStatus("Unable to send equipment assignment to " .. getDepositTargetLabel(self) .. ".")
        return
    end

    self:applyOptimisticToolAssign(sentEntries)

    if #sentEntries == 1 then
        self:updateStatus(
            "Assigning " .. tostring(sentEntries[1].displayName or sentEntries[1].fullType or "selected tool") .. " to " .. getDepositTargetLabel(self) .. "..."
        )
    else
        self:updateStatus("Assigning " .. tostring(#sentEntries) .. " tools to " .. getDepositTargetLabel(self) .. "...")
    end
end

function DT_SupplyWindow:onDepositSelected()
    local selectedEntry = self.selectedPlayerEntry
    local activeTab = self.activeTab or Internal.Tabs.Provisions

    if activeTab == Internal.Tabs.Output and not (Internal.isWarehouseView and Internal.isWarehouseView(self)) then
        self:updateStatus("This tab is warehouse storage only. Open the Warehouse view to store general items.")
        return
    end

    if not selectedEntry then
        if self.scanning then
            self:updateStatus("Inventory scan still in progress.")
            return
        end
        self:updateStatus("Select an item on the player side first.")
        return
    end

    if selectedEntry.kind == "money" then
        self:openDepositMoneyModal()
        return
    end

    if activeTab == Internal.Tabs.Equipment then
        if not selectedEntry.canAssignTool then
            self:updateStatus("Select a valid labour tool first.")
            return
        end
        self:assignToolEntries({ selectedEntry })
        return
    end

    if activeTab == Internal.Tabs.Output then
        if not (Internal.canStoreInWarehouseOutput and Internal.canStoreInWarehouseOutput(selectedEntry)) then
            self:updateStatus("That item cannot be stored in warehouse storage.")
            return
        end
        self:depositEntries({ selectedEntry })
        return
    end

    if not selectedEntry.canDeposit then
        self:updateStatus("That item is visible for preview, but it cannot be stored as provisions.")
        return
    end

    self:depositEntries({ selectedEntry })
end

function DT_SupplyWindow:onDepositVisible()
    local activeTab = self.activeTab or Internal.Tabs.Provisions

    if activeTab == Internal.Tabs.Output and not (Internal.isWarehouseView and Internal.isWarehouseView(self)) then
        self:updateStatus("This tab is warehouse storage only. Open the Warehouse view to store general items.")
        return
    end

    if self.scanning then
        self:updateStatus("Wait for the inventory scan to finish before bulk depositing filtered supplies.")
        return
    end

    local visibleEntries = {}
    for _, row in ipairs(self.playerList and self.playerList.items or {}) do
        local entry = row and row.item or nil
        if entry
            and entry.kind ~= "money"
            and ((activeTab == Internal.Tabs.Equipment and entry.canAssignTool)
                or (activeTab == Internal.Tabs.Output and Internal.canStoreInWarehouseOutput and Internal.canStoreInWarehouseOutput(entry))
                or (activeTab ~= Internal.Tabs.Equipment and activeTab ~= Internal.Tabs.Output and entry.canDeposit)) then
            visibleEntries[#visibleEntries + 1] = entry
        end
    end

    if #visibleEntries <= 0 then
        if activeTab == Internal.Tabs.Equipment then
            self:updateStatus("No visible labour tools matched the current filter.")
        elseif activeTab == Internal.Tabs.Output then
            self:updateStatus("No visible warehouse storage items matched the current filter.")
        elseif activeTab == Internal.Tabs.Provisions then
            self:updateStatus("No visible provisions matched the current filter. Select the cash entry to transfer money.")
        else
            self:updateStatus("No visible provisions matched the current filter.")
        end
        return
    end

    if activeTab == Internal.Tabs.Equipment then
        self:assignToolEntries(visibleEntries)
    else
        self:depositEntries(visibleEntries)
    end
end
