DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegLedgers or {}

function Registry.AddNutritionEntry(worker, entry)
    if not worker or not entry then
        return false
    end
    if Registry.GetFittingInventoryQuantity(worker, entry.fullType, 1) < 1 then
        return false
    end

    worker.nutritionLedger = worker.nutritionLedger or {}
    entry.entryID = entry.entryID or (Internal.GenerateLedgerEntryID and Internal.GenerateLedgerEntryID("prov") or nil)
    local calories = 0
    local hydration = 0
    if Data.Nutrition and Data.Nutrition.SanitizeLedgerEntry then
        calories, hydration = Data.Nutrition.SanitizeLedgerEntry(entry)
    end
    worker.nutritionLedger[#worker.nutritionLedger + 1] = entry
    if not Internal.ApplyNutritionCacheDelta(worker, calories, hydration) then
        Internal.MarkNutritionCacheDirty(worker)
    end
    return true
end

function Registry.AddToolEntry(worker, entry)
    if not worker or not entry then
        return false
    end

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

function Registry.AddToolEntryForRequirement(worker, entry, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "" then
        return Registry.AddToolEntry(worker, entry)
    end

    if not worker or not entry then
        return false
    end

    local normalized = Internal.NormalizeEquipmentEntry and Internal.NormalizeEquipmentEntry(entry) or entry
    if not normalized or not normalized.fullType or not (Internal.IsEquipmentEntryUsable and Internal.IsEquipmentEntryUsable(normalized)) then
        return false
    end

    if Internal.CopyShallow == nil then
        return false
    end

    if DC_Colony.Config.ItemMatchesWorkerEquipmentRequirement
        and not DC_Colony.Config.ItemMatchesWorkerEquipmentRequirement(normalized.fullType, targetKey, worker) then
        return false
    end

    worker.toolLedger = worker.toolLedger or {}
    local insertIndex = Data.findRequirementInsertIndex(worker, targetKey)
    local replacingEntry = insertIndex and worker.toolLedger[insertIndex] or nil
    local replacingWeight = replacingEntry and Data.getEntryWeight(replacingEntry.fullType, replacingEntry.qty) or 0
    local requestedQty = math.max(1, tonumber(normalized.qty) or 1)
    local requiredWeight = Data.getEntryWeight(normalized.fullType, requestedQty)
    if not replacingEntry and Registry.GetFittingInventoryQuantity(worker, normalized.fullType, requestedQty) < requestedQty then
        return false
    end
    if replacingEntry then
        local state = Registry.GetInventoryWeightState(worker)
        local adjustedRemaining = math.max(0, tonumber(state and state.remainingWeight) or 0) + replacingWeight
        if requiredWeight > 0 and requiredWeight > adjustedRemaining + 0.0001 then
            return false
        end
    end

    normalized.assignedRequirementKey = targetKey
    if targetKey == "Colony.Combat.Ammo" and replacingEntry and tostring(replacingEntry.fullType or "") == tostring(normalized.fullType or "") then
        replacingEntry.qty = math.max(1, math.floor(tonumber(replacingEntry.qty) or 1))
            + math.max(1, math.floor(tonumber(normalized.qty) or 1))
        Registry.Internal.MarkToolCacheDirty(worker)
        return true
    end

    if insertIndex then
        if replacingEntry then
            Data.storeReplacedToolInWorkerOutput(worker, replacingEntry)
        end
        worker.toolLedger[insertIndex] = normalized
    else
        worker.toolLedger[#worker.toolLedger + 1] = normalized
    end

    Internal.MarkToolCacheDirty(worker)
    return true
end

function Registry.AddOutputEntry(worker, entry)
    if not worker or not entry or not entry.fullType then
        return 0
    end

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
    if Data.mergeOutputLikeEntry(worker.outputLedger, normalized) then
        Internal.MarkOutputCacheDirty(worker)
    end
    return fitQty
end

function Registry.AddHaulEntry(worker, entry)
    if not worker or not entry or not entry.fullType then
        return
    end
    worker.haulLedger = worker.haulLedger or {}
    Data.mergeOutputLikeEntry(worker.haulLedger, entry)
end

return Data