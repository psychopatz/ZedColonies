DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}
local Equipment = (Network.Workers or {}).Equipment or {}

Network.Handlers = Network.Handlers or {}

Network.Handlers.AssignWorkerToolset = function(player, args)
    if not args or not args.workerID then
        return
    end

    local owner, worker = Equipment.getWorkerContext(player, args)
    local requirementKey = args.requirementKey and tostring(args.requirementKey) or nil
    if not worker then
        Equipment.syncWorkerNotFound(player, args)
        return
    end

    local reserved, rejected = Shared.beginItemTransferLocks(player, Shared.normalizeItemIDs(args))
    local acceptedItemIDs = {}
    local movedCount = 0
    local targetLabel = tostring(Equipment.FlavorText.npcInventoryLabel or "NPC inventory")

    for _, lock in ipairs(reserved) do
        local itemID = lock.itemID
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local fullType = invItem:getFullType()
            local effectiveRequirementKey = Equipment.resolveAssignmentRequirementKey(worker, fullType, requirementKey)
            if Equipment.canAssignRequirement(worker, fullType, effectiveRequirementKey) then
                local toolEntry = Equipment.buildInventoryToolEntry(invItem)
                if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry) then
                    Equipment.rejectItem(rejected, itemID, "broken", fullType)
                elseif Equipment.storeWorkerToolEntry(worker, toolEntry, effectiveRequirementKey) then
                    Internal.removeInventoryItem(invItem)
                    acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                    movedCount = movedCount + 1
                else
                    Equipment.rejectItem(rejected, itemID, "capacity", fullType, Equipment.buildWorkerCapacityDetail(worker, toolEntry, effectiveRequirementKey))
                end
            else
                Equipment.rejectItem(rejected, itemID, "not_required_equipment", fullType)
            end
        else
            Equipment.rejectItem(rejected, itemID, "missing")
        end
    end
    Shared.releaseItemTransferLocks(reserved)
    Shared.syncSupplyTransferResult(player, args, {
        acceptedItemIDs = acceptedItemIDs,
        rejected = rejected,
        movedCount = movedCount,
        message = Equipment.buildEquipmentTransferMessage(targetLabel, movedCount, rejected, requirementKey),
    })

    if movedCount > 0 then
        Shared.saveAndRefreshSupplyTransfer(player, worker)
    else
        if #rejected > 0 then
            Internal.syncNotice(player, Equipment.buildEquipmentTransferMessage(targetLabel, movedCount, rejected, requirementKey), "error", true)
        end
        Shared.saveAndRefreshBasic(player, worker)
    end
end

Network.Handlers.AssignWarehouseToolset = function(player, args)
    if not args or not args.workerID then
        return
    end

    local owner, worker = Equipment.getWorkerContext(player, args)
    if not worker then
        Equipment.syncWorkerNotFound(player, args)
        return
    end

    local reserved, rejected = Shared.beginItemTransferLocks(player, Shared.normalizeItemIDs(args))
    local acceptedItemIDs = {}
    local movedCount = 0
    local targetLabel = tostring(Equipment.FlavorText.warehouseLabel or "warehouse")

    for _, lock in ipairs(reserved) do
        local itemID = lock.itemID
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local fullType = invItem:getFullType()
            local isRequiredEquipment = Config.IsRequiredEquipmentFullTypeForWorker
                and Config.IsRequiredEquipmentFullTypeForWorker(fullType, worker)
                or (Config.IsRequiredEquipmentFullType and Config.IsRequiredEquipmentFullType(fullType, worker.jobType))
            if isRequiredEquipment then
                local toolEntry = Equipment.buildInventoryToolEntry(invItem)
                if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry) then
                    Equipment.rejectItem(rejected, itemID, "broken", fullType)
                elseif Warehouse.DepositEquipmentEntry(owner, toolEntry) then
                    Internal.removeInventoryItem(invItem)
                    acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                    movedCount = movedCount + 1
                else
                    Equipment.rejectItem(rejected, itemID, "capacity", fullType, Equipment.buildWarehouseCapacityDetail(owner, toolEntry))
                end
            else
                Equipment.rejectItem(rejected, itemID, "not_required_equipment", fullType)
            end
        else
            Equipment.rejectItem(rejected, itemID, "missing")
        end
    end
    Shared.releaseItemTransferLocks(reserved)
    Shared.syncSupplyTransferResult(player, args, {
        acceptedItemIDs = acceptedItemIDs,
        rejected = rejected,
        movedCount = movedCount,
        message = Equipment.buildEquipmentTransferMessage(targetLabel, movedCount, rejected, nil),
    })

    if movedCount > 0 then
        Shared.saveAndRefreshSupplyTransfer(player, worker, true)
    else
        if #rejected > 0 then
            Internal.syncNotice(player, Equipment.buildEquipmentTransferMessage(targetLabel, movedCount, rejected, nil), "error", true)
        end
        Shared.saveAndRefreshBasic(player, worker, true)
    end
end

Network.Handlers.AssignWarehouseToolToWorker = function(player, args)
    if not args or not args.workerID or not args.ledgerIndex or not args.requirementKey then
        return
    end

    local owner, worker = Equipment.getWorkerContext(player, args)
    if not worker then
        return
    end

    local requirementKey = tostring(args.requirementKey or "")
    if requirementKey == "" then
        return
    end

    local requestedQuantities = nil
    if args and args.ledgerIndex then
        requestedQuantities = {
            [math.floor(tonumber(args.ledgerIndex) or 0)] = math.max(1, math.floor(tonumber(args.requestedQty) or 1))
        }
    end

    local taken = Warehouse.TakeEquipmentEntries(owner, Equipment.resolveWarehouseEquipmentIndexes(owner, args), requestedQuantities)
    local toolEntry = taken and taken[1] or nil
    if not toolEntry or not toolEntry.fullType then
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    local fullType = tostring(toolEntry.fullType or "")
    if fullType == ""
        or not Equipment.canAssignRequirement(worker, fullType, requirementKey)
        or (Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry)) then
        Warehouse.DepositEquipmentEntry(owner, toolEntry, true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    if not Equipment.storeWorkerToolEntry(worker, toolEntry, requirementKey) then
        Warehouse.DepositEquipmentEntry(owner, toolEntry, true)
        Internal.syncNotice(player, tostring(Equipment.FlavorText.npcNoSpace or "NPC inventory is full. No space for that equipment."), "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    Shared.saveAndRefreshProcessed(player, worker, true)
end

return Equipment
