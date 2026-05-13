DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}
local Deposit = Network.Workers.Deposit or {}

Network.Workers.Deposit = Deposit
Deposit.FlavorText = DC_Colony.Network.WorkersDepositFlavorText or {}

function Deposit.getInventoryItemQuantity(item)
    if not item then
        return 0
    end

    local count = item.getCount and item:getCount() or nil
    count = math.floor(tonumber(count) or 0)
    if count > 0 then
        return count
    end

    return 1
end

function Deposit.rejectItem(rejected, itemID, reason)
    rejected[#rejected + 1] = {
        itemID = itemID,
        reason = tostring(reason or "rejected"),
    }
end

function Deposit.buildTransferMessage(targetLabel, movedCount, rejectedCount)
    local FlavorText = Deposit.FlavorText or {}
    if movedCount > 0 and rejectedCount > 0 then
        return string.format(
            tostring(FlavorText.transferStoredAndRejected or "Stored %s item%s in %s; %s failed."),
            tostring(movedCount),
            movedCount == 1 and "" or "s",
            tostring(targetLabel),
            tostring(rejectedCount)
        )
    end
    if movedCount > 0 then
        return string.format(
            tostring(FlavorText.transferStored or "Stored %s item%s in %s."),
            tostring(movedCount),
            movedCount == 1 and "" or "s",
            tostring(targetLabel)
        )
    end
    return string.format(
        tostring(FlavorText.transferRejected or "%s item%s could not be stored."),
        tostring(rejectedCount),
        rejectedCount == 1 and "" or "s"
    )
end

function Deposit.consumeInventoryItemQuantity(invItem, quantity)
    local removeInventoryItemUnits = Internal.removeInventoryItemUnits
    if removeInventoryItemUnits then
        return removeInventoryItemUnits(invItem, quantity)
    end

    if Internal.removeInventoryItem then
        Internal.removeInventoryItem(invItem)
        return math.max(0, math.floor(tonumber(quantity) or 0))
    end

    return 0
end

function Deposit.getWorkerContext(player, args)
    if not args or not args.workerID then
        return nil, nil
    end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        Shared.syncSupplyTransferResult(player, args, {
            message = tostring(Deposit.FlavorText.workerNotFound or "That worker could not be found."),
            rejected = {},
        })
        return owner, nil
    end

    return owner, worker
end

return Deposit