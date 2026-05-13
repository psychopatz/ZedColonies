DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Nutrition = DC_Colony.Nutrition
local Config = DC_Colony.Config
local Data = Internal.ColonyRegLedgers or {}

Internal.ColonyRegLedgers = Data

function Data.getEntryWeight(fullType, qty)
    return math.max(0, tonumber(Config.GetItemWeight and Config.GetItemWeight(fullType)) or 0) * math.max(1, tonumber(qty) or 1)
end

function Data.getWorkerInventoryCapacity(worker)
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

function Data.getWorkerLedgerWeight(entries)
    local totalWeight = 0
    for _, entry in ipairs(entries or {}) do
        totalWeight = totalWeight + Data.getEntryWeight(entry and entry.fullType, entry and entry.qty)
    end
    return totalWeight
end

function Data.mergeOutputLikeEntry(targetLedger, entry)
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

function Data.findRequirementInsertIndex(worker, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "" then
        return nil
    end

    for index, existing in ipairs(worker and worker.toolLedger or {}) do
        if tostring(existing and existing.assignedRequirementKey or "") == targetKey then
            return index
        end
        if Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(existing and existing.fullType, targetKey, worker) then
            return index
        end
    end

    return nil
end

function Data.storeReplacedToolInWorkerOutput(worker, entry)
    if not worker or not entry or not entry.fullType then
        return false
    end

    worker.outputLedger = worker.outputLedger or {}
    if Data.mergeOutputLikeEntry(worker.outputLedger, entry) then
        Internal.MarkOutputCacheDirty(worker)
        return true
    end

    return false
end

Data.Nutrition = Nutrition

return Data