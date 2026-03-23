DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

function DT_SupplyWindow:openDepositMoneyModal()
    if not self.workerID then
        self:updateStatus("No worker selected.")
        return
    end
    if Internal.isWarehouseView and Internal.isWarehouseView(self) then
        self:updateStatus("Warehouse cash transfers are not available in this view.")
        return
    end
    if not self:canTransferWithWorker(true) then
        return
    end

    local wealth = Internal.getPlayerWealth and Internal.getPlayerWealth(Internal.getLocalPlayer and Internal.getLocalPlayer() or nil) or 0
    if wealth <= 0 then
        self:updateStatus("You do not have any money to deposit.")
        return
    end

    local workerName = tostring(self.workerName or self.workerID or "this worker")
    DT_LabourQuantityModal.Open({
        title = "Deposit Cash",
        promptText = "How much money do you want to give to " .. workerName .. "?",
        maxValue = wealth,
        defaultValue = wealth,
        onConfirm = function(quantity)
            self:sendLabourCommand("GiveWorkerMoney", {
                workerID = self.workerID,
                amount = quantity
            })
            self:updateStatus("Depositing $" .. tostring(quantity) .. " to " .. workerName .. "...")
        end
    })
end

function DT_SupplyWindow:openWithdrawMoneyModal()
    if not self.workerID then
        self:updateStatus("No worker selected.")
        return
    end
    if Internal.isWarehouseView and Internal.isWarehouseView(self) then
        self:updateStatus("Warehouse cash transfers are not available in this view.")
        return
    end
    if not self:canTransferWithWorker(true) then
        return
    end

    local stored = math.max(0, math.floor(tonumber(self.workerData and self.workerData.moneyStored) or 0))
    if stored <= 0 then
        self:updateStatus(tostring(self.workerName or self.workerID or "This worker") .. " does not have any stored cash.")
        return
    end

    local workerName = tostring(self.workerName or self.workerID or "this worker")
    DT_LabourQuantityModal.Open({
        title = "Withdraw Cash",
        promptText = "How much money do you want to take from " .. workerName .. "?",
        maxValue = stored,
        defaultValue = stored,
        onConfirm = function(quantity)
            self:sendLabourCommand("WithdrawWorkerMoney", {
                workerID = self.workerID,
                amount = quantity
            })
            self:updateStatus("Withdrawing $" .. tostring(quantity) .. " from " .. workerName .. "...")
        end
    })
end
