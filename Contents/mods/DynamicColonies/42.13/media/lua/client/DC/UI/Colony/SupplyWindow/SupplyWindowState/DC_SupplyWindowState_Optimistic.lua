DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function ensureWarehouse(workerData)
    if type(workerData) ~= "table" then
        return nil
    end

    workerData.warehouse = type(workerData.warehouse) == "table" and workerData.warehouse or {}
    local warehouse = workerData.warehouse
    warehouse.ledgers = type(warehouse.ledgers) == "table" and warehouse.ledgers or {}
    warehouse.ledgers.provisions = type(warehouse.ledgers.provisions) == "table" and warehouse.ledgers.provisions or {}
    warehouse.ledgers.equipment = type(warehouse.ledgers.equipment) == "table" and warehouse.ledgers.equipment or {}
    warehouse.ledgers.output = type(warehouse.ledgers.output) == "table" and warehouse.ledgers.output or {}
    warehouse.maxWeight = math.max(0, tonumber(warehouse.maxWeight) or 0)
    warehouse.usedWeight = math.max(0, tonumber(warehouse.usedWeight) or 0)
    warehouse.remainingWeight = math.max(0, tonumber(warehouse.remainingWeight) or math.max(0, warehouse.maxWeight - warehouse.usedWeight))
    return warehouse
end

local function getEntryUnitWeight(entry)
    if not entry or not entry.fullType then
        return 0
    end

    return math.max(0, tonumber(entry.unitWeight) or tonumber(Internal.Config and Internal.Config.GetItemWeight and Internal.Config.GetItemWeight(entry.fullType)) or 0)
end

local function getEquipmentSignature(entry)
    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
    return registryInternal and registryInternal.GetEquipmentDurabilitySignature and registryInternal.GetEquipmentDurabilitySignature(entry) or ""
end

local function entryMatchesRequirement(entry, requirementKey)
    local config = Internal.Config or {}
    local key = tostring(requirementKey or "")
    return key ~= ""
        and entry
        and entry.fullType
        and config.ItemMatchesEquipmentRequirement
        and config.ItemMatchesEquipmentRequirement(entry.fullType, key)
        or false
end

local function promoteLedgerEntryForRequirement(ledger, entry, requirementKey)
    if type(ledger) ~= "table" or type(entry) ~= "table" or tostring(requirementKey or "") == "" then
        return
    end

    local entryIndex = nil
    for index = #ledger, 1, -1 do
        if ledger[index] == entry then
            entryIndex = index
            break
        end
    end
    if not entryIndex then
        return
    end

    local insertIndex = nil
    for index, existing in ipairs(ledger) do
        if index ~= entryIndex and entryMatchesRequirement(existing, requirementKey) then
            insertIndex = index
            break
        end
    end

    if not insertIndex or insertIndex >= entryIndex then
        return
    end

    table.remove(ledger, entryIndex)
    table.insert(ledger, insertIndex, entry)
end

local function pruneRedundantPendingEquipmentEntries(ledger)
    if type(ledger) ~= "table" then
        return
    end

    local resolvedCounts = {}
    for _, entry in ipairs(ledger) do
        if entry and entry.pending ~= true then
            local signature = getEquipmentSignature(entry)
            if signature ~= "" then
                resolvedCounts[signature] = (resolvedCounts[signature] or 0) + 1
            end
        end
    end

    for index = #ledger, 1, -1 do
        local entry = ledger[index]
        if entry and entry.pending == true then
            local signature = getEquipmentSignature(entry)
            if signature ~= "" and (resolvedCounts[signature] or 0) > 0 then
                resolvedCounts[signature] = resolvedCounts[signature] - 1
                table.remove(ledger, index)
            end
        end
    end
end

local function applyWarehouseWeightDelta(workerData, delta)
    local warehouse = ensureWarehouse(workerData)
    if not warehouse then
        return
    end

    warehouse.usedWeight = math.max(0, math.max(0, tonumber(warehouse.usedWeight) or 0) + (tonumber(delta) or 0))
    warehouse.remainingWeight = math.max(0, math.max(0, tonumber(warehouse.maxWeight) or 0) - warehouse.usedWeight)
end

local function addOptimisticProvision(window, entry)
    if not entry then
        return false
    end

    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        local warehouse = ensureWarehouse(window.workerData)
        if not warehouse then
            return false
        end
        local normalizedProvisionType = entry.provisionType or "nutrition"
        local normalizedCalories = math.max(0, tonumber(entry.calories) or 0)
        local normalizedHydration = math.max(0, tonumber(entry.hydration) or 0)
        local normalizedTreatmentUnits = math.max(0, tonumber(entry.treatmentUnits) or 0)
        local normalizedMedicalUse = normalizedProvisionType == "medical" and "bandage" or nil

        for _, existing in ipairs(warehouse.ledgers.provisions) do
            if existing.fullType == entry.fullType
                and tostring(existing.provisionType or "nutrition") == tostring(normalizedProvisionType)
                and math.max(0, tonumber(existing.caloriesRemaining) or 0) == normalizedCalories
                and math.max(0, tonumber(existing.hydrationRemaining) or 0) == normalizedHydration
                and math.max(0, tonumber(existing.treatmentUnitsRemaining) or 0) == normalizedTreatmentUnits
                and tostring(existing.medicalUse or "") == tostring(normalizedMedicalUse or "") then
                existing.qty = math.max(1, tonumber(existing.qty) or 1) + 1
                existing.pending = true
                applyWarehouseWeightDelta(window.workerData, getEntryUnitWeight(entry))
                return true
            end
        end

        warehouse.ledgers.provisions[#warehouse.ledgers.provisions + 1] = {
            fullType = entry.fullType,
            displayName = entry.displayName,
            provisionType = normalizedProvisionType,
            caloriesRemaining = normalizedCalories,
            hydrationRemaining = normalizedHydration,
            treatmentUnitsRemaining = normalizedTreatmentUnits,
            medicalUse = normalizedMedicalUse,
            qty = 1,
            pending = true,
        }
        applyWarehouseWeightDelta(window.workerData, getEntryUnitWeight(entry))
        return true
    end

    window.workerData = type(window.workerData) == "table" and window.workerData or {}
    window.workerData.nutritionLedger = type(window.workerData.nutritionLedger) == "table" and window.workerData.nutritionLedger or {}
    window.workerData.nutritionLedger[#window.workerData.nutritionLedger + 1] = {
        fullType = entry.fullType,
        displayName = entry.displayName,
        provisionType = entry.provisionType or "nutrition",
        caloriesRemaining = math.max(0, tonumber(entry.calories) or 0),
        hydrationRemaining = math.max(0, tonumber(entry.hydration) or 0),
        treatmentUnitsRemaining = math.max(0, tonumber(entry.treatmentUnits) or 0),
        medicalUse = entry.provisionType == "medical" and "bandage" or nil,
        pending = true,
    }
    return true
end

local function addOptimisticTool(window, entry, requirementKey)
    if not entry then
        return false
    end

    if Internal.isWarehouseView and Internal.isWarehouseView(window) then
        local warehouse = ensureWarehouse(window.workerData)
        if not warehouse then
            return false
        end
        local optimisticEntry = {
            fullType = entry.fullType,
            displayName = entry.displayName,
            tags = entry.tags or {},
            condition = entry.condition,
            conditionMax = entry.conditionMax,
            isDrainable = entry.isDrainable == true,
            useDelta = entry.useDelta,
            usedDelta = entry.usedDelta,
            keepOnDeplete = entry.keepOnDeplete == true,
            pending = true,
        }
        warehouse.ledgers.equipment[#warehouse.ledgers.equipment + 1] = optimisticEntry
        promoteLedgerEntryForRequirement(warehouse.ledgers.equipment, optimisticEntry, requirementKey)
        applyWarehouseWeightDelta(window.workerData, getEntryUnitWeight(entry))
        return true
    end

    window.workerData = type(window.workerData) == "table" and window.workerData or {}
    window.workerData.toolLedger = type(window.workerData.toolLedger) == "table" and window.workerData.toolLedger or {}
    local optimisticEntry = {
        fullType = entry.fullType,
        displayName = entry.displayName,
        tags = entry.tags or {},
        condition = entry.condition,
        conditionMax = entry.conditionMax,
        isDrainable = entry.isDrainable == true,
        useDelta = entry.useDelta,
        usedDelta = entry.usedDelta,
        keepOnDeplete = entry.keepOnDeplete == true,
        pending = true,
    }
    window.workerData.toolLedger[#window.workerData.toolLedger + 1] = optimisticEntry
    promoteLedgerEntryForRequirement(window.workerData.toolLedger, optimisticEntry, requirementKey)
    return true
end

local function addOptimisticOutput(window, entry)
    if not entry or not (Internal.isWarehouseView and Internal.isWarehouseView(window)) then
        return false
    end

    local warehouse = ensureWarehouse(window.workerData)
    if not warehouse then
        return false
    end

    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
    local normalizedEntry = registryInternal and registryInternal.NormalizeOutputEntry and registryInternal.NormalizeOutputEntry(entry)
        or {
            fullType = entry.fullType,
            displayName = entry.displayName,
            qty = 1,
            fluidAmount = entry.fluidAmount,
        }
    local stackKey = registryInternal and registryInternal.GetOutputEntryStateSignature and registryInternal.GetOutputEntryStateSignature(normalizedEntry)
        or tostring(normalizedEntry and normalizedEntry.fullType or "")

    for _, existing in ipairs(warehouse.ledgers.output) do
        local existingKey = registryInternal and registryInternal.GetOutputEntryStateSignature and registryInternal.GetOutputEntryStateSignature(existing)
            or tostring(existing and existing.fullType or "")
        if existingKey == stackKey then
            existing.qty = math.max(1, tonumber(existing.qty) or 1) + 1
            existing.pending = true
            applyWarehouseWeightDelta(window.workerData, getEntryUnitWeight(entry))
            return true
        end
    end

    warehouse.ledgers.output[#warehouse.ledgers.output + 1] = {
        fullType = normalizedEntry.fullType,
        displayName = normalizedEntry.displayName,
        qty = 1,
        fluidAmount = normalizedEntry.fluidAmount,
        isRottenProvision = normalizedEntry.isRottenProvision == true,
        provisionBlockedReason = normalizedEntry.provisionBlockedReason,
        condition = normalizedEntry.condition,
        conditionMax = normalizedEntry.conditionMax,
        isDrainable = normalizedEntry.isDrainable == true,
        useDelta = normalizedEntry.useDelta,
        usedDelta = normalizedEntry.usedDelta,
        keepOnDeplete = normalizedEntry.keepOnDeplete == true,
        pending = true,
    }
    applyWarehouseWeightDelta(window.workerData, getEntryUnitWeight(entry))
    return true
end

function DC_SupplyWindow:applyOptimisticDeposit(entries)
    local changed = false
    local activeTab = self.activeTab or Internal.Tabs.Provisions

    for _, entry in ipairs(entries or {}) do
        local removed = self:removePlayerEntryByID(entry.itemID)
        if removed then
            changed = true
            if activeTab == Internal.Tabs.Output then
                addOptimisticOutput(self, entry)
            else
                addOptimisticProvision(self, entry)
            end
        end
    end

    if changed then
        self:rebuildPlayerList()
        self:refreshWorkerEntries()
    end
end

function DC_SupplyWindow:applyOptimisticToolAssign(entries, requirementKey)
    local changed = false

    for _, entry in ipairs(entries or {}) do
        local removed = self:removePlayerEntryByID(entry.itemID)
        if removed then
            changed = true
            addOptimisticTool(self, entry, requirementKey)
        end
    end

    if changed then
        self:rebuildPlayerList()
        self:refreshWorkerEntries()
    end
end

function DC_SupplyWindow:applyOptimisticWarehouseToolAssign(entry, requirementKey)
    if not entry or not entry.ledgerIndex then
        return
    end

    local warehouse = self.workerData and self.workerData.warehouse or nil
    local equipmentLedger = warehouse and warehouse.ledgers and warehouse.ledgers.equipment or nil
    local removed = nil
    local index = math.floor(tonumber(entry.ledgerIndex) or 0)

    if equipmentLedger and index > 0 and equipmentLedger[index] then
        removed = table.remove(equipmentLedger, index)
        applyWarehouseWeightDelta(self.workerData, -getEntryUnitWeight(removed or entry))
    end

    addOptimisticTool(self, removed or entry, requirementKey)
    self:refreshWorkerEntries()
end

function DC_SupplyWindow:pruneOptimisticEquipmentDuplicates()
    local workerData = type(self.workerData) == "table" and self.workerData or nil
    if not workerData then
        return
    end

    pruneRedundantPendingEquipmentEntries(workerData.toolLedger)

    local warehouse = workerData.warehouse
    local equipmentLedger = warehouse and warehouse.ledgers and warehouse.ledgers.equipment or nil
    pruneRedundantPendingEquipmentEntries(equipmentLedger)
end
