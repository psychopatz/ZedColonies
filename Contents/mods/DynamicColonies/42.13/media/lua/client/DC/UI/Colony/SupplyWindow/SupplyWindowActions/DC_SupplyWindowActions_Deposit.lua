DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

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

local function takeEntrySubset(entries, quantity)
    local result = {}
    local limit = math.max(1, math.floor(tonumber(quantity) or 1))
    for index = 1, math.min(limit, #entries) do
        result[#result + 1] = entries[index]
    end
    return result
end

local function getEntryTransferWeight(entry)
    return math.max(0, tonumber(entry and entry.totalWeight) or tonumber(entry and entry.unitWeight) or 0)
end

local function getRemainingTransferCapacity(window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        local warehouse = window and window.workerData and window.workerData.warehouse or nil
        if not warehouse then
            return nil
        end
        local maxWeight = math.max(0, tonumber(warehouse.maxWeight) or 0)
        local usedWeight = math.max(0, tonumber(warehouse.usedWeight) or 0)
        return math.max(0, tonumber(warehouse.remainingWeight) or math.max(0, maxWeight - usedWeight))
    end

    if Internal.getWorkerInventoryWeightState then
        local state = Internal.getWorkerInventoryWeightState(window and window.workerData)
        if state and tonumber(state.maxWeight) then
            return math.max(0, tonumber(state.remainingWeight) or 0)
        end
    end

    return nil
end

local function selectEntriesThatFit(window, entries)
    local remainingCapacity = getRemainingTransferCapacity(window)
    if remainingCapacity == nil then
        return entries or {}, 0
    end

    local fittingEntries = {}
    local blockedCount = 0
    for _, entry in ipairs(entries or {}) do
        local weight = getEntryTransferWeight(entry)
        if weight <= 0 or weight <= (remainingCapacity + 0.0001) then
            fittingEntries[#fittingEntries + 1] = entry
            if weight > 0 then
                remainingCapacity = math.max(0, remainingCapacity - weight)
            end
        else
            blockedCount = blockedCount + 1
        end
    end

    return fittingEntries, blockedCount
end

function DC_SupplyWindow:openGroupedDepositQuantityModal(selectedEntry, concreteEntries)
    local available = #(concreteEntries or {})
    if available <= 1 then
        return false
    end

    local activeTab = self.activeTab or Internal.Tabs.Provisions
    local itemLabel = tostring(selectedEntry and (selectedEntry.displayName or selectedEntry.fullType) or "selected item")
    local actionVerb = activeTab == Internal.Tabs.Equipment and "assign"
        or (activeTab == Internal.Tabs.Output and "store")
        or "deposit"

    DC_ColonyQuantityModal.Open({
        title = "Choose Quantity",
        promptText = "How many " .. itemLabel .. " entries do you want to " .. actionVerb .. "?",
        maxValue = available,
        defaultValue = available,
        onConfirm = function(quantity)
            local pickedEntries = takeEntrySubset(concreteEntries, quantity)
            if activeTab == Internal.Tabs.Equipment then
                self:assignToolEntries(pickedEntries)
            else
                self:depositEntries(pickedEntries)
            end
        end
    })

    return true
end

function DC_SupplyWindow:depositEntries(entries)
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

    local fittingEntries, blockedCount = selectEntriesThatFit(self, selectedEntries)
    if #fittingEntries <= 0 then
        if activeTab == Internal.Tabs.Output then
            self:updateStatus("No selected storage items fit in the remaining capacity.")
        else
            self:updateStatus("No selected provisions fit in the remaining capacity.")
        end
        return
    end

    payload = {}
    for _, entry in ipairs(fittingEntries) do
        payload[#payload + 1] = entry.itemID
    end

    local command = activeTab == Internal.Tabs.Output and getOutputDepositCommand(self) or getSupplyDepositCommand(self)
    if not command or not self:sendColonyCommand(command, {
            workerID = self.workerID,
            itemIDs = payload
        }) then
        self:updateStatus("Unable to send transfer to " .. getDepositTargetLabel(self) .. ".")
        return
    end

    self:applyOptimisticDeposit(fittingEntries)

    if #fittingEntries == 1 then
        local entry = fittingEntries[1]
        if activeTab == Internal.Tabs.Output then
            local statusText = "Storing " .. tostring(entry.displayName or entry.fullType or "selected item") .. " in warehouse storage..."
            if blockedCount > 0 then
                statusText = statusText .. " " .. tostring(blockedCount) .. " did not fit."
            end
            self:updateStatus(statusText)
        else
            local statusText =
                "Depositing " .. tostring(entry.displayName or entry.fullType or "selected item") .. " into " .. getDepositTargetLabel(self) .. "..."
            if blockedCount > 0 then
                statusText = statusText .. " " .. tostring(blockedCount) .. " did not fit."
            end
            self:updateStatus(statusText)
        end
    else
        if activeTab == Internal.Tabs.Output then
            local statusText = "Storing " .. tostring(#fittingEntries) .. " visible items in warehouse storage..."
            if blockedCount > 0 then
                statusText = statusText .. " " .. tostring(blockedCount) .. " did not fit."
            end
            self:updateStatus(statusText)
        else
            local statusText = "Depositing " .. tostring(#fittingEntries) .. " visible supplies into " .. getDepositTargetLabel(self) .. "..."
            if blockedCount > 0 then
                statusText = statusText .. " " .. tostring(blockedCount) .. " did not fit."
            end
            self:updateStatus(statusText)
        end
    end
end

function DC_SupplyWindow:assignToolEntries(entries)
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

    local fittingEntries, blockedCount = selectEntriesThatFit(self, selectedEntries)
    if #fittingEntries <= 0 then
        self:updateStatus("No selected labour tools fit in the remaining capacity.")
        return
    end

    local sentEntries = {}
    for _, entry in ipairs(fittingEntries) do
        if self:sendColonyCommand(getEquipmentDepositCommand(self), {
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
        local statusText =
            "Assigning " .. tostring(sentEntries[1].displayName or sentEntries[1].fullType or "selected tool") .. " to " .. getDepositTargetLabel(self) .. "..."
        if blockedCount > 0 then
            statusText = statusText .. " " .. tostring(blockedCount) .. " did not fit."
        end
        self:updateStatus(statusText)
    else
        local statusText = "Assigning " .. tostring(#sentEntries) .. " tools to " .. getDepositTargetLabel(self) .. "..."
        if blockedCount > 0 then
            statusText = statusText .. " " .. tostring(blockedCount) .. " did not fit."
        end
        self:updateStatus(statusText)
    end
end

function DC_SupplyWindow:onDepositSelected()
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

    local concreteEntries = Internal.getConcreteTransferEntries(selectedEntry)
    if Internal.isGroupEntry and Internal.isGroupEntry(selectedEntry) and #concreteEntries > 1 then
        self:openGroupedDepositQuantityModal(selectedEntry, concreteEntries)
        return
    end

    if activeTab == Internal.Tabs.Equipment then
        if not selectedEntry.canAssignTool then
            self:updateStatus("Select a valid labour tool first.")
            return
        end
        self:assignToolEntries(concreteEntries)
        return
    end

    if activeTab == Internal.Tabs.Output then
        if not (Internal.canStoreInWarehouseOutput and Internal.canStoreInWarehouseOutput(selectedEntry)) then
            self:updateStatus("That item cannot be stored in warehouse storage.")
            return
        end
        self:depositEntries(concreteEntries)
        return
    end

    if not selectedEntry.canDeposit then
        self:updateStatus(
            tostring(selectedEntry.provisionBlockedReason or "That item is visible for preview, but it cannot be stored as provisions.")
        )
        return
    end

    self:depositEntries(concreteEntries)
end

function DC_SupplyWindow:onDepositVisible()
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
    for _, entry in ipairs(self.playerVisibleEntries or {}) do
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
