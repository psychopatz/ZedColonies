DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Ledgers = Internal.Ledgers or {}

Internal.Ledgers = Ledgers

function Ledgers.GetProvisionStackKey(entry)
    return table.concat({
        tostring(entry and entry.fullType or ""),
        tostring(entry and entry.provisionType or ""),
        tostring(math.max(0, tonumber(entry and entry.caloriesRemaining) or 0)),
        tostring(math.max(0, tonumber(entry and entry.hydrationRemaining) or 0)),
        tostring(math.max(0, tonumber(entry and entry.treatmentUnitsRemaining) or 0)),
        tostring(entry and entry.medicalUse or ""),
        tostring(entry and entry.consumedOutputFullType or ""),
        tostring(entry and entry.consumedOutputDisplayName or ""),
        tostring(entry and entry.consumedOutputFluidAmount ~= nil and string.format("%.4f", entry.consumedOutputFluidAmount) or "")
    }, "|")
end

function Ledgers.AppendProvisionEntry(warehouse, entry)
    if not warehouse or not entry or not entry.fullType then
        return false
    end

    local weight = Internal.GetEntryWeight(entry.fullType, 1)
    if weight > 0 and weight > Warehouse.GetRemainingCapacity(warehouse) then
        return false
    end

    local normalized = {
        fullType = entry.fullType,
        entryID = tostring(entry.entryID or Registry.Internal.GenerateLedgerEntryID and Registry.Internal.GenerateLedgerEntryID("prov") or ""),
        displayName = entry.displayName or Registry.Internal.GetDisplayNameForFullType(entry.fullType),
        provisionType = Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) and "medical" or "nutrition",
        caloriesRemaining = math.max(0, tonumber(entry.caloriesRemaining) or 0),
        hydrationRemaining = math.max(0, tonumber(entry.hydrationRemaining) or 0),
        treatmentUnitsRemaining = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0),
        medicalUse = Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) and tostring(entry.medicalUse or "bandage") or nil,
        qty = math.max(1, math.floor(tonumber(entry.qty) or 1))
    }
    if entry.consumedOutputFullType then
        normalized.consumedOutputFullType = tostring(entry.consumedOutputFullType)
        normalized.consumedOutputDisplayName = tostring(entry.consumedOutputDisplayName or Registry.Internal.GetDisplayNameForFullType(entry.consumedOutputFullType))
        if entry.consumedOutputFluidAmount ~= nil then
            normalized.consumedOutputFluidAmount = math.max(0, tonumber(entry.consumedOutputFluidAmount) or 0)
        end
    end

    local stackKey = Ledgers.GetProvisionStackKey(normalized)
    for _, existing in ipairs(warehouse.ledgers.provisions) do
        if Ledgers.GetProvisionStackKey(existing) == stackKey then
            existing.qty = math.max(1, math.floor(tonumber(existing.qty) or 1)) + normalized.qty
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

    local normalized = Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry(entry) or nil
    if not normalized then
        return false
    end

    local weight = Internal.GetEntryWeight(normalized.fullType, 1)
    if ignoreCapacity ~= true and weight > 0 and weight > Warehouse.GetRemainingCapacity(warehouse) then
        return false
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