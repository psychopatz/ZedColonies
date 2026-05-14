DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function canDropHaulEntries(window)
    if not window then
        return false
    end

    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return false
    end

    if (window.activeTab or Internal.Tabs.Provisions) ~= Internal.Tabs.Output then
        return false
    end

    local worker = window.workerData
    local config = Internal.Config or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
    return normalizedJob == ((config.JobTypes or {}).Scavenge)
end

function DC_SupplyWindow:canTransferWithWorker(showStatus)
    if self:hasPendingSupplyTransfers() then
        if showStatus ~= false then
            self:updateStatus("A storage transfer is still being confirmed.")
        end
        return false
    end

    if self.requireCanonicalWorkerDetail == true then
        if not self:ensureCanonicalWorkerDetail(showStatus, false) then
            return false
        end

        if not self:isPlayerInventoryReady() then
            if showStatus ~= false then
                self:updateStatus("Player inventory is still scanning. Please wait a moment.")
            end
            return false
        end
    end

    if Internal.isWarehouseView and Internal.isWarehouseView(self) then
        return true
    end

    local allowed = Internal.canTransferWithWorker(self.workerData)
    if allowed then
        return true
    end

    if showStatus ~= false then
        self:updateStatus(Internal.getTransferBlockedReason(self.workerData))
    end
    return false
end

function DC_SupplyWindow:updateTransferControls()
    if not self.btnWithdrawSelected or not self.btnDepositSelected then
        return
    end

    local activeTab = self.activeTab or Internal.Tabs.Provisions
    local transferAllowed = self:canTransferWithWorker(false)
    local isWarehouseOutputTab = activeTab == Internal.Tabs.Output and Internal.isWarehouseView and Internal.isWarehouseView(self)
    local autoEquipControlsVisible = self.isAutoEquipControlVisible and self:isAutoEquipControlVisible()
    local depositEnabled = transferAllowed and (activeTab ~= Internal.Tabs.Output or isWarehouseOutputTab)
    local hasWorkerEntries = #(self.workerEntries or {}) > 0
    local dropEnabled = canDropHaulEntries(self) and hasWorkerEntries

    self.btnWithdrawSelected:setEnable(transferAllowed and hasWorkerEntries)
    self.btnDepositSelected:setEnable(depositEnabled)
    if self.btnDropSelected then
        self.btnDropSelected:setVisible(canDropHaulEntries(self))
        self.btnDropSelected:setEnable(dropEnabled)
    end
    if self.btnAutoEquipNow then
        self.btnAutoEquipNow:setVisible(autoEquipControlsVisible)
        self.btnAutoEquipNow:setEnable(autoEquipControlsVisible and transferAllowed)
        self.btnAutoEquipNow:setTitle("Auto Equip")
    end
    if self.btnAutoEquipToggle then
        local autoEquipEnabled = self.getWarehouseAutoEquipEnabled and self:getWarehouseAutoEquipEnabled()
        self.btnAutoEquipToggle:setVisible(autoEquipControlsVisible)
        self.btnAutoEquipToggle:setEnable(autoEquipControlsVisible)
        self.btnAutoEquipToggle:setTitle(autoEquipEnabled and "Auto On" or "Auto Off")
    end

    if activeTab == Internal.Tabs.Equipment then
        self.btnDepositSelected:setTitle(">")
    elseif isWarehouseOutputTab then
        self.btnDepositSelected:setTitle(">")
    else
        self.btnDepositSelected:setTitle(">")
    end

    self.btnWithdrawSelected:setTitle("<")
end
