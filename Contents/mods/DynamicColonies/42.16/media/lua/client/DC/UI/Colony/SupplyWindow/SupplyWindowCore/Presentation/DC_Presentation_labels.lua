DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function Internal.getOutputTabLabel(worker, window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return "Storage"
    end

    return "Inventory"
end

function Internal.getActiveWorkerTabLabel(window)
    local activeTab = window and window.activeTab or Internal.Tabs.Provisions
    if activeTab == Internal.Tabs.Equipment then
        return "Equipment"
    end
    if activeTab == Internal.Tabs.Output then
        return Internal.getOutputTabLabel(window and window.workerData, window)
    end
    return "Provisions"
end

function Internal.formatWeightValue(value)
    return string.format("%.2f", math.max(0, tonumber(value) or 0))
end

function Internal.getWorkerHeaderTitle(window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        local warehouseName = Internal.getWarehouseDisplayName and Internal.getWarehouseDisplayName(window) or tostring(window and window.workerName or "Warehouse")
        return warehouseName .. " Warehouse"
    end

    local workerName = tostring(window and window.workerName or "Worker")
    local activeTab = window and window.activeTab or Internal.Tabs.Provisions
    local worker = window and window.workerData or nil
    local config = Internal.Config or {}
    local inventoryState = Internal.getWorkerInventoryWeightState and Internal.getWorkerInventoryWeightState(worker) or nil
    local carryWeight = Internal.formatWeightValue(inventoryState and inventoryState.usedWeight)
    local carryCapacity = Internal.formatWeightValue(inventoryState and inventoryState.maxWeight)

    if activeTab == Internal.Tabs.Output then
        local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
        local haulWeight = Internal.formatWeightValue(worker and worker.haulRawWeight)
        local haulCapacity = Internal.formatWeightValue(worker and worker.maxCarryWeight)

        if normalizedJob ~= ((config.JobTypes or {}).Scavenge) then
            local storedWeight = Internal.formatWeightValue(worker and worker.outputWeight)
            return workerName
                .. " (Stored "
                .. storedWeight
                .. " | Carry "
                .. carryWeight
                .. " / "
                .. carryCapacity
                .. ") Inventory"
        end

        return workerName
            .. " (Carry "
            .. carryWeight
            .. " / "
            .. carryCapacity
            .. " | Haul "
            .. haulWeight
            .. " / "
            .. haulCapacity
            .. ") Inventory"
    end

    return workerName .. " Inventory (Carry " .. carryWeight .. " / " .. carryCapacity .. ")"
end

function Internal.getTabButtonTitle(window, tabID)
    local baseTitle = "Provisions"
    if tabID == Internal.Tabs.Output then
        baseTitle = Internal.getOutputTabLabel(window and window.workerData, window)
    elseif tabID == Internal.Tabs.Equipment then
        baseTitle = "Equipment"
    end

    if tabID == Internal.Tabs.Provisions and Internal.isWarehouseView and Internal.isWarehouseView(window) then
        baseTitle = "Provision"
    end

    local weightValue = 0
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        weightValue = Internal.getWarehouseLedgerWeight(window and window.workerData, tabID)
    else
        weightValue = Internal.getWorkerLedgerWeight and Internal.getWorkerLedgerWeight(window and window.workerData, tabID) or 0
    end

    return baseTitle .. " W" .. Internal.formatWeightValue(weightValue)
end
