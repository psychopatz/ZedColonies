DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

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

function DT_SupplyWindow:withdrawWorkerEntries(entries)
    if not self.workerID then
        self:updateStatus("No worker selected.")
        return
    end
    if not self:canTransferWithWorker(true) then
        return
    end

    local selectedEntries = {}
    local seenIndexes = {}
    for _, entry in ipairs(entries or {}) do
        local ledgerIndex = math.floor(tonumber(entry and entry.ledgerIndex) or 0)
        if ledgerIndex > 0 and not seenIndexes[ledgerIndex] then
            seenIndexes[ledgerIndex] = true
            selectedEntries[#selectedEntries + 1] = entry
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

    local activeTab = self.activeTab or Internal.Tabs.Provisions
    local command = getWithdrawCommand(self, activeTab)

    local payload = {}
    for _, entry in ipairs(selectedEntries) do
        payload[#payload + 1] = entry.ledgerIndex
    end

    if not self:sendLabourCommand(command, {
            workerID = self.workerID,
            ledgerIndexes = payload
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

function DT_SupplyWindow:onWithdrawSelected()
    local selectedEntry = self.selectedWorkerEntry
    if not selectedEntry then
        self:updateStatus("Select an item on the worker side first.")
        return
    end

    if selectedEntry.kind == "money" then
        self:openWithdrawMoneyModal()
        return
    end

    if selectedEntry.kind == "placeholder" then
        self:updateStatus("That row is a missing equipment placeholder. Assign a matching tool from the left side.")
        return
    end

    self:withdrawWorkerEntries({ selectedEntry })
end

function DT_SupplyWindow:onWithdrawVisible()
    local visibleEntries = {}
    for _, row in ipairs(self.workerList and self.workerList.items or {}) do
        local entry = row and row.item or nil
        if entry and entry.kind ~= "money" and entry.kind ~= "placeholder" then
            visibleEntries[#visibleEntries + 1] = entry
        end
    end

    if #visibleEntries <= 0 then
        if Internal.isWarehouseView and Internal.isWarehouseView(self) then
            self:updateStatus("No visible warehouse items matched the current filter.")
        else
            self:updateStatus("No visible NPC inventory items matched the current filter. Select the cash entry to transfer money.")
        end
        return
    end

    self:withdrawWorkerEntries(visibleEntries)
end
