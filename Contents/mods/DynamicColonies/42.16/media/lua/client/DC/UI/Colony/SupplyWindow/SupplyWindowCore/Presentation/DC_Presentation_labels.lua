DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return fallback or key
end

function Internal.getOutputTabLabel(worker, window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return T("DCCommon_UI_Supply_Inventory", "Inventory")
    end

    return T("DCCommon_UI_Supply_Inventory", "Inventory")
end

function Internal.getActiveWorkerTabLabel(window)
    local activeTab = window and window.activeTab or Internal.Tabs.Provisions
    if activeTab == Internal.Tabs.Equipment then
        return T("DCCommon_UI_Supply_Equipment", "Equipment")
    end
    if activeTab == Internal.Tabs.Output then
        return Internal.getOutputTabLabel(window and window.workerData, window)
    end
    return T("DCCommon_UI_Supply_Provisions", "Provisions")
end

function Internal.formatWeightValue(value)
    return string.format("%.2f", math.max(0, tonumber(value) or 0))
end

function Internal.getWorkerHeaderTitle(window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        local warehouseName = Internal.getWarehouseDisplayName and Internal.getWarehouseDisplayName(window) or tostring(window and window.workerName or T("DCCommon_UI_MainWindow_Warehouse", "Warehouse"))
        return T("DCCommon_UI_Supply_WarehouseSuffix", "{name} Warehouse", {
            name = warehouseName
        })
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
            return T("DCCommon_UI_Supply_WorkerInventoryStored", "{name} (Stored {stored} | Carry {carry} / {capacity}) Inventory", {
                name = workerName,
                stored = storedWeight,
                carry = carryWeight,
                capacity = carryCapacity,
            })
        end

        return T("DCCommon_UI_Supply_WorkerInventoryHaul", "{name} (Carry {carry} / {capacity} | Haul {haul} / {haulCapacity}) Inventory", {
            name = workerName,
            carry = carryWeight,
            capacity = carryCapacity,
            haul = haulWeight,
            haulCapacity = haulCapacity,
        })
    end

    return T("DCCommon_UI_Supply_WorkerInventoryCarry", "{name} Inventory (Carry {carry} / {capacity})", {
        name = workerName,
        carry = carryWeight,
        capacity = carryCapacity,
    })
end

function Internal.getTabButtonTitle(window, tabID)
    local baseTitle = T("DCCommon_UI_Supply_Provisions", "Provisions")
    if tabID == Internal.Tabs.Output then
        baseTitle = Internal.getOutputTabLabel(window and window.workerData, window)
    elseif tabID == Internal.Tabs.Equipment then
        baseTitle = T("DCCommon_UI_Supply_Equipment", "Equipment")
    end

    if tabID == Internal.Tabs.Provisions and Internal.isWarehouseView and Internal.isWarehouseView(window) then
        baseTitle = T("DCCommon_UI_Supply_Provision", "Provision")
    end

    local weightValue = 0
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        weightValue = Internal.getWarehouseLedgerWeight(window and window.workerData, tabID)
    else
        weightValue = Internal.getWorkerLedgerWeight and Internal.getWorkerLedgerWeight(window and window.workerData, tabID) or 0
    end

    return T("DCCommon_UI_Supply_TabWeight", "{title} W{weight}", {
        title = baseTitle,
        weight = Internal.formatWeightValue(weightValue)
    })
end
