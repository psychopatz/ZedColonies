DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function appendWeightLine(text, entry)
    local weight = math.max(0, tonumber(entry and entry.totalWeight) or tonumber(entry and entry.unitWeight) or 0)
    if weight <= 0 then
        return text
    end
    return text .. " <RGB:0.82,0.82,0.82> Weight: <RGB:1,1,1> " .. Internal.formatWeightValue(weight) .. " <LINE> "
end

local function appendConditionLine(text, entry)
    local durabilityText = Internal.getEquipmentDurabilityText and Internal.getEquipmentDurabilityText(entry) or ""
    if tostring(durabilityText or "") == "" then
        return text
    end

    return text .. " <RGB:0.82,0.82,0.82> Condition: <RGB:1,1,1> " .. tostring(durabilityText) .. " <LINE> "
end

local function setDetailSupportPanel(window, title, entries)
    if not window or not window.detailSupportPanel then
        return
    end

    window.detailSupportPanel.title = tostring(title or "")
    window.detailSupportPanel.entries = entries or {}
    window.detailSupportPanel:setVisible(window.detailSupportPanel.title ~= "" or #(window.detailSupportPanel.entries or {}) > 0)
end

function DC_SupplyWindow:updateItemDetail(entry, side)
    if not self.detailText then
        return
    end

    if not entry then
        setDetailSupportPanel(self, "", {})
        local workerTabLabel = Internal.getActiveWorkerTabLabel(self)
        local workerStorageLabel = "stored in "
        local transferAllowed = Internal.canTransferWithWorker(self.workerData)
        if self.activeTab == Internal.Tabs.Output and not transferAllowed then
            workerStorageLabel = "currently carrying in "
        end
        local transferGuidance = ""
        if transferAllowed then
            transferGuidance =
                "<LINE> <RGB:0.62,0.62,0.62> Use "
                .. "<RGB:1,1,1> < <RGB:0.62,0.62,0.62> for one selected worker item or "
                .. "<RGB:1,1,1> << <RGB:0.62,0.62,0.62> to pull every visible filtered worker item back to your inventory. "
                .. "<LINE> <RGB:0.62,0.62,0.62> Use "
                .. "<RGB:1,1,1> > <RGB:0.62,0.62,0.62> for one selected item or "
                .. "<RGB:1,1,1> >> <RGB:0.62,0.62,0.62> to send every visible filtered item when the active tab supports transfers. "
                .. "<LINE> <RGB:0.62,0.62,0.62> Select the "
                .. "<RGB:1,1,1> cash <RGB:0.62,0.62,0.62> entry on Provisions and use "
                .. "<RGB:1,1,1> > <RGB:0.62,0.62,0.62> or "
                .. "<RGB:1,1,1> < <RGB:0.62,0.62,0.62> to open the money transfer modal. "
            local config = Internal.Config or {}
            local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(self.workerData and self.workerData.jobType) or tostring(self.workerData and self.workerData.jobType or "")
            if self.activeTab == Internal.Tabs.Output
                and normalizedJob == ((config.JobTypes or {}).Scavenge)
                and Internal.isInventoryView
                and Internal.isInventoryView(self) then
                transferGuidance = transferGuidance
                    .. "<LINE> <RGB:0.62,0.62,0.62> Use "
                    .. "<RGB:1,1,1> Drop <RGB:0.62,0.62,0.62> to throw away the selected hauled item and free carry weight. "
            end
        else
            transferGuidance =
                "<LINE> <RGB:0.85,0.72,0.38> "
                .. Internal.getTransferBlockedReason(self.workerData)
                .. " "
                .. "<LINE> <RGB:0.62,0.62,0.62> This window is read-only while they are away, so you can inspect the haul but not move items. "
            local config = Internal.Config or {}
            local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(self.workerData and self.workerData.jobType) or tostring(self.workerData and self.workerData.jobType or "")
            if self.activeTab == Internal.Tabs.Output
                and normalizedJob == ((config.JobTypes or {}).Scavenge)
                and Internal.isInventoryView
                and Internal.isInventoryView(self) then
                transferGuidance = transferGuidance
                    .. "<LINE> <RGB:0.62,0.62,0.62> You can still use "
                    .. "<RGB:1,1,1> Drop <RGB:0.62,0.62,0.62> to discard selected haul and reduce their carried weight. "
            end
        end
        self.detailText:setText(
            " <RGB:0.78,0.78,0.78> Left side shows your inventory cache, right side shows what "
                .. tostring(self.workerName or "the worker")
                .. " is "
                .. workerStorageLabel
                .. workerTabLabel
                .. ". "
                .. transferGuidance
                .. ((Internal.isWarehouseView and Internal.isWarehouseView(self) and self.activeTab == Internal.Tabs.Output)
                        and "<LINE> <RGB:0.62,0.62,0.62> Warehouse weight shows total used capacity across Provisions, Storage, and Equipment, not just the currently visible storage rows. "
                    or "")
                .. (((self.activeTab == Internal.Tabs.Equipment) and Internal.isInventoryView and Internal.isInventoryView(self))
                        and "<LINE> <RGB:0.62,0.62,0.62> Use <RGB:1,1,1> Auto Equip <RGB:0.62,0.62,0.62> to fill missing gear from warehouse storage, and <RGB:1,1,1> Auto On/Off <RGB:0.62,0.62,0.62> to control automatic warehouse equipping while the worker is home. "
                    or "")
                .. "<LINE> <RGB:0.62,0.62,0.62> Active worker tab: <RGB:1,1,1> "
                .. workerTabLabel
                .. " <RGB:0.62,0.62,0.62> | "
                .. Internal.getWorkerTabSummary(self, self.workerEntries)
        )
        self.detailText:paginate()
        return
    end

    local text = ""
    if side == "worker" then
        text = text .. " <RGB:1,1,1> <SIZE:Large> " .. Internal.getActiveWorkerTabLabel(self) .. " <LINE> <LINE> "
        text = text .. " <RGB:0.82,0.82,0.82> Item: <RGB:1,1,1> " .. tostring(Internal.formatEntryLabel(entry)) .. " <LINE> "
        if Internal.isGroupEntry and Internal.isGroupEntry(entry) then
            setDetailSupportPanel(self, "", {})
            text = text .. " <RGB:0.82,0.82,0.82> Group Size: <RGB:1,1,1> " .. tostring(entry.childCount or 0) .. " entries <LINE> "
            if self.activeTab == Internal.Tabs.Output then
                text = appendWeightLine(text, entry)
                text = text .. " <RGB:0.82,0.82,0.82> Total Quantity: <RGB:1,1,1> " .. tostring(entry.totalQty or entry.qty or 0) .. " <LINE> "
            elseif self.activeTab == Internal.Tabs.Equipment then
                text = appendWeightLine(text, entry)
                text = appendConditionLine(text, entry)
            else
                text = appendWeightLine(text, entry)
                text = text .. " <RGB:0.82,0.82,0.82> Total Calories: <RGB:1,1,1> " .. string.format("%.0f", entry.calories or 0) .. " <LINE> "
                text = text .. " <RGB:0.82,0.82,0.82> Total Hydration: <RGB:1,1,1> " .. string.format("%.0f", entry.hydration or 0) .. " <LINE> "
                if (tonumber(entry.treatmentUnits) or 0) > 0 then
                    text = text .. " <RGB:0.82,0.82,0.82> Treatment Units: <RGB:1,1,1> " .. tostring(math.floor((tonumber(entry.treatmentUnits) or 0) + 0.5)) .. " <LINE> "
                end
            end
            text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Use < to collect the whole group, or click the left arrow to expand it for individual transfers. <LINE> "
        elseif entry.kind == "placeholder" then
            local maxCount = self.detailSupportPanel and self.detailSupportPanel.getCapacity and self.detailSupportPanel:getCapacity() or 20
            local supportDisplay = Internal.getPlaceholderSupportDisplay(self, entry, maxCount)
            text = text .. " <RGB:0.82,0.82,0.82> Needed For: <RGB:1,1,1> " .. tostring(entry.reasonText or "This tool unlocks additional work options for the worker.") .. " <LINE> "
            text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Click this row to open the equipment picker. <LINE> "
            setDetailSupportPanel(self, supportDisplay.title, supportDisplay.entries)
        else
            setDetailSupportPanel(self, "", {})
            text = text .. " <RGB:0.82,0.82,0.82> Full Type: <RGB:1,1,1> " .. tostring(entry.fullType or "Unknown") .. " <LINE> "
        end
        if entry.kind == "money" then
            text = text .. " <RGB:0.82,0.82,0.82> Stored Dollars: <RGB:1,1,1> $" .. tostring(math.max(0, math.floor(tonumber(entry.amount) or 0))) .. " <LINE> "
            text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Use < to withdraw a chosen amount. <LINE> "
        elseif Internal.isGroupEntry and Internal.isGroupEntry(entry) then
            -- Group details were already rendered above.
        elseif self.activeTab == Internal.Tabs.Equipment then
            text = appendWeightLine(text, entry)
            text = appendConditionLine(text, entry)
            if Internal.isInventoryView and Internal.isInventoryView(self) then
                text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Click this row to replace the active matching equipment. <LINE> "
            end
        elseif self.activeTab == Internal.Tabs.Output then
            text = text .. " <RGB:0.82,0.82,0.82> Quantity: <RGB:1,1,1> " .. tostring(entry.qty or 1) .. " <LINE> "
            text = appendWeightLine(text, entry)
            local config = Internal.Config or {}
            local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(self.workerData and self.workerData.jobType) or tostring(self.workerData and self.workerData.jobType or "")
            if normalizedJob == ((config.JobTypes or {}).Scavenge)
                and Internal.isInventoryView
                and Internal.isInventoryView(self) then
                text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Use Drop to discard this hauled item and free carry weight. <LINE> "
            end
        else
            if (tonumber(entry.qty) or 1) > 1 then
                text = text .. " <RGB:0.82,0.82,0.82> Quantity: <RGB:1,1,1> " .. tostring(entry.qty or 1) .. " <LINE> "
            end
            text = appendWeightLine(text, entry)
            text = text .. " <RGB:0.82,0.82,0.82> Remaining Calories: <RGB:1,1,1> " .. string.format("%.0f", entry.totalCalories or entry.calories or 0) .. " <LINE> "
            text = text .. " <RGB:0.82,0.82,0.82> Remaining Hydration: <RGB:1,1,1> " .. string.format("%.0f", entry.totalHydration or entry.hydration or 0) .. " <LINE> "
            if (tonumber(entry.totalTreatmentUnits) or 0) > 0 then
                text = text .. " <RGB:0.82,0.82,0.82> Treatment Units: <RGB:1,1,1> " .. tostring(math.floor((tonumber(entry.totalTreatmentUnits) or 0) + 0.5)) .. " <LINE> "
            end
        end
    else
        setDetailSupportPanel(self, "", {})
        text = text .. " <RGB:1,1,1> <SIZE:Large> Player Item <LINE> <LINE> "
        text = text .. " <RGB:0.82,0.82,0.82> Item: <RGB:1,1,1> " .. tostring(Internal.formatEntryLabel(entry)) .. " <LINE> "
        if Internal.isGroupEntry and Internal.isGroupEntry(entry) then
            text = text .. " <RGB:0.82,0.82,0.82> Group Size: <RGB:1,1,1> " .. tostring(entry.childCount or 0) .. " entries <LINE> "
            if self.activeTab == Internal.Tabs.Equipment then
                text = appendWeightLine(text, entry)
                text = appendConditionLine(text, entry)
            elseif self.activeTab == Internal.Tabs.Output and Internal.isWarehouseView and Internal.isWarehouseView(self) then
                text = appendWeightLine(text, entry)
                text = text .. " <RGB:0.82,0.82,0.82> Total Quantity: <RGB:1,1,1> " .. tostring(entry.totalQty or entry.qty or 0) .. " <LINE> "
            else
                text = appendWeightLine(text, entry)
                text = text .. " <RGB:0.82,0.82,0.82> Total Calories: <RGB:1,1,1> " .. string.format("%.0f", entry.calories or 0) .. " <LINE> "
                text = text .. " <RGB:0.82,0.82,0.82> Total Hydration: <RGB:1,1,1> " .. string.format("%.0f", entry.hydration or 0) .. " <LINE> "
                if (tonumber(entry.treatmentUnits) or 0) > 0 then
                    text = text .. " <RGB:0.82,0.82,0.82> Treatment Units: <RGB:1,1,1> " .. tostring(math.floor((tonumber(entry.treatmentUnits) or 0) + 0.5)) .. " <LINE> "
                end
            end
            text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Use > to move the whole visible group, or click the left arrow to expand it for precise transfers. <LINE> "
        else
            text = text .. " <RGB:0.82,0.82,0.82> Full Type: <RGB:1,1,1> " .. tostring(entry.fullType or "Unknown") .. " <LINE> "
        end
        if entry.kind == "money" then
            text = text .. " <RGB:0.82,0.82,0.82> Available Dollars: <RGB:1,1,1> $" .. tostring(math.max(0, math.floor(tonumber(entry.amount) or 0))) .. " <LINE> "
            text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Use > to deposit a chosen amount. <LINE> "
        elseif Internal.isGroupEntry and Internal.isGroupEntry(entry) then
            -- Group details were already rendered above.
        elseif self.activeTab == Internal.Tabs.Equipment then
            text = appendWeightLine(text, entry)
            text = appendConditionLine(text, entry)
        elseif self.activeTab == Internal.Tabs.Output and Internal.isWarehouseView and Internal.isWarehouseView(self) then
            text = appendWeightLine(text, entry)
            text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Use Store to place this item in warehouse storage for construction and general item use. <LINE> "
        else
            text = appendWeightLine(text, entry)
            text = text .. " <RGB:0.82,0.82,0.82> Adds Calories: <RGB:1,1,1> " .. string.format("%.0f", entry.calories or 0) .. " <LINE> "
            text = text .. " <RGB:0.82,0.82,0.82> Adds Hydration: <RGB:1,1,1> " .. string.format("%.0f", entry.hydration or 0) .. " <LINE> "
        end
    end

    self.detailText:setText(text)
    self.detailText:paginate()
end
