DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

function Internal.getOutputTabLabel(worker, window)
    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        return "Storage"
    end

    if not worker or not worker.jobType then
        return "Merchandise"
    end

    local config = Internal.Config or {}
    local jobTypes = config.JobTypes or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")

    if normalizedJob == jobTypes.Farm then
        return "Yield"
    end
    if normalizedJob == jobTypes.Fish then
        return "Catch"
    end
    if normalizedJob == jobTypes.Scavenge then
        return "Haul"
    end

    return "Merchandise"
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

    if activeTab == Internal.Tabs.Output then
        local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
        local carryWeight = Internal.formatWeightValue(worker and worker.haulRawWeight)
        local carryCapacity = Internal.formatWeightValue(worker and worker.maxCarryWeight)

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
            .. ") Inventory"
    end

    return workerName .. " Inventory"
end

function Internal.getTabButtonTitle(window, tabID)
    local baseTitle = "Provisions"
    if tabID == Internal.Tabs.Output then
        baseTitle = Internal.getOutputTabLabel(window and window.workerData, window)
    elseif tabID == Internal.Tabs.Equipment then
        baseTitle = "Equipment"
    end

    if not (Internal.isWarehouseView and Internal.isWarehouseView(window)) then
        return baseTitle
    end

    if tabID == Internal.Tabs.Provisions then
        baseTitle = "Provision"
    end

    return baseTitle .. " W" .. Internal.formatWeightValue(Internal.getWarehouseLedgerWeight(window and window.workerData, tabID))
end
