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
    local stateText = Internal.getItemStateText and Internal.getItemStateText(entry)
        or (Internal.getEquipmentDurabilityText and Internal.getEquipmentDurabilityText(entry))
        or ""
    if tostring(stateText or "") == "" then
        return text
    end

    return text .. " <RGB:0.82,0.82,0.82> State: <RGB:1,1,1> " .. tostring(stateText) .. " <LINE> "
end

local function isAmmoEquipmentEntry(entry)
    if type(entry) ~= "table" then
        return false
    end

    if tostring(entry.assignedRequirementKey or "") == "Colony.Combat.Ammo" then
        return true
    end

    local config = Internal.Config or {}
    for _, itemTag in ipairs(entry.tags or {}) do
        local itemKey = tostring(itemTag or "")
        if itemKey == "Weapon.Ranged.Ammo"
            or (config.TagMatches and config.TagMatches(itemKey, "Weapon.Ranged.Ammo")) then
            return true
        end
    end

    return false
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
        local isWarehouseOutputTab = Internal.isWarehouseView and Internal.isWarehouseView(self) and self.activeTab == Internal.Tabs.Output
        local rightPaneDescription = tostring(self.workerName or "the worker") .. " is " .. workerStorageLabel .. workerTabLabel
        if self.activeTab == Internal.Tabs.Output and not transferAllowed then
            workerStorageLabel = "currently carrying in "
            rightPaneDescription = tostring(self.workerName or "the worker") .. " is " .. workerStorageLabel .. workerTabLabel
        elseif Internal.isWarehouseView and Internal.isWarehouseView(self) then
            rightPaneDescription = "the colony warehouse currently holds " .. string.lower(tostring(workerTabLabel or "storage"))
        end
        local transferGuidance = ""
        local warehouseFeedLoading = isWarehouseOutputTab
            and self.warehouseInventoryFeedState
            and self.warehouseInventoryFeedState.loading == true
        if isWarehouseOutputTab then
            transferGuidance =
                "<LINE> <RGB:0.62,0.62,0.62> This warehouse Inventory tab shows compressed literal item stock by full type, plus any read-only colony reserve rows that came from older or system-generated abstract stock. "
                .. "<LINE> <RGB:0.62,0.62,0.62> Use "
                .. "<RGB:1,1,1> > <RGB:0.62,0.62,0.62> on the left side to deposit pristine, full-state items only. Matching items are merged into one row with a quantity count for performance. "
                .. "<LINE> <RGB:0.62,0.62,0.62> Provisions and Equipment keep their richer tracked state in their own tabs. Inventory rows on the right side are read-only and feed colony material systems. "
                .. (warehouseFeedLoading and "<LINE> <RGB:0.85,0.72,0.38> Warehouse inventory is still loading rows in the background. " or "")
        elseif transferAllowed then
            transferGuidance =
                "<LINE> <RGB:0.62,0.62,0.62> Use "
                .. "<RGB:1,1,1> < <RGB:0.62,0.62,0.62> for the selected worker item and "
                .. "<RGB:1,1,1> > <RGB:0.62,0.62,0.62> for the selected player item. "
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
            " <RGB:0.78,0.78,0.78> Left side shows your inventory cache, right side shows "
                .. rightPaneDescription
                .. ". "
                .. transferGuidance
                .. ((isWarehouseOutputTab)
                        and "<LINE> <RGB:0.62,0.62,0.62> Warehouse weight shows total used capacity across Provisions, Inventory, Equipment, and any hidden legacy reserve, not just the currently visible rows. "
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
            text = text .. " <RGB:0.82,0.82,0.82> Debug: <RGB:1,1,1> Click a support icon below, then choose [debug] Get Item. <LINE> "
            setDetailSupportPanel(self, supportDisplay.title, supportDisplay.entries)
        else
            setDetailSupportPanel(self, "", {})
            if entry.kind == "category" then
                text = text .. " <RGB:0.82,0.82,0.82> Category ID: <RGB:1,1,1> " .. tostring(entry.category or "Unknown") .. " <LINE> "
                text = text .. " <RGB:0.82,0.82,0.82> Group: <RGB:1,1,1> " .. tostring(entry.group or "Waste") .. " <LINE> "
            else
                text = text .. " <RGB:0.82,0.82,0.82> Full Type: <RGB:1,1,1> " .. tostring(entry.fullType or "Unknown") .. " <LINE> "
            end
        end
        if entry.kind == "money" then
            text = text .. " <RGB:0.82,0.82,0.82> Stored Dollars: <RGB:1,1,1> $" .. tostring(math.max(0, math.floor(tonumber(entry.amount) or 0))) .. " <LINE> "
            text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Use < to withdraw a chosen amount. <LINE> "
        elseif Internal.isGroupEntry and Internal.isGroupEntry(entry) then
            -- Group details were already rendered above.
        elseif self.activeTab == Internal.Tabs.Equipment then
            if (tonumber(entry.qty) or 1) > 1 then
                text = text .. " <RGB:0.82,0.82,0.82> Quantity: <RGB:1,1,1> " .. tostring(entry.qty or 1) .. " <LINE> "
            end
            text = appendWeightLine(text, entry)
            if not isAmmoEquipmentEntry(entry) then
                text = appendConditionLine(text, entry)
            end
            if Internal.isInventoryView and Internal.isInventoryView(self) then
                text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Click this row to replace the active matching equipment. <LINE> "
            end
        elseif self.activeTab == Internal.Tabs.Output then
            text = text .. " <RGB:0.82,0.82,0.82> Quantity: <RGB:1,1,1> " .. tostring(entry.qty or 1) .. " <LINE> "
            text = appendWeightLine(text, entry)
            if entry.kind == "category" then
                text = text .. " <RGB:0.82,0.82,0.82> Type: <RGB:1,1,1> Colony reserve category <LINE> "
                text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Read only. This row represents legacy or system-generated abstract reserve that does not map to one literal item stack. <LINE> "
            elseif entry.kind == "special" then
                text = text .. " <RGB:0.82,0.82,0.82> Type: <RGB:1,1,1> Literal special stock <LINE> "
                if tostring(entry.specialStockType or "") ~= "" then
                    text = text .. " <RGB:0.82,0.82,0.82> Purpose: <RGB:1,1,1> " .. tostring(entry.specialStockType) .. " <LINE> "
                end
                text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Read only. These items stay literal for systems like research specimens. <LINE> "
            else
                text = text .. " <RGB:0.82,0.82,0.82> Type: <RGB:1,1,1> Literal warehouse item stock <LINE> "
                local config = Internal.Config or {}
                local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(self.workerData and self.workerData.jobType) or tostring(self.workerData and self.workerData.jobType or "")
                if normalizedJob == ((config.JobTypes or {}).Scavenge)
                    and Internal.isInventoryView
                    and Internal.isInventoryView(self) then
                    text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Use Drop to discard this hauled item and free carry weight. <LINE> "
                else
                    text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Read only. Matching pristine deposits merge into this stack automatically. <LINE> "
                end
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
            if (tonumber(entry.qty) or 1) > 1 then
                text = text .. " <RGB:0.82,0.82,0.82> Quantity: <RGB:1,1,1> " .. tostring(entry.qty or 1) .. " <LINE> "
            end
            text = appendWeightLine(text, entry)
            if not isAmmoEquipmentEntry(entry) then
                text = appendConditionLine(text, entry)
            end
        elseif self.activeTab == Internal.Tabs.Output and Internal.isWarehouseView and Internal.isWarehouseView(self) then
            text = appendWeightLine(text, entry)
            text = text .. " <RGB:0.82,0.82,0.82> Action: <RGB:1,1,1> Use Store to add this pristine item into the warehouse inventory as a compressed literal stack for colony use. <LINE> "
        else
            text = appendWeightLine(text, entry)
            text = text .. " <RGB:0.82,0.82,0.82> Adds Calories: <RGB:1,1,1> " .. string.format("%.0f", entry.calories or 0) .. " <LINE> "
            text = text .. " <RGB:0.82,0.82,0.82> Adds Hydration: <RGB:1,1,1> " .. string.format("%.0f", entry.hydration or 0) .. " <LINE> "
        end
    end

    self.detailText:setText(text)
    self.detailText:paginate()
end
