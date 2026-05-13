DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Withdraw = (Network.Workers or {}).Withdraw or {}

function Withdraw.withdrawWorkerNutritionEntries(worker, inventory, indexes)
    local moved = 0
    table.sort(indexes or {}, function(a, b)
        return (tonumber(a) or 0) > (tonumber(b) or 0)
    end)
    for _, index in ipairs(indexes or {}) do
        local entry = worker and worker.nutritionLedger and worker.nutritionLedger[index] or nil
        if entry and entry.fullType then
            Internal.addInventoryItem(inventory, entry.fullType, 1)
            table.remove(worker.nutritionLedger, index)
            moved = moved + 1
        end
    end
    if moved > 0 then
        DC_Colony.Registry.Internal.MarkNutritionCacheDirty(worker)
    end
    return moved
end

function Withdraw.withdrawWarehouseNutritionEntries(ownerUsername, inventory, indexes)
    local moved = 0
    for _, entry in ipairs(Warehouse.TakeProvisionEntries(ownerUsername, indexes) or {}) do
        if entry and entry.fullType then
            local qty = math.max(1, tonumber(entry.qty) or 1)
            Internal.addInventoryItem(inventory, entry.fullType, qty)
            moved = moved + qty
        end
    end
    return moved
end

return Withdraw