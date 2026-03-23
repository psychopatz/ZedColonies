DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

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

function DT_SupplyWindow:canTransferWithWorker(showStatus)
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

function DT_SupplyWindow:updateTransferControls()
    if not self.btnWithdrawSelected or not self.btnWithdrawVisible or not self.btnDepositSelected or not self.btnDepositVisible then
        return
    end

    local activeTab = self.activeTab or Internal.Tabs.Provisions
    local transferAllowed = self:canTransferWithWorker(false)
    local isWarehouseOutputTab = activeTab == Internal.Tabs.Output and Internal.isWarehouseView and Internal.isWarehouseView(self)
    local depositEnabled = transferAllowed and (activeTab ~= Internal.Tabs.Output or isWarehouseOutputTab)
    local hasWorkerEntries = #(self.workerEntries or {}) > 0
    local dropEnabled = canDropHaulEntries(self) and hasWorkerEntries

    self.btnWithdrawSelected:setEnable(transferAllowed and hasWorkerEntries)
    self.btnWithdrawVisible:setEnable(transferAllowed and hasWorkerEntries)
    self.btnDepositSelected:setEnable(depositEnabled)
    self.btnDepositVisible:setEnable(depositEnabled)
    if self.btnDropSelected then
        self.btnDropSelected:setVisible(canDropHaulEntries(self))
        self.btnDropSelected:setEnable(dropEnabled)
    end

    if activeTab == Internal.Tabs.Equipment then
        self.btnDepositSelected:setTitle("Use")
        self.btnDepositVisible:setTitle("All")
    elseif isWarehouseOutputTab then
        self.btnDepositSelected:setTitle("Store")
        self.btnDepositVisible:setTitle("Store All")
    else
        self.btnDepositSelected:setTitle(">")
        self.btnDepositVisible:setTitle(">>")
    end

    self.btnWithdrawSelected:setTitle("<")
    self.btnWithdrawVisible:setTitle("<<")
end
