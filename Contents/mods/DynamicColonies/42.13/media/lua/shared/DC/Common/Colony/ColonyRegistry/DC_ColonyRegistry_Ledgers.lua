DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Nutrition = DC_Colony.Nutrition
local Config = DC_Colony.Config

local function getEntryWeight(fullType, qty)
    return math.max(0, tonumber(Config.GetItemWeight and Config.GetItemWeight(fullType)) or 0) * math.max(1, tonumber(qty) or 1)
end

local function getWorkerInventoryCapacity(worker)
    return math.max(
        0,
        tonumber(worker and worker.inventoryMaxWeight)
            or tonumber(worker and worker.maxCarryWeight)
            or tonumber(worker and worker.baseCarryWeight)
            or tonumber(Config.GetWorkerBaseCarryWeight and Config.GetWorkerBaseCarryWeight(worker))
            or tonumber(Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight())
            or tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT)
            or 0
    )
end

local function getWorkerLedgerWeight(entries)
    local totalWeight = 0
    for _, entry in ipairs(entries or {}) do
        totalWeight = totalWeight + getEntryWeight(entry and entry.fullType, entry and entry.qty)
    end
    return totalWeight
end

local function mergeOutputLikeEntry(targetLedger, entry)
    if not targetLedger or not entry or not entry.fullType then
        return false
    end

    local normalized = Internal.NormalizeOutputEntry and Internal.NormalizeOutputEntry(entry) or entry
    if not normalized or not normalized.fullType then
        return false
    end

    local qtyDelta = math.max(1, tonumber(normalized.qty) or 1)
    local entrySignature = Internal.GetOutputEntryStateSignature and Internal.GetOutputEntryStateSignature(normalized)
        or tostring(normalized.fullType)
    for _, existing in ipairs(targetLedger) do
        local existingSignature = Internal.GetOutputEntryStateSignature and Internal.GetOutputEntryStateSignature(existing)
            or tostring(existing and existing.fullType or "")
        if existingSignature == entrySignature then
            existing.qty = (existing.qty or 0) + qtyDelta
            return true
        end
    end

    normalized.qty = qtyDelta
    targetLedger[#targetLedger + 1] = normalized
    return true
end

function Registry.GetInventoryWeightState(worker)
    local hasNutritionLedger = worker and type(worker.nutritionLedger) == "table"
    local hasToolLedger = worker and type(worker.toolLedger) == "table"
    local hasOutputLedger = worker and type(worker.outputLedger) == "table"
    local provisionsWeight = math.max(0, hasNutritionLedger and getWorkerLedgerWeight(worker.nutritionLedger) or tonumber(worker and worker.inventoryProvisionWeight) or 0)
    local equipmentWeight = math.max(0, hasToolLedger and getWorkerLedgerWeight(worker.toolLedger) or tonumber(worker and worker.inventoryEquipmentWeight) or 0)
    local outputWeight = math.max(0, hasOutputLedger and getWorkerLedgerWeight(worker.outputLedger) or tonumber(worker and worker.inventoryOutputWeight) or 0)
    local usedWeight = math.max(0, (hasNutritionLedger or hasToolLedger or hasOutputLedger) and (provisionsWeight + equipmentWeight + outputWeight) or tonumber(worker and worker.inventoryUsedWeight) or (provisionsWeight + equipmentWeight + outputWeight))
    local maxWeight = getWorkerInventoryCapacity(worker)
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
    local unitWeight = getEntryWeight(fullType, 1)
    if unitWeight <= 0 then
        return quantity
    end

    local remaining = Registry.GetInventoryRemainingCapacity(worker)
    return math.max(0, math.floor(remaining / unitWeight))
end

function Registry.AddNutritionEntry(worker, entry)
    if not worker or not entry then return false end
    if Registry.GetFittingInventoryQuantity(worker, entry.fullType, 1) < 1 then
        return false
    end
    worker.nutritionLedger = worker.nutritionLedger or {}
    local calories = 0
    local hydration = 0
    if Nutrition and Nutrition.SanitizeLedgerEntry then
        calories, hydration = Nutrition.SanitizeLedgerEntry(entry)
    end
    worker.nutritionLedger[#worker.nutritionLedger + 1] = entry
    if not Internal.ApplyNutritionCacheDelta(worker, calories, hydration) then
        Internal.MarkNutritionCacheDirty(worker)
    end
    return true
end

function Registry.AddToolEntry(worker, entry)
    if not worker or not entry then return false end
    local normalized = Internal.NormalizeEquipmentEntry and Internal.NormalizeEquipmentEntry(entry) or entry
    if not normalized or not normalized.fullType or not (Internal.IsEquipmentEntryUsable and Internal.IsEquipmentEntryUsable(normalized)) then
        return false
    end

    local requestedQty = math.max(1, tonumber(normalized.qty) or 1)
    if Registry.GetFittingInventoryQuantity(worker, normalized.fullType, requestedQty) < requestedQty then
        return false
    end
    worker.toolLedger = worker.toolLedger or {}
    worker.toolLedger[#worker.toolLedger + 1] = normalized
    if not Internal.ApplyToolTags(worker, normalized.tags or {}) then
        Internal.MarkToolCacheDirty(worker)
    end
    return true
end

function Registry.AddOutputEntry(worker, entry)
    if not worker or not entry or not entry.fullType then return 0 end
    local normalized = Internal.NormalizeOutputEntry and Internal.NormalizeOutputEntry(entry) or entry
    if not normalized or not normalized.fullType then
        return 0
    end

    local fitQty = Registry.GetFittingInventoryQuantity(worker, normalized.fullType, math.max(1, tonumber(normalized.qty) or 1))
    if fitQty <= 0 then
        return 0
    end
    worker.outputLedger = worker.outputLedger or {}
    normalized.qty = fitQty
    if mergeOutputLikeEntry(worker.outputLedger, normalized) then
        Internal.MarkOutputCacheDirty(worker)
    end
    return fitQty
end

function Registry.AddHaulEntry(worker, entry)
    if not worker or not entry or not entry.fullType then return end
    worker.haulLedger = worker.haulLedger or {}
    mergeOutputLikeEntry(worker.haulLedger, entry)
end

function Registry.GetHaulMetrics(worker)
    local rawWeight = 0
    local count = 0
    for _, entry in ipairs(worker and worker.haulLedger or {}) do
        local qty = math.max(1, tonumber(entry.qty) or 1)
        count = count + qty
        rawWeight = rawWeight + (Config.GetItemWeight(entry.fullType) * qty)
    end

    local carryProfile = Config.GetScavengeCarryProfile and Config.GetScavengeCarryProfile(worker) or nil
    local effectiveWeight = Config.CalculateEffectiveCarryWeight and Config.CalculateEffectiveCarryWeight(rawWeight, carryProfile) or rawWeight
    return {
        count = count,
        rawWeight = rawWeight,
        effectiveWeight = effectiveWeight,
        effectiveCarryLimit = carryProfile and carryProfile.effectiveCarryLimit
            or (Config.GetWorkerBaseCarryWeight and Config.GetWorkerBaseCarryWeight(worker))
            or (Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight())
            or (tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT) or 8),
        maxCarryWeight = carryProfile and carryProfile.maxCarryWeight
            or (Config.GetWorkerBaseCarryWeight and Config.GetWorkerBaseCarryWeight(worker))
            or (Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight())
            or (tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT) or 8)
    }
end

function Registry.DumpCarriedHaul(worker)
    if not worker then
        return 0, 0, 0
    end

    local haulEntries = worker.haulLedger or {}
    local remainingEntries = {}
    local movedStacks = 0
    local movedCount = 0
    local movedWeight = 0
    for _, entry in ipairs(haulEntries) do
        local requestedQty = math.max(1, tonumber(entry and entry.qty) or 1)
        local movedQty = Registry.AddOutputEntry(worker, entry)
        if movedQty > 0 then
            movedStacks = movedStacks + 1
            movedCount = movedCount + movedQty
            movedWeight = movedWeight + getEntryWeight(entry and entry.fullType, movedQty)
        end

        local leftoverQty = requestedQty - movedQty
        if leftoverQty > 0 then
            local leftoverEntry = Internal.NormalizeOutputEntry and Internal.NormalizeOutputEntry(entry) or Internal.CopyShallow(entry)
            leftoverEntry.qty = leftoverQty
            remainingEntries[#remainingEntries + 1] = leftoverEntry
        end
    end

    worker.haulLedger = remainingEntries
    return movedStacks, movedCount, movedWeight
end

function Registry.AddMoney(worker, amount)
    if not worker then return end
    worker.moneyStored = math.max(0, math.floor(tonumber(worker.moneyStored) or 0) + math.floor(tonumber(amount) or 0))
end

function Registry.RemoveMoney(worker, amount)
    if not worker then
        return 0
    end

    local available = math.max(0, math.floor(tonumber(worker.moneyStored) or 0))
    local requested = math.max(0, math.floor(tonumber(amount) or 0))
    local removed = math.min(available, requested)
    worker.moneyStored = available - removed
    return removed
end

function Registry.CollectOutput(worker)
    local output = worker and worker.outputLedger or {}
    if not worker then
        return output
    end
    worker.outputLedger = {}
    Internal.ResetOutputCount(worker)
    worker.outputWeight = 0
    return output
end

return Registry
