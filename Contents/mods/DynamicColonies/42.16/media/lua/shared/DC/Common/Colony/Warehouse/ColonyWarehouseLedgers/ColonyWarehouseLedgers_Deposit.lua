DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Ledgers = Internal.Ledgers or {}

Internal.Ledgers = Ledgers

function Warehouse.DepositProvisionEntry(ownerUsername, entry)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return Ledgers.AppendProvisionEntry(warehouse, entry)
end

function Warehouse.DepositEquipmentEntry(ownerUsername, entry, ignoreCapacity)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return Ledgers.AppendEquipmentEntry(warehouse, entry, ignoreCapacity)
end

function Warehouse.DepositOutputEntry(ownerUsername, entry)
    if not entry or not entry.fullType then
        return 0
    end
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return Ledgers.MergeOutputEntry(warehouse, entry)
end

function Warehouse.DepositHaulEntry(ownerUsername, entry)
    if not entry or not entry.fullType then
        return 0, 0
    end

    local totalQty = math.max(1, tonumber(entry.qty) or 1)
    local movedQty = Warehouse.DepositOutputEntry(ownerUsername, entry)

    return movedQty, math.max(0, totalQty - movedQty)
end

function Warehouse.DepositWorkerHaul(worker)
    if not worker then
        return 0, 0, 0, 0
    end

    local remainingEntries = {}
    local movedStacks = 0
    local movedCount = 0
    local movedWeight = 0
    local leftoverCount = 0

    for _, entry in ipairs(worker.haulLedger or {}) do
        local qty = math.max(1, tonumber(entry.qty) or 1)
        local movedQty, leftoverQty = Warehouse.DepositHaulEntry(worker.ownerUsername, entry)
        if movedQty > 0 then
            movedStacks = movedStacks + 1
            movedCount = movedCount + movedQty
            movedWeight = movedWeight + Internal.GetEntryWeight(entry.fullType, movedQty)
        end
        if leftoverQty > 0 then
            leftoverCount = leftoverCount + leftoverQty
            local leftoverEntry = Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or Registry.Internal.CopyShallow(entry)
            leftoverEntry.qty = leftoverQty
            remainingEntries[#remainingEntries + 1] = leftoverEntry
        elseif movedQty <= 0 then
            leftoverCount = leftoverCount + qty
            local leftoverEntry = Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or Registry.Internal.CopyShallow(entry)
            leftoverEntry.qty = qty
            remainingEntries[#remainingEntries + 1] = leftoverEntry
        end
    end

    worker.haulLedger = remainingEntries
    return movedStacks, movedCount, movedWeight, leftoverCount
end

function Warehouse.DepositWorkerOutput(worker)
    if not worker then
        return 0, 0, 0, 0
    end

    local remainingEntries = {}
    local movedStacks = 0
    local movedCount = 0
    local movedWeight = 0
    local leftoverCount = 0

    for _, entry in ipairs(worker.outputLedger or {}) do
        local normalized = Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or nil
        if normalized then
            local requestedQty = math.max(1, tonumber(normalized.qty) or 1)
            local movedQty = Warehouse.DepositOutputEntry(worker.ownerUsername, normalized)
            if movedQty > 0 then
                movedStacks = movedStacks + 1
                movedCount = movedCount + movedQty
                movedWeight = movedWeight + Internal.GetEntryWeight(normalized.fullType, movedQty)
            end

            local leftoverQty = requestedQty - movedQty
            if leftoverQty > 0 then
                leftoverCount = leftoverCount + leftoverQty
                normalized.qty = leftoverQty
                remainingEntries[#remainingEntries + 1] = normalized
            elseif movedQty <= 0 then
                leftoverCount = leftoverCount + requestedQty
                normalized.qty = requestedQty
                remainingEntries[#remainingEntries + 1] = normalized
            end
        end
    end

    if movedCount > 0 then
        worker.outputLedger = remainingEntries
        if Registry.Internal and Registry.Internal.MarkOutputCacheDirty then
            Registry.Internal.MarkOutputCacheDirty(worker)
        end
    else
        worker.outputLedger = remainingEntries
    end

    return movedStacks, movedCount, movedWeight, leftoverCount
end

return Warehouse
