DT_Labour = DT_Labour or {}
DT_Labour.Network = DT_Labour.Network or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry
local Sites = DT_Labour.Sites
local Warehouse = DT_Labour.Warehouse
local Network = DT_Labour.Network
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
    if not Config.IsLabourToolFullType or not Config.IsLabourToolFullType(fullType) then return end

    Registry.AddToolEntry(worker, {
        fullType = fullType,
        displayName = invItem:getDisplayName(),
        tags = tags
    })
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
    if not Config.IsLabourToolFullType or not Config.IsLabourToolFullType(fullType) then return end

    local stored = Warehouse.DepositEquipmentEntry(owner, {
        fullType = fullType,
        displayName = invItem:getDisplayName(),
        tags = tags
    })
    if not stored then
        Internal.syncNotice(player, "Warehouse is full. No space for that equipment.", "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    Internal.removeInventoryItem(invItem)
    Shared.saveAndRefreshProcessed(player, worker, true)
end

return Network
