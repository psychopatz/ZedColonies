DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Shared = (Network.Workers or {}).Shared or {}
local Equipment = (Network.Workers or {}).Equipment or {}

Network.Workers.Equipment = Equipment
Equipment.FlavorText = DC_Colony.Network.WorkersEquipmentFlavorText or {}

function Equipment.buildInventoryToolEntry(invItem)
    local fullType = invItem and invItem.getFullType and invItem:getFullType() or nil
    return Registry.Internal.BuildEquipmentEntryFromInventoryItem
        and Registry.Internal.BuildEquipmentEntryFromInventoryItem(invItem, invItem:getDisplayName())
        or {
            fullType = fullType,
            displayName = invItem and invItem.getDisplayName and invItem:getDisplayName() or fullType,
            tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(fullType)) or Config.FindItemTags(fullType)
        }
end

function Equipment.getWorkerContext(player, args)
    if not args or not args.workerID then
        return nil, nil
    end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    return owner, worker
end

function Equipment.syncWorkerNotFound(player, args)
    Shared.syncSupplyTransferResult(player, args, {
        message = tostring(Equipment.FlavorText.workerNotFound or "That worker could not be found."),
        rejected = {},
    })
end

function Equipment.resolveWarehouseEquipmentIndexes(owner, args)
    if args and args.entryID then
        local targetID = tostring(args.entryID or "")
        local warehouse = Warehouse.GetOwnerWarehouse(owner)
        for index, entry in ipairs(warehouse and warehouse.ledgers and warehouse.ledgers.equipment or {}) do
            if tostring(entry and entry.entryID or "") == targetID then
                return { index }
            end
        end
    end

    return Shared.normalizeLedgerIndexes(args)
end

return Equipment