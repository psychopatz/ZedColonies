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

local function isRottenProvisionRejection(reason)
    local nutritionInternal = Nutrition and Nutrition.Internal or nil
    return tostring(reason or "") ~= ""
        and nutritionInternal
        and tostring(reason) == tostring(nutritionInternal.ROTTEN_PROVISION_MESSAGE or "")
end

local function syncRottenProvisionNotice(player, rottenCount)
    if rottenCount <= 0 then
        return
    end

    Internal.syncNotice(
        player,
        "Rotten items cannot be used as colony provisions. Rejected " .. tostring(rottenCount) .. " item" .. (rottenCount == 1 and "" or "s") .. ".",
        "error",
        true
    )
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

    local eligibleCount = 0
    local movedCount = 0
    local blockedCount = 0
    local rottenCount = 0
    for _, itemID in ipairs(itemIDs) do
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local entry, reason = Nutrition.BuildEntryFromItem(invItem)
            if entry then
                eligibleCount = eligibleCount + 1
                if Registry.AddNutritionEntry(worker, entry) then
                    Internal.removeInventoryItem(invItem)
                    movedCount = movedCount + 1
                else
                    blockedCount = blockedCount + 1
                end
            elseif isRottenProvisionRejection(reason) then
                rottenCount = rottenCount + 1
            end
        end
    end

    if movedCount <= 0 and eligibleCount > 0 then
        Internal.syncNotice(player, "NPC inventory is full. No provisions could be deposited.", "error", true)
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    if movedCount <= 0 and eligibleCount <= 0 and rottenCount > 0 then
        syncRottenProvisionNotice(player, rottenCount)
        Shared.saveAndRefreshBasic(player, worker)
        return
    end

    if blockedCount > 0 then
        Internal.syncNotice(
            player,
            "NPC inventory is nearly full. " .. tostring(blockedCount) .. " provision item" .. (blockedCount == 1 and "" or "s") .. " could not be stored.",
            "error",
            true
        )
    end
    syncRottenProvisionNotice(player, rottenCount)

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
    local rottenCount = 0
    for _, itemID in ipairs(itemIDs) do
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local entry, reason = Nutrition.BuildEntryFromItem(invItem)
            if entry then
                eligibleCount = eligibleCount + 1
                if Warehouse.DepositProvisionEntry(owner, entry) then
                    Internal.removeInventoryItem(invItem)
                    movedCount = movedCount + 1
                else
                    blockedCount = blockedCount + 1
                end
            elseif isRottenProvisionRejection(reason) then
                rottenCount = rottenCount + 1
            end
        end
    end

    if movedCount <= 0 and eligibleCount > 0 then
        Internal.syncNotice(player, "Warehouse is full. No supplies could be stored.", "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    if movedCount <= 0 and eligibleCount <= 0 and rottenCount > 0 then
        syncRottenProvisionNotice(player, rottenCount)
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
    syncRottenProvisionNotice(player, rottenCount)

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
                    local outputEntry = Registry.Internal.BuildOutputEntryFromInventoryItem
                        and Registry.Internal.BuildOutputEntryFromInventoryItem(invItem)
                        or {
                            fullType = fullType,
                            qty = getInventoryItemQuantity(invItem)
                        }
                    local availableQty = math.max(1, tonumber(outputEntry and outputEntry.qty) or getInventoryItemQuantity(invItem))
                    local movedQty = Warehouse.DepositOutputEntry(owner, outputEntry)
                    if movedQty > 0 then
                        local container = invItem:getContainer()
                        Internal.removeInventoryItem(invItem)
                        if availableQty > movedQty and container then
                            local customData = Registry.Internal.BuildOutputAddItemCustomData
                                and Registry.Internal.BuildOutputAddItemCustomData(outputEntry)
                                or nil
                            if Internal.addInventoryItem then
                                Internal.addInventoryItem(container, fullType, availableQty - movedQty, customData)
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
