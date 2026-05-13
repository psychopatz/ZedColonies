DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegLedgers or {}

function Registry.GetInventoryWeightState(worker)
    local hasNutritionLedger = worker and type(worker.nutritionLedger) == "table"
    local hasToolLedger = worker and type(worker.toolLedger) == "table"
    local hasOutputLedger = worker and type(worker.outputLedger) == "table"
    local provisionsWeight = math.max(0, hasNutritionLedger and Data.getWorkerLedgerWeight(worker.nutritionLedger) or tonumber(worker and worker.inventoryProvisionWeight) or 0)
    local equipmentWeight = math.max(0, hasToolLedger and Data.getWorkerLedgerWeight(worker.toolLedger) or tonumber(worker and worker.inventoryEquipmentWeight) or 0)
    local outputWeight = math.max(0, hasOutputLedger and Data.getWorkerLedgerWeight(worker.outputLedger) or tonumber(worker and worker.inventoryOutputWeight) or 0)
    local usedWeight = math.max(0, (hasNutritionLedger or hasToolLedger or hasOutputLedger) and (provisionsWeight + equipmentWeight + outputWeight) or tonumber(worker and worker.inventoryUsedWeight) or (provisionsWeight + equipmentWeight + outputWeight))
    local maxWeight = Data.getWorkerInventoryCapacity(worker)
    return {
        provisionsWeight = provisionsWeight,
        equipmentWeight = equipmentWeight,
        outputWeight = outputWeight,
        usedWeight = usedWeight,
        maxWeight = maxWeight,
        remainingWeight = math.max(0, maxWeight - usedWeight),
    }
end

function Registry.GetInventoryRemainingCapacity(worker)
    local state = Registry.GetInventoryWeightState(worker)
    return math.max(0, tonumber(state and state.remainingWeight) or 0)
end

function Registry.GetFittingInventoryQuantity(worker, fullType, requestedQty)
    local quantity = math.max(1, math.floor(tonumber(requestedQty) or 1))
    local unitWeight = Data.getEntryWeight(fullType, 1)
    if unitWeight <= 0 then
        return quantity
    end

    local remaining = Registry.GetInventoryRemainingCapacity(worker)
    return math.max(0, math.floor(remaining / unitWeight))
end

return Data