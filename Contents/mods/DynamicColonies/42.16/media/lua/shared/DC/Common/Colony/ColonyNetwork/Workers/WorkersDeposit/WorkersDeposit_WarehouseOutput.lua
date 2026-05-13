DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Nutrition = DC_Colony.Nutrition
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}
local Deposit = Network.Workers.Deposit or {}
local FlavorText = Deposit.FlavorText or {}

Network.Handlers = Network.Handlers or {}

Network.Handlers.DepositWarehouseOutput = function(player, args)
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
    for _, lock in ipairs(reserved) do
        local itemID = lock.itemID
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local fullType = invItem:getFullType()
            if fullType ~= "Base.Money" and fullType ~= "Base.MoneyBundle" then
                if Config.IsMedicalProvisionFullType and Config.IsMedicalProvisionFullType(fullType) then
                    local provisionEntry = Nutrition.BuildEntryFromItem(invItem)
                    if provisionEntry then
                        eligibleCount = eligibleCount + 1
                        if Warehouse.DepositProvisionEntry(owner, provisionEntry) then
                            Internal.removeInventoryItem(invItem)
                            movedCount = movedCount + 1
                            acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                        else
                            blockedCount = blockedCount + 1
                            Deposit.rejectItem(rejected, itemID, "capacity")
                        end
                    else
                        Deposit.rejectItem(rejected, itemID, "not_provision")
                    end
                else
                    eligibleCount = eligibleCount + 1
                    local outputEntry = Registry.Internal.BuildOutputEntryFromInventoryItem
                        and Registry.Internal.BuildOutputEntryFromInventoryItem(invItem)
                        or {
                            fullType = fullType,
                            qty = Deposit.getInventoryItemQuantity(invItem)
                        }
                    local movedQty = Warehouse.DepositOutputEntry(owner, outputEntry)
                    if movedQty > 0 then
                        Deposit.consumeInventoryItemQuantity(invItem, movedQty)
                        movedCount = movedCount + movedQty
                        acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                    else
                        blockedCount = blockedCount + 1
                        Deposit.rejectItem(rejected, itemID, "capacity")
                    end
                end
            else
                Deposit.rejectItem(rejected, itemID, "money")
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
        message = Deposit.buildTransferMessage(tostring(FlavorText.warehouseStorageLabel or "warehouse storage"), movedCount, #rejected),
    })

    if movedCount <= 0 then
        if eligibleCount <= 0 then
            Internal.syncNotice(player, tostring(FlavorText.warehouseStorageNoEligible or "No eligible storage items could be stored from that selection."), "error")
        else
            Internal.syncNotice(player, tostring(FlavorText.warehouseStorageFull or "Warehouse storage is full. No items could be stored."), "error", true)
        end
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    if blockedCount > 0 then
        Internal.syncNotice(
            player,
            string.format(
                tostring(FlavorText.warehouseStorageNearlyFull or "Warehouse is nearly full. %s storage item%s could not be stored."),
                tostring(blockedCount),
                blockedCount == 1 and "" or "s"
            ),
            "error",
            true
        )
    end

    Shared.saveAndRefreshSupplyTransfer(player, worker, true)
end

return Network