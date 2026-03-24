DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Nutrition = DC_Colony.Nutrition
local Warehouse = DC_Colony.Warehouse
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = (Network.Workers or {}).Shared or {}

Network.Handlers = Network.Handlers or {}

local function getInventoryItemQuantity(item)
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

Network.Handlers.DepositWorkerSupplies = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    local itemIDs = args.itemIDs or {}
    if args.itemID then
        itemIDs[#itemIDs + 1] = args.itemID
    end

    for _, itemID in ipairs(itemIDs) do
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local entry = Nutrition.BuildEntryFromItem(invItem)
            if entry then
                Registry.AddNutritionEntry(worker, entry)
                Internal.removeInventoryItem(invItem)
            end
        end
    end

    Shared.saveAndRefreshProcessed(player, worker)
end

Network.Handlers.DepositWarehouseSupplies = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    local itemIDs = args.itemIDs or {}
    if args.itemID then
        itemIDs[#itemIDs + 1] = args.itemID
    end

    local eligibleCount = 0
    local movedCount = 0
    local blockedCount = 0
    for _, itemID in ipairs(itemIDs) do
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local entry = Nutrition.BuildEntryFromItem(invItem)
            if entry then
                eligibleCount = eligibleCount + 1
                if Warehouse.DepositProvisionEntry(owner, entry) then
                    Internal.removeInventoryItem(invItem)
                    movedCount = movedCount + 1
                else
                    blockedCount = blockedCount + 1
                end
            end
        end
    end

    if movedCount <= 0 and eligibleCount > 0 then
        Internal.syncNotice(player, "Warehouse is full. No supplies could be stored.", "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    if blockedCount > 0 then
        Internal.syncNotice(
            player,
            "Warehouse is nearly full. " .. tostring(blockedCount) .. " supply item" .. (blockedCount == 1 and "" or "s") .. " could not be stored.",
            "error",
            true
        )
    end

    Shared.saveAndRefreshProcessed(player, worker, true)
end

Network.Handlers.DepositWarehouseOutput = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then return end

    local itemIDs = args.itemIDs or {}
    if args.itemID then
        itemIDs[#itemIDs + 1] = args.itemID
    end

    local eligibleCount = 0
    local movedCount = 0
    local blockedCount = 0
    for _, itemID in ipairs(itemIDs) do
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
                        else
                            blockedCount = blockedCount + 1
                        end
                    end
                else
                    eligibleCount = eligibleCount + 1
                    local availableQty = getInventoryItemQuantity(invItem)
                    local movedQty = Warehouse.DepositOutputEntry(owner, {
                        fullType = fullType,
                        qty = availableQty
                    })
                    if movedQty > 0 then
                        local container = invItem:getContainer()
                        Internal.removeInventoryItem(invItem)
                        if availableQty > movedQty and container then
                            if Internal.addInventoryItem then
                                Internal.addInventoryItem(container, fullType, availableQty - movedQty)
                            else
                                container:AddItems(fullType, availableQty - movedQty)
                            end
                        end
                        movedCount = movedCount + movedQty
                    else
                        blockedCount = blockedCount + 1
                    end
                end
            end
        end
    end

    if movedCount <= 0 then
        if eligibleCount <= 0 then
            Internal.syncNotice(player, "No eligible storage items could be stored from that selection.", "error")
        else
            Internal.syncNotice(player, "Warehouse storage is full. No items could be stored.", "error", true)
        end
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    if blockedCount > 0 then
        Internal.syncNotice(
            player,
            "Warehouse is nearly full. " .. tostring(blockedCount) .. " storage item" .. (blockedCount == 1 and "" or "s") .. " could not be stored.",
            "error",
            true
        )
    end

    Shared.saveAndRefreshProcessed(player, worker, true)
end

return Network
