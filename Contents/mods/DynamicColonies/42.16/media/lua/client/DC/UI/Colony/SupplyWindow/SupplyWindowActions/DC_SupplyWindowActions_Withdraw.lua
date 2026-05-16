DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getWithdrawCommand(window, activeTab)
    local isWarehouseView = Internal.isWarehouseView and Internal.isWarehouseView(window)
    if activeTab == Internal.Tabs.Equipment then
        return isWarehouseView and "WithdrawWarehouseTools" or "WithdrawWorkerTools"
    end
    if activeTab == Internal.Tabs.Output then
        return isWarehouseView and "WithdrawWarehouseOutput" or "WithdrawWorkerOutput"
    end
    return isWarehouseView and "WithdrawWarehouseSupplies" or "WithdrawWorkerSupplies"
end

local function getWithdrawSourceLabel(window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return "warehouse"
    end
    return tostring(window and (window.workerName or window.workerID) or "worker")
end

local function isWithdrawableWarehouseInventoryEntry(entry)
    return entry
        and entry.kind == "inventory"
        and tostring(entry.fullType or "") ~= ""
        and math.max(0, tonumber(entry.qty) or 0) > 0
end

local function copyEntry(entry)
    local copied = {}
    for key, value in pairs(entry or {}) do
        copied[key] = value
    end
    return copied
end

function DC_SupplyWindow:openWithdrawQuantityModal(selectedEntry)
    local available = math.max(1, math.floor(tonumber(selectedEntry and selectedEntry.qty) or 1))
    if available <= 1 then
        return false
    end

    local itemLabel = tostring(selectedEntry and (selectedEntry.displayName or selectedEntry.fullType) or "selected item")
    DC_ColonyQuantityModal.Open({
        title = "Choose Quantity",
        promptText = "How many " .. itemLabel .. " entries do you want to withdraw?",
        maxValue = available,
        defaultValue = 1,
        onConfirm = function(quantity)
            local requestEntry = copyEntry(selectedEntry)
            requestEntry.requestedQty = math.max(1, math.floor(tonumber(quantity) or 1))
            self:withdrawWorkerEntries({ requestEntry })
        end
    })

    return true
end

function DC_SupplyWindow:withdrawWorkerEntries(entries)
    if not self.workerID then
        self:updateStatus("No worker selected.")
        return
    end
    if not self:canTransferWithWorker(true) then
        return
    end

    local activeTab = self.activeTab or Internal.Tabs.Provisions
    if Internal.isWarehouseView and Internal.isWarehouseView(self) and activeTab == Internal.Tabs.Output then
        local inventoryRequests = {}
        local selectedEntries = {}
        for _, entry in ipairs(entries or {}) do
            if isWithdrawableWarehouseInventoryEntry(entry) then
                local requestQty = math.max(1, math.floor(tonumber(entry.requestedQty) or tonumber(entry.qty) or 1))
                inventoryRequests[#inventoryRequests + 1] = {
                    kind = "inventory",
                    fullType = entry.fullType,
                    qty = requestQty,
                }
                selectedEntries[#selectedEntries + 1] = {
                    displayName = entry.displayName,
                    fullType = entry.fullType,
                    qty = requestQty,
                }
            end
        end

        if #selectedEntries <= 0 then
            self:updateStatus("No literal warehouse items are available for transfer.")
            return
        end

        local command = getWithdrawCommand(self, activeTab)
        if not self:sendColonyCommand(command, {
                workerID = self.workerID,
                inventoryRequests = inventoryRequests,
            }) then
            self:updateStatus("Unable to collect items from " .. getWithdrawSourceLabel(self) .. ".")
            return
        end

        if #selectedEntries == 1 then
            local selectedEntry = selectedEntries[1]
            local qtyText = math.max(1, tonumber(selectedEntry.qty) or 1)
            if qtyText > 1 then
                self:updateStatus(
                    "Taking " .. tostring(qtyText) .. " " .. tostring(selectedEntry.displayName or selectedEntry.fullType or "item")
                        .. " from "
                        .. getWithdrawSourceLabel(self)
                        .. "..."
                )
            else
                self:updateStatus(
                    "Taking " .. tostring(selectedEntry.displayName or selectedEntry.fullType or "item") .. " from "
                        .. getWithdrawSourceLabel(self)
                        .. "..."
                )
            end
        else
            self:updateStatus("Taking " .. tostring(#selectedEntries) .. " warehouse inventory rows from " .. getWithdrawSourceLabel(self) .. "...")
        end
        return
    end

    local selectedEntries = {}
    local seenIndexes = {}
    local quantityByIndex = {}
    for _, entry in ipairs(entries or {}) do
        local ledgerIndex = math.floor(tonumber(entry and entry.ledgerIndex) or 0)
        if ledgerIndex > 0 and not seenIndexes[ledgerIndex] then
            seenIndexes[ledgerIndex] = true
            selectedEntries[#selectedEntries + 1] = entry
            quantityByIndex[ledgerIndex] = math.max(1, math.floor(tonumber(entry and entry.requestedQty) or tonumber(entry and entry.qty) or 1))
        end
    end

    if #selectedEntries <= 0 then
        local activeTab = self.activeTab or Internal.Tabs.Provisions
        if activeTab == Internal.Tabs.Output then
            local config = Internal.Config or {}
            local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(self.workerData and self.workerData.jobType) or tostring(self.workerData and self.workerData.jobType or "")
            if normalizedJob == ((config.JobTypes or {}).Scavenge) and (tonumber(self.workerData and self.workerData.haulCount) or 0) > 0 then
                self:updateStatus("This worker is still carrying haul. Wait for them to get home first.")
                return
            end
        end
        self:updateStatus("No worker items are available for transfer.")
        return
    end

    local command = getWithdrawCommand(self, activeTab)

    local payload = {}
    local ledgerRequests = {}
    for _, entry in ipairs(selectedEntries) do
        payload[#payload + 1] = entry.ledgerIndex
        ledgerRequests[#ledgerRequests + 1] = {
            ledgerIndex = entry.ledgerIndex,
            qty = quantityByIndex[entry.ledgerIndex] or 1,
        }
    end

    if not self:sendColonyCommand(command, {
            workerID = self.workerID,
            ledgerIndexes = payload,
            ledgerRequests = ledgerRequests,
            requestedQty = #selectedEntries == 1 and quantityByIndex[selectedEntries[1].ledgerIndex] or nil,
        }) then
        self:updateStatus("Unable to collect items from " .. getWithdrawSourceLabel(self) .. ".")
        return
    end

    if #selectedEntries == 1 then
        self:updateStatus(
            "Taking " .. tostring(selectedEntries[1].displayName or selectedEntries[1].fullType or "item") .. " from " .. getWithdrawSourceLabel(self) .. "..."
        )
    else
        self:updateStatus("Taking " .. tostring(#selectedEntries) .. " entries from " .. getWithdrawSourceLabel(self) .. "...")
    end
end

function DC_SupplyWindow:onWithdrawSelected()
    local selectedEntry = self.selectedWorkerEntry
    if not selectedEntry then
        self:updateStatus("Select an item on the worker side first.")
        return
    end
    if Internal.isWarehouseView and Internal.isWarehouseView(self) and (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Output then
        if not isWithdrawableWarehouseInventoryEntry(selectedEntry) then
            if selectedEntry.kind == "category" then
                self:updateStatus("That warehouse reserve row is abstract colony stock and cannot be withdrawn as a literal item.")
            elseif selectedEntry.kind == "special" then
                self:updateStatus("That literal special row is reserved for colony systems and cannot be withdrawn here.")
            else
                self:updateStatus("Only literal warehouse item rows can be withdrawn from this tab.")
            end
            return
        end
    end

    if selectedEntry.kind == "money" then
        self:openWithdrawMoneyModal()
        return
    end

    if selectedEntry.kind == "placeholder" then
        self:updateStatus("That row is a missing equipment placeholder. Assign a matching tool from the left side.")
        return
    end

    if (tonumber(selectedEntry.qty) or 1) > 1 and not (Internal.isGroupEntry and Internal.isGroupEntry(selectedEntry)) then
        if self:openWithdrawQuantityModal(selectedEntry) then
            return
        end
    end

    self:withdrawWorkerEntries(Internal.getConcreteTransferEntries(selectedEntry))
end

function DC_SupplyWindow:onWithdrawVisible()
    local visibleEntries = {}
    for _, entry in ipairs(self.workerVisibleEntries or {}) do
        if entry
            and entry.kind ~= "money"
            and entry.kind ~= "placeholder"
            and (not (Internal.isWarehouseView and Internal.isWarehouseView(self) and (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Output)
                or isWithdrawableWarehouseInventoryEntry(entry)) then
            visibleEntries[#visibleEntries + 1] = entry
        end
    end

    if #visibleEntries <= 0 then
        if Internal.isWarehouseView and Internal.isWarehouseView(self) then
            if (self.activeTab or Internal.Tabs.Provisions) == Internal.Tabs.Output then
                self:updateStatus("No visible literal warehouse inventory rows matched the current filter.")
            else
                self:updateStatus("No visible warehouse items matched the current filter.")
            end
        else
            self:updateStatus("No visible NPC inventory items matched the current filter. Select the cash entry to transfer money.")
        end
        return
    end

    self:withdrawWorkerEntries(visibleEntries)
end
