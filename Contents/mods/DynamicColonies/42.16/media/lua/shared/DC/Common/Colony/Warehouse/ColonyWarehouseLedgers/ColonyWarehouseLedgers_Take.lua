DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Ledgers = Internal.Ledgers or {}

Internal.Ledgers = Ledgers

function Ledgers.TakeEntries(ledger, indexes)
    local entries = {}
    table.sort(indexes or {}, function(a, b)
        return a > b
    end)

    for _, index in ipairs(indexes or {}) do
        local normalized = math.floor(tonumber(index) or 0)
        local entry = ledger and ledger[normalized] or nil
        if entry then
            entries[#entries + 1] = Registry.Internal.CopyShallow(entry)
            table.remove(ledger, normalized)
        end
    end

    return entries
end

function Warehouse.TakeProvisionEntries(ownerUsername, indexes)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local entries = Ledgers.TakeEntries(warehouse.ledgers.provisions, indexes)
    if #entries > 0 then
        Warehouse.TouchItemsVersion(ownerUsername)
        Warehouse.TouchSummaryVersion(ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return entries
end

function Warehouse.TakeEquipmentEntries(ownerUsername, indexes)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local entries = Ledgers.TakeEntries(warehouse.ledgers.equipment, indexes)
    if #entries > 0 then
        Warehouse.TouchItemsVersion(ownerUsername)
        Warehouse.TouchSummaryVersion(ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return entries
end

function Warehouse.TakeOutputEntries(ownerUsername, indexes)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local entries = Ledgers.TakeEntries(warehouse.ledgers.output, indexes)
    if #entries > 0 then
        Warehouse.TouchItemsVersion(ownerUsername)
        Warehouse.TouchSummaryVersion(ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return entries
end

function Warehouse.CollectAllOutput(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local entries = Internal.CopyArray(warehouse.ledgers.output)
    warehouse.ledgers.output = {}
    if #entries > 0 then
        Warehouse.TouchItemsVersion(ownerUsername)
        Warehouse.TouchSummaryVersion(ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return entries
end

return Warehouse