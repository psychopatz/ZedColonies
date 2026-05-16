DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Network = DC_Colony.Network
local Shared = (Network.Workers or {}).Shared or {}
local Withdraw = (Network.Workers or {}).Withdraw or {}

Network.Handlers = Network.Handlers or {}

Network.Handlers.WithdrawWorkerSupplies = function(player, args)
    local _, worker, inventory = Withdraw.getWorkerInventoryContext(player, args)
    if not worker or not inventory then
        return
    end

    local moved = Withdraw.withdrawWorkerNutritionEntries(worker, inventory, Shared.normalizeLedgerIndexes(args))
    if moved <= 0 then
        return
    end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.WithdrawWarehouseSupplies = function(player, args)
    local owner, worker, inventory = Withdraw.getWorkerInventoryContext(player, args)
    if not worker or not inventory then
        return
    end

    local moved = Withdraw.withdrawWarehouseNutritionEntries(
        owner,
        inventory,
        Shared.normalizeLedgerIndexes(args),
        Shared.normalizeLedgerQuantities and Shared.normalizeLedgerQuantities(args) or nil
    )
    if moved <= 0 then
        return
    end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.WithdrawWorkerTools = function(player, args)
    local _, worker, inventory = Withdraw.getWorkerInventoryContext(player, args)
    if not worker or not inventory then
        return
    end

    local moved = Withdraw.withdrawWorkerToolEntries(player, worker, inventory, Shared.normalizeLedgerIndexes(args))
    if moved <= 0 then
        return
    end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.WithdrawWarehouseTools = function(player, args)
    local owner, worker, inventory = Withdraw.getWorkerInventoryContext(player, args)
    if not worker or not inventory then
        return
    end

    local moved = Withdraw.withdrawWarehouseToolEntries(
        player,
        owner,
        inventory,
        Shared.normalizeLedgerIndexes(args),
        Shared.normalizeLedgerQuantities and Shared.normalizeLedgerQuantities(args) or nil
    )
    if moved <= 0 then
        return
    end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.WithdrawWorkerOutput = function(player, args)
    local _, worker, inventory = Withdraw.getWorkerInventoryContext(player, args)
    if not worker or not inventory then
        return
    end

    local moved = Withdraw.withdrawWorkerOutputEntries(worker, inventory, Shared.normalizeLedgerIndexes(args))
    if moved <= 0 then
        return
    end

    Shared.saveAndRefreshBasic(player, worker)
end

Network.Handlers.WithdrawWarehouseOutput = function(player, args)
    local owner, worker, inventory = Withdraw.getWorkerInventoryContext(player, args)
    if not worker or not inventory then
        return
    end

    local moved = 0
    if type(args and args.inventoryRequests) == "table" and #(args.inventoryRequests or {}) > 0 then
        moved = Withdraw.withdrawWarehouseInventoryEntries(owner, inventory, args.inventoryRequests)
    else
        moved = Withdraw.withdrawWarehouseOutputEntries(owner, inventory, Shared.normalizeLedgerIndexes(args))
    end
    if moved <= 0 then
        return
    end

    Shared.saveAndRefreshBasic(player, worker, true)
end

return Withdraw
