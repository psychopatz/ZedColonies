DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Withdraw = (Network.Workers or {}).Withdraw or {}

function Withdraw.getOnBreakHandler(fullType)
    if not fullType then
        return nil
    end

    local transient = Registry and Registry.Internal and Registry.Internal.CreateTransientInventoryItem
        and Registry.Internal.CreateTransientInventoryItem(fullType)
        or nil
    local scriptItem = transient and transient.getScriptItem and transient:getScriptItem()
        or (getScriptManager and getScriptManager():getItem(fullType))
        or nil
    local handlerPath = scriptItem and scriptItem.getOnBreak and scriptItem:getOnBreak() or nil
    if not handlerPath or tostring(handlerPath) == "" then
        return nil
    end

    pcall(require, "Items/OnBreak")
    return Withdraw.resolveGlobalFunction(handlerPath)
end

function Withdraw.materializeWithdrawnTool(player, inventory, entry)
    if not inventory or not entry or not entry.fullType then
        return false
    end

    local quantity = math.max(1, math.floor(tonumber(entry.qty) or 1))
    local customData = Registry.Internal.BuildEquipmentAddItemCustomData
        and Registry.Internal.BuildEquipmentAddItemCustomData(entry)
        or nil
    local addedItems = Internal.addInventoryItem(inventory, entry.fullType, quantity, customData)
    local item = Withdraw.getFirstAddedItem(addedItems)
    if not item then
        return false
    end

    local isBrokenEntry = entry.pendingVanillaBreak == true
        and Registry.Internal.IsEquipmentEntryUsable
        and not Registry.Internal.IsEquipmentEntryUsable(entry)
    if not isBrokenEntry then
        return true
    end

    local breakHandler = Withdraw.getOnBreakHandler(entry.fullType)
    if not breakHandler then
        return true
    end

    local ok = pcall(breakHandler, item, player)
    if ok then
        return true
    end

    if isServer() and item.syncItemFields then
        item:syncItemFields()
    end
    return true
end

function Withdraw.withdrawWorkerToolEntries(player, worker, inventory, indexes)
    local moved = 0
    table.sort(indexes or {}, function(a, b)
        return (tonumber(a) or 0) > (tonumber(b) or 0)
    end)
    for _, index in ipairs(indexes or {}) do
        local entry = worker and worker.toolLedger and worker.toolLedger[index] or nil
        if entry and entry.fullType then
            if Withdraw.materializeWithdrawnTool(player, inventory, entry) then
                table.remove(worker.toolLedger, index)
                moved = moved + math.max(1, math.floor(tonumber(entry.qty) or 1))
            end
        end
    end
    if moved > 0 then
        DC_Colony.Registry.Internal.MarkToolCacheDirty(worker)
    end
    return moved
end

function Withdraw.withdrawWarehouseToolEntries(player, ownerUsername, inventory, indexes)
    local moved = 0
    for _, entry in ipairs(Warehouse.TakeEquipmentEntries(ownerUsername, indexes) or {}) do
        if entry and entry.fullType then
            if Withdraw.materializeWithdrawnTool(player, inventory, entry) then
                moved = moved + math.max(1, math.floor(tonumber(entry.qty) or 1))
            end
        end
    end
    return moved
end

return Withdraw