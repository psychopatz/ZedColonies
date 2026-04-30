DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function DC_SupplyWindow:openDepositMoneyModal()
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
    DC_ColonyQuantityModal.Open({
        title = "Deposit Cash",
        promptText = "How much money do you want to give to " .. workerName .. "?",
        maxValue = wealth,
        defaultValue = wealth,
        onConfirm = function(quantity)
            self:sendColonyCommand("GiveWorkerMoney", {
                workerID = self.workerID,
                amount = quantity
            })
            if self.refreshPlayerMoneyCache then
                self:refreshPlayerMoneyCache(true)
            end
            if self.refreshWorkerEntries then
                self:refreshWorkerEntries()
            end
            self:updateStatus("Depositing $" .. tostring(quantity) .. " to " .. workerName .. "...")
        end
    })
end

function DC_SupplyWindow:openWithdrawMoneyModal()
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
    DC_ColonyQuantityModal.Open({
        title = "Withdraw Cash",
        promptText = "How much money do you want to take from " .. workerName .. "?",
        maxValue = stored,
        defaultValue = stored,
        onConfirm = function(quantity)
            self:sendColonyCommand("WithdrawWorkerMoney", {
                workerID = self.workerID,
                amount = quantity
            })
            if self.refreshPlayerMoneyCache then
                self:refreshPlayerMoneyCache(true)
            end
            if self.refreshWorkerEntries then
                self:refreshWorkerEntries()
            end
            self:updateStatus("Withdrawing $" .. tostring(quantity) .. " from " .. workerName .. "...")
        end
    })
end
