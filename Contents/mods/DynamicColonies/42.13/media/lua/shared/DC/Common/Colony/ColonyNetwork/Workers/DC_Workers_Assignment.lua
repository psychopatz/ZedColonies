DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Sites = DC_Colony.Sites
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}

Network.Handlers = Network.Handlers or {}

Network.Handlers.AssignWorkerSite = function(player, args)
    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    local x = args.x or (player and player:getX()) or nil
    local y = args.y or (player and player:getY()) or nil
    local z = args.z or (player and player:getZ()) or 0
    Sites.AssignSiteForWorker(worker, x, y, z, args.radius)
    if worker.homeX == nil or worker.homeY == nil then
        Registry.SetWorkerHome(worker, player and player:getX() or x, player and player:getY() or y, player and player:getZ() or z)
    end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.AssignWorkerToolset = function(player, args)
    if not args or not args.workerID or not args.itemID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local invItem = Internal.getInventoryItemByID(player, args.itemID)
    if not worker or not invItem then return end

    local fullType = invItem:getFullType()
    local tags = Config.GetItemCombinedTags and Config.GetItemCombinedTags(fullType) or Config.FindItemTags(fullType)
    local isRequiredEquipment = Config.IsRequiredEquipmentFullType and Config.IsRequiredEquipmentFullType(fullType, worker.jobType)
    if not isRequiredEquipment then return end

    local toolEntry = Registry.Internal.BuildEquipmentEntryFromInventoryItem and Registry.Internal.BuildEquipmentEntryFromInventoryItem(invItem, invItem:getDisplayName()) or {
        fullType = fullType,
        displayName = invItem:getDisplayName(),
        tags = tags
    }
    if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry) then
        Internal.syncNotice(player, "That tool is broken or empty and cannot be assigned.", "error", true)
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    local stored = Registry.AddToolEntry(worker, toolEntry)
    if not stored then
        Internal.syncNotice(player, "NPC inventory is full. No space for that equipment.", "error", true)
        Shared.saveAndRefreshBasic(player, worker)
        return
    end
    Internal.removeInventoryItem(invItem)

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.AssignWarehouseToolset = function(player, args)
    if not args or not args.workerID or not args.itemID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local invItem = Internal.getInventoryItemByID(player, args.itemID)
    if not worker or not invItem then return end

    local fullType = invItem:getFullType()
    local tags = Config.GetItemCombinedTags and Config.GetItemCombinedTags(fullType) or Config.FindItemTags(fullType)
    local isRequiredEquipment = Config.IsRequiredEquipmentFullType and Config.IsRequiredEquipmentFullType(fullType, worker.jobType)
    if not isRequiredEquipment then return end

    local toolEntry = Registry.Internal.BuildEquipmentEntryFromInventoryItem and Registry.Internal.BuildEquipmentEntryFromInventoryItem(invItem, invItem:getDisplayName()) or {
        fullType = fullType,
        displayName = invItem:getDisplayName(),
        tags = tags
    }
    if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry) then
        Internal.syncNotice(player, "That tool is broken or empty and cannot be assigned.", "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    local stored = Warehouse.DepositEquipmentEntry(owner, toolEntry)
    if not stored then
        Internal.syncNotice(player, "Warehouse is full. No space for that equipment.", "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    Internal.removeInventoryItem(invItem)
    Shared.saveAndRefreshProcessed(player, worker, true)
end

return Network
