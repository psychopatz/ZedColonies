DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getLedgerWeight(entries)
    local config = Internal.Config or {}
    local totalWeight = 0
    for _, entry in ipairs(entries or {}) do
        local qty = math.max(1, tonumber(entry and entry.qty) or 1)
        totalWeight = totalWeight + (math.max(0, tonumber(config.GetItemWeight and config.GetItemWeight(entry and entry.fullType)) or 0) * qty)
    end
    return totalWeight
end

local function getCategoryStockWeight(stock)
    local totalWeight = 0
    for _, entry in pairs(stock or {}) do
        if type(entry) == "table" then
            totalWeight = totalWeight + math.max(0, tonumber(entry.totalWeight) or 0)
        end
    end
    return totalWeight
end

function Internal.getWorkerSupplyTotals(entries)
    local totals = {
        count = 0,
        calories = 0,
        hydration = 0,
        medicalUnits = 0,
        money = 0,
    }

    for _, entry in ipairs(entries or {}) do
        if entry.kind == "money" then
            totals.money = totals.money + math.max(0, math.floor(tonumber(entry.amount) or 0))
        else
            local qty = math.max(1, tonumber(entry.qty) or 1)
            totals.count = totals.count + qty
            totals.calories = totals.calories + ((tonumber(entry.totalCalories) or math.max(0, tonumber(entry.calories) or 0) * qty))
            totals.hydration = totals.hydration + ((tonumber(entry.totalHydration) or math.max(0, tonumber(entry.hydration) or 0) * qty))
            totals.medicalUnits = totals.medicalUnits + ((tonumber(entry.totalTreatmentUnits) or math.max(0, tonumber(entry.treatmentUnits) or 0) * qty))
        end
    end

    return totals
end

function Internal.getEntryWeightTotal(entries)
    local totalWeight = 0
    for _, entry in ipairs(entries or {}) do
        totalWeight = totalWeight + math.max(0, tonumber(entry and entry.totalWeight) or tonumber(entry and entry.unitWeight) or 0)
    end
    return totalWeight
end

function Internal.getWorkerInventoryWeightState(worker)
    local hasNutritionLedger = worker and type(worker.nutritionLedger) == "table"
    local hasToolLedger = worker and type(worker.toolLedger) == "table"
    local hasOutputLedger = worker and type(worker.outputLedger) == "table"
    local provisionsWeight = math.max(0, hasNutritionLedger and getLedgerWeight(worker.nutritionLedger) or tonumber(worker and worker.inventoryProvisionWeight) or 0)
    local equipmentWeight = math.max(0, hasToolLedger and getLedgerWeight(worker.toolLedger) or tonumber(worker and worker.inventoryEquipmentWeight) or 0)
    local outputWeight = math.max(0, hasOutputLedger and getLedgerWeight(worker.outputLedger) or tonumber(worker and worker.inventoryOutputWeight) or 0)
    local usedWeight = math.max(0, (hasNutritionLedger or hasToolLedger or hasOutputLedger) and (provisionsWeight + equipmentWeight + outputWeight) or tonumber(worker and worker.inventoryUsedWeight) or (provisionsWeight + equipmentWeight + outputWeight))
    local maxWeight = math.max(
        0,
        tonumber(worker and worker.inventoryMaxWeight)
            or tonumber(worker and worker.maxCarryWeight)
            or tonumber(worker and worker.baseCarryWeight)
            or 0
    )

    return {
        provisionsWeight = provisionsWeight,
        equipmentWeight = equipmentWeight,
        outputWeight = outputWeight,
        usedWeight = usedWeight,
        maxWeight = maxWeight,
        remainingWeight = math.max(0, (hasNutritionLedger or hasToolLedger or hasOutputLedger) and math.max(0, maxWeight - usedWeight) or tonumber(worker and worker.inventoryRemainingWeight) or math.max(0, maxWeight - usedWeight)),
    }
end

function Internal.getWorkerLedgerWeight(worker, tabID)
    local state = Internal.getWorkerInventoryWeightState(worker)
    if tabID == Internal.Tabs.Equipment then
        return state.equipmentWeight
    end
    if tabID == Internal.Tabs.Output then
        return state.outputWeight
    end
    return state.provisionsWeight
end

function Internal.getWarehouseLedgerWeight(worker, tabID)
    local warehouse = worker and worker.warehouse or nil
    local ledgers = warehouse and warehouse.ledgers or {}

    if tabID == Internal.Tabs.Provisions then
        return getLedgerWeight(ledgers.provisions)
    end

    if tabID == Internal.Tabs.Equipment then
        return getLedgerWeight(ledgers.equipment)
    end

    return getCategoryStockWeight(warehouse and warehouse.abstractStock)
        + getLedgerWeight(warehouse and warehouse.literalSpecialStock)
        + getLedgerWeight(ledgers.output)
end
