DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Warehouse = DC_Colony.Warehouse
local Nutrition = DC_Colony.Nutrition
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}
local Deposit = Network.Workers.Deposit or {}
local FlavorText = Deposit.FlavorText or {}

Network.Handlers = Network.Handlers or {}

Network.Handlers.DepositWarehouseSupplies = function(player, args)
    if not args or not args.workerID then
        return
    end

    local owner, worker = Deposit.getWorkerContext(player, args)
    if not worker then
        return
    end

    local reserved, rejected = Shared.beginItemTransferLocks(player, Shared.normalizeItemIDs(args))
    local acceptedItemIDs = {}

    local eligibleCount = 0
    local movedCount = 0
    local blockedCount = 0
    local rottenCount = 0
    for _, lock in ipairs(reserved) do
        local itemID = lock.itemID
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local entry, reason = Nutrition.BuildEntryFromItem(invItem)
            if entry then
                eligibleCount = eligibleCount + 1
                if Warehouse.DepositProvisionEntry(owner, entry) then
                    Internal.removeInventoryItem(invItem)
                    movedCount = movedCount + 1
                    acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                else
                    blockedCount = blockedCount + 1
                    Deposit.rejectItem(rejected, itemID, "capacity")
                end
            elseif Deposit.isRottenProvisionRejection(reason) then
                rottenCount = rottenCount + 1
                Deposit.rejectItem(rejected, itemID, "rotten")
            else
                Deposit.rejectItem(rejected, itemID, "not_provision")
            end
        else
            Deposit.rejectItem(rejected, itemID, "missing")
        end
    end
    Shared.releaseItemTransferLocks(reserved)
    Shared.syncSupplyTransferResult(player, args, {
        acceptedItemIDs = acceptedItemIDs,
        rejected = rejected,
        movedCount = movedCount,
        message = Deposit.buildTransferMessage(tostring(FlavorText.warehouseLabel or "warehouse"), movedCount, #rejected),
    })

    if movedCount <= 0 and eligibleCount > 0 then
        Internal.syncNotice(player, tostring(FlavorText.warehouseFull or "Warehouse is full. No supplies could be stored."), "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    if movedCount <= 0 and eligibleCount <= 0 and rottenCount > 0 then
        Deposit.syncRottenProvisionNotice(player, rottenCount)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    if blockedCount > 0 then
        Internal.syncNotice(
            player,
            string.format(
                tostring(FlavorText.warehouseNearlyFull or "Warehouse is nearly full. %s supply item%s could not be stored."),
                tostring(blockedCount),
                blockedCount == 1 and "" or "s"
            ),
            "error",
            true
        )
    end
    Deposit.syncRottenProvisionNotice(player, rottenCount)

    Shared.saveAndRefreshSupplyTransfer(player, worker, true)
end

return Network