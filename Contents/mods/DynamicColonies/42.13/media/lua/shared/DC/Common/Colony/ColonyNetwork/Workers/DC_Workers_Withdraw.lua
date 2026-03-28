DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}

Network.Handlers = Network.Handlers or {}

local function getFirstAddedItem(items)
    if not items then
        return nil
    end

    local ok, size = pcall(function()
        return items:size()
    end)
    if not ok or size <= 0 then
        return nil
    end

    local itemOk, item = pcall(function()
        return items:get(0)
    end)
    return itemOk and item or nil
end

local function resolveGlobalFunction(path)
    local current = _G
    for part in string.gmatch(tostring(path or ""), "[^%.]+") do
        if type(current) ~= "table" then
            return nil
        end
        current = current[part]
        if current == nil then
            return nil
        end
    end

    return type(current) == "function" and current or nil
end

local function getOnBreakHandler(fullType)
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
    return resolveGlobalFunction(handlerPath)
end

local function materializeWithdrawnTool(player, inventory, entry)
    if not inventory or not entry or not entry.fullType then
        return false
    end

    local customData = DC_Colony.Registry.Internal.BuildEquipmentAddItemCustomData
        and DC_Colony.Registry.Internal.BuildEquipmentAddItemCustomData(entry)
        or nil
    local qty = math.max(1, math.floor(tonumber(entry.qty) or 1))
    local addedItems = Internal.addInventoryItem(inventory, entry.fullType, qty, customData)
    local item = getFirstAddedItem(addedItems)
    if not item then
        return false
    end

    local isBrokenEntry = entry.pendingVanillaBreak == true
        and Registry.Internal.IsEquipmentEntryUsable
        and not Registry.Internal.IsEquipmentEntryUsable(entry)
    if not isBrokenEntry then
        return true
    end

    local breakHandler = getOnBreakHandler(entry.fullType)
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

local function withdrawWorkerNutritionEntries(worker, inventory, indexes)
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

local function withdrawWarehouseNutritionEntries(ownerUsername, inventory, indexes)
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

local function withdrawWorkerToolEntries(player, worker, inventory, indexes)
    local moved = 0
    table.sort(indexes or {}, function(a, b)
        return (tonumber(a) or 0) > (tonumber(b) or 0)
    end)
    for _, index in ipairs(indexes or {}) do
        local entry = worker and worker.toolLedger and worker.toolLedger[index] or nil
        if entry and entry.fullType then
            if materializeWithdrawnTool(player, inventory, entry) then
                table.remove(worker.toolLedger, index)
                moved = moved + 1
            end
        end
    end
    if moved > 0 then
        DC_Colony.Registry.Internal.MarkToolCacheDirty(worker)
    end
    return moved
end

local function withdrawWarehouseToolEntries(player, ownerUsername, inventory, indexes)
    local moved = 0
    for _, entry in ipairs(Warehouse.TakeEquipmentEntries(ownerUsername, indexes) or {}) do
        if entry and entry.fullType then
            if materializeWithdrawnTool(player, inventory, entry) then
                moved = moved + math.max(1, tonumber(entry.qty) or 1)
            end
        end
    end
    return moved
end

local function withdrawWorkerOutputEntries(worker, inventory, indexes)
    local moved = 0
    table.sort(indexes or {}, function(a, b)
        return (tonumber(a) or 0) > (tonumber(b) or 0)
    end)
    for _, index in ipairs(indexes or {}) do
        local entry = worker and worker.outputLedger and worker.outputLedger[index] or nil
        if entry and entry.fullType and (tonumber(entry.qty) or 0) > 0 then
            Internal.addInventoryItem(
                inventory,
                entry.fullType,
                entry.qty,
                DC_Colony.Registry.Internal.BuildOutputAddItemCustomData and DC_Colony.Registry.Internal.BuildOutputAddItemCustomData(entry) or nil
            )
            table.remove(worker.outputLedger, index)
            moved = moved + 1
        end
    end
    if moved > 0 then
        DC_Colony.Registry.Internal.MarkOutputCacheDirty(worker)
    end
    return moved
end

local function withdrawWarehouseOutputEntries(ownerUsername, inventory, indexes)
    local moved = 0
    for _, entry in ipairs(Warehouse.TakeOutputEntries(ownerUsername, indexes) or {}) do
        if entry and entry.fullType and (tonumber(entry.qty) or 0) > 0 then
            Internal.addInventoryItem(
                inventory,
                entry.fullType,
                entry.qty,
                DC_Colony.Registry.Internal.BuildOutputAddItemCustomData and DC_Colony.Registry.Internal.BuildOutputAddItemCustomData(entry) or nil
            )
            moved = moved + 1
        end
    end
    return moved
end

Network.Handlers.CollectWorkerOutput = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    local collected = Registry.CollectOutput(worker)
    local inventory = player and player:getInventory() or nil
    if inventory then
        for _, entry in ipairs(collected) do
            if entry.fullType and (entry.qty or 0) > 0 then
                Internal.addInventoryItem(
                    inventory,
                    entry.fullType,
                    entry.qty,
                    DC_Colony.Registry.Internal.BuildOutputAddItemCustomData and DC_Colony.Registry.Internal.BuildOutputAddItemCustomData(entry) or nil
                )
            end
        end
    end

    Shared.saveAndRefreshBasic(player, worker)
end

Network.Handlers.CollectWarehouseOutput = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    local collected = Warehouse.CollectAllOutput(owner)
    local inventory = player and player:getInventory() or nil
    if inventory then
        for _, entry in ipairs(collected) do
            if entry.fullType and (entry.qty or 0) > 0 then
                Internal.addInventoryItem(
                    inventory,
                    entry.fullType,
                    entry.qty,
                    DC_Colony.Registry.Internal.BuildOutputAddItemCustomData and DC_Colony.Registry.Internal.BuildOutputAddItemCustomData(entry) or nil
                )
            end
        end
    end

    Shared.saveAndRefreshBasic(player, worker)
end

Network.Handlers.WithdrawWorkerSupplies = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local inventory = player and player:getInventory() or nil
    if not worker or not inventory then return end

    local moved = withdrawWorkerNutritionEntries(worker, inventory, Shared.normalizeLedgerIndexes(args))
    if moved <= 0 then return end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.WithdrawWarehouseSupplies = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local inventory = player and player:getInventory() or nil
    if not worker or not inventory then return end

    local moved = withdrawWarehouseNutritionEntries(owner, inventory, Shared.normalizeLedgerIndexes(args))
    if moved <= 0 then return end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.WithdrawWorkerTools = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local inventory = player and player:getInventory() or nil
    if not worker or not inventory then return end

    local moved = withdrawWorkerToolEntries(player, worker, inventory, Shared.normalizeLedgerIndexes(args))
    if moved <= 0 then return end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.WithdrawWarehouseTools = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local inventory = player and player:getInventory() or nil
    if not worker or not inventory then return end

    local moved = withdrawWarehouseToolEntries(player, owner, inventory, Shared.normalizeLedgerIndexes(args))
    if moved <= 0 then return end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.WithdrawWorkerOutput = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local inventory = player and player:getInventory() or nil
    if not worker or not inventory then return end

    local moved = withdrawWorkerOutputEntries(worker, inventory, Shared.normalizeLedgerIndexes(args))
    if moved <= 0 then return end

    Shared.saveAndRefreshBasic(player, worker)
end

Network.Handlers.WithdrawWarehouseOutput = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local inventory = player and player:getInventory() or nil
    if not worker or not inventory then return end

    local moved = withdrawWarehouseOutputEntries(owner, inventory, Shared.normalizeLedgerIndexes(args))
    if moved <= 0 then return end

    Shared.saveAndRefreshBasic(player, worker)
end

return Network
