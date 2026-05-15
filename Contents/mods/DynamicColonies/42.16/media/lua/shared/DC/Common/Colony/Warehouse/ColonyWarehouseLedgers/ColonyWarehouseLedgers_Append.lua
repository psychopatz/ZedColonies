DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local AbstractInventory = DC_Colony.AbstractInventory
local Internal = Warehouse.Internal
local Ledgers = Internal.Ledgers or {}

Internal.Ledgers = Ledgers

function Ledgers.GetProvisionStackKey(entry)
    return Internal.Data and Internal.Data.GetProvisionBucketKey and Internal.Data.GetProvisionBucketKey(entry) or ""
end

function Ledgers.AppendProvisionEntry(warehouse, entry)
    if not warehouse or not entry or not entry.fullType then
        return false
    end

    local weight = Internal.GetEntryWeight(entry.fullType, 1)
    if weight > 0 and weight > Warehouse.GetRemainingCapacity(warehouse) then
        return false
    end

    local normalized = Internal.Data and Internal.Data.NormalizeProvisionEntry and Internal.Data.NormalizeProvisionEntry(entry) or nil
    if not normalized then
        return false
    end

    local stackKey = Ledgers.GetProvisionStackKey(normalized)
    for _, existing in ipairs(warehouse.ledgers.provisions) do
        if Ledgers.GetProvisionStackKey(existing) == stackKey then
            if Internal.Data and Internal.Data.MergeProvisionEntries then
                Internal.Data.MergeProvisionEntries(existing, normalized)
            else
                existing.qty = math.max(1, math.floor(tonumber(existing.qty) or 1)) + normalized.qty
            end
            Warehouse.TouchItemsVersion(warehouse.ownerUsername)
            Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
            Warehouse.Recalculate(warehouse)
            return true
        end
    end

    warehouse.ledgers.provisions[#warehouse.ledgers.provisions + 1] = normalized
    Warehouse.TouchItemsVersion(warehouse.ownerUsername)
    Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
    Warehouse.Recalculate(warehouse)
    return true
end

function Ledgers.AppendEquipmentEntry(warehouse, entry, ignoreCapacity)
    if not warehouse or not entry or not entry.fullType then
        return false
    end

    local normalized = Internal.Data and Internal.Data.NormalizeEquipmentEntry and Internal.Data.NormalizeEquipmentEntry(entry) or nil
    if not normalized then
        return false
    end

    local weight = Internal.GetEntryWeight(normalized.fullType, 1)
    if ignoreCapacity ~= true and weight > 0 and weight > Warehouse.GetRemainingCapacity(warehouse) then
        return false
    end

    local stackKey = Internal.Data and Internal.Data.GetEquipmentStackKey and Internal.Data.GetEquipmentStackKey(normalized) or ""
    for _, existing in ipairs(warehouse.ledgers.equipment) do
        local existingKey = Internal.Data and Internal.Data.GetEquipmentStackKey and Internal.Data.GetEquipmentStackKey(existing) or ""
        if existingKey == stackKey then
            if Internal.Data and Internal.Data.MergeEquipmentEntries then
                Internal.Data.MergeEquipmentEntries(existing, normalized)
            else
                existing.qty = math.max(1, tonumber(existing.qty) or 1) + math.max(1, tonumber(normalized.qty) or 1)
            end
            Warehouse.TouchItemsVersion(warehouse.ownerUsername)
            Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
            Warehouse.Recalculate(warehouse)
            return true
        end
    end

    warehouse.ledgers.equipment[#warehouse.ledgers.equipment + 1] = normalized
    Warehouse.TouchItemsVersion(warehouse.ownerUsername)
    Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
    Warehouse.Recalculate(warehouse)
    return true
end

function Ledgers.MergeOutputEntry(warehouse, entry)
    local normalized = Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or nil
    if not warehouse or not normalized or not normalized.fullType then
        return 0
    end

    if Internal.Data and Internal.Data.ShouldStoreAsLiteralSpecial
        and Internal.Data.ShouldStoreAsLiteralSpecial(normalized) == true then
        return AbstractInventory and AbstractInventory.AddLiteralSpecial and AbstractInventory.AddLiteralSpecial(warehouse.ownerUsername, normalized) or 0
    end

    if normalized.forceLiteral ~= true then
        return AbstractInventory and AbstractInventory.DepositOutputEntry and AbstractInventory.DepositOutputEntry(warehouse.ownerUsername, normalized) or 0
    end

    local qty = math.max(1, tonumber(normalized.qty) or 1)
    local unitWeight = Internal.GetEntryWeight(normalized.fullType, 1)
    local remainingCapacity = Warehouse.GetRemainingCapacity(warehouse)
    local fitQty = qty

    if unitWeight > 0 and remainingCapacity < (unitWeight * qty) then
        fitQty = math.floor(remainingCapacity / unitWeight)
    end

    if fitQty <= 0 and unitWeight > 0 then
        return 0
    end
    if fitQty <= 0 then
        fitQty = qty
    end

    local stackKey = Registry.Internal.GetOutputEntryStateSignature and Registry.Internal.GetOutputEntryStateSignature(normalized)
        or normalized.fullType
    for _, existing in ipairs(warehouse.ledgers.output) do
        local existingKey = Registry.Internal.GetOutputEntryStateSignature and Registry.Internal.GetOutputEntryStateSignature(existing)
            or tostring(existing and existing.fullType or "")
        if existingKey == stackKey then
            existing.qty = math.max(1, tonumber(existing.qty) or 1) + fitQty
            Warehouse.TouchItemsVersion(warehouse.ownerUsername)
            Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
            Warehouse.Recalculate(warehouse)
            return fitQty
        end
    end

    normalized.qty = fitQty
    warehouse.ledgers.output[#warehouse.ledgers.output + 1] = normalized
    Warehouse.TouchItemsVersion(warehouse.ownerUsername)
    Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
    Warehouse.Recalculate(warehouse)
    return fitQty
end

return Warehouse
