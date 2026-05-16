DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local AbstractInventory = DC_Colony.AbstractInventory
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}
local Withdraw = (Network.Workers or {}).Withdraw or {}

local function getOutputCustomData(entry)
    return Registry.Internal.BuildOutputAddItemCustomData
        and Registry.Internal.BuildOutputAddItemCustomData(entry)
        or nil
end

function Withdraw.withdrawWorkerOutputEntries(worker, inventory, indexes)
    local moved = 0
    table.sort(indexes or {}, function(a, b)
        return (tonumber(a) or 0) > (tonumber(b) or 0)
    end)
    for _, index in ipairs(indexes or {}) do
        local entry = worker and worker.outputLedger and worker.outputLedger[index] or nil
        if entry and entry.fullType and (tonumber(entry.qty) or 0) > 0 then
            Internal.addInventoryItem(inventory, entry.fullType, entry.qty, getOutputCustomData(entry))
            table.remove(worker.outputLedger, index)
            moved = moved + 1
        end
    end
    if moved > 0 then
        DC_Colony.Registry.Internal.MarkOutputCacheDirty(worker)
    end
    return moved
end

function Withdraw.withdrawWarehouseOutputEntries(ownerUsername, inventory, indexes)
    local moved = 0
    for _, entry in ipairs(Warehouse.TakeOutputEntries(ownerUsername, indexes) or {}) do
        if entry and entry.fullType and (tonumber(entry.qty) or 0) > 0 then
            Internal.addInventoryItem(inventory, entry.fullType, entry.qty, getOutputCustomData(entry))
            moved = moved + 1
        end
    end
    return moved
end

function Withdraw.withdrawWarehouseInventoryEntries(ownerUsername, inventory, requests)
    local moved = 0
    for _, request in ipairs(requests or {}) do
        local requestKind = tostring(request and request.kind or "")
        if requestKind == "inventory" then
            local fullType = tostring(request and request.fullType or "")
            local requestedQty = math.max(0, math.floor(tonumber(request and request.qty) or 0))
            if fullType ~= "" and requestedQty > 0 then
                local takenQty = AbstractInventory and AbstractInventory.TakeItemStock
                    and AbstractInventory.TakeItemStock(ownerUsername, fullType, requestedQty)
                    or 0
                if takenQty > 0 then
                    Internal.addInventoryItem(inventory, fullType, takenQty)
                    moved = moved + takenQty
                end
            end
        end
    end
    return moved
end

function Withdraw.collectWorkerOutput(player, worker)
    local collected = Registry.CollectOutput(worker)
    local inventory = player and player:getInventory() or nil
    if not inventory then
        return
    end

    for _, entry in ipairs(collected) do
        if entry.fullType and (entry.qty or 0) > 0 then
            Internal.addInventoryItem(inventory, entry.fullType, entry.qty, getOutputCustomData(entry))
        end
    end
end

function Withdraw.collectWarehouseOutput(player, owner)
    local collected = Warehouse.CollectAllOutput(owner)
    local inventory = player and player:getInventory() or nil
    if not inventory then
        return
    end

    for _, entry in ipairs(collected) do
        if entry.fullType and (entry.qty or 0) > 0 then
            Internal.addInventoryItem(inventory, entry.fullType, entry.qty, getOutputCustomData(entry))
        end
    end
end

Network.Handlers = Network.Handlers or {}

Network.Handlers.CollectWorkerOutput = function(player, args)
    local _, worker = Withdraw.getWorkerContext(player, args)
    if not worker then
        return
    end

    Withdraw.collectWorkerOutput(player, worker)
    Shared.saveAndRefreshBasic(player, worker)
end

Network.Handlers.CollectWarehouseOutput = function(player, args)
    local owner, worker = Withdraw.getWorkerContext(player, args)
    if not worker then
        return
    end

    Withdraw.collectWarehouseOutput(player, owner)
    Shared.saveAndRefreshBasic(player, worker)
end

return Withdraw
