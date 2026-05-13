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

local function rejectItem(rejected, itemID, reason)
    rejected[#rejected + 1] = {
        itemID = itemID,
        reason = tostring(reason or "rejected"),
    }
end

local function buildTransferMessage(targetLabel, movedCount, rejectedCount)
    if movedCount > 0 and rejectedCount > 0 then
        return "Stored " .. tostring(movedCount) .. " item" .. (movedCount == 1 and "" or "s")
            .. " in " .. tostring(targetLabel) .. "; " .. tostring(rejectedCount) .. " failed."
    end
    if movedCount > 0 then
        return "Stored " .. tostring(movedCount) .. " item" .. (movedCount == 1 and "" or "s")
            .. " in " .. tostring(targetLabel) .. "."
    end
    return tostring(rejectedCount) .. " item" .. (rejectedCount == 1 and "" or "s") .. " could not be stored."
end

local function consumeInventoryItemQuantity(invItem, quantity)
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

Network.Handlers.DepositWorkerSupplies = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        Shared.syncSupplyTransferResult(player, args, { message = "That worker could not be found.", rejected = {} })
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
                if Registry.AddNutritionEntry(worker, entry) then
                    Internal.removeInventoryItem(invItem)
                    movedCount = movedCount + 1
                    acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                else
                    blockedCount = blockedCount + 1
                    rejectItem(rejected, itemID, "capacity")
                end
            elseif isRottenProvisionRejection(reason) then
                rottenCount = rottenCount + 1
                rejectItem(rejected, itemID, "rotten")
            else
                rejectItem(rejected, itemID, "not_provision")
            end
        else
            rejectItem(rejected, itemID, "missing")
        end
    end
    Shared.releaseItemTransferLocks(reserved)
    Shared.syncSupplyTransferResult(player, args, {
        acceptedItemIDs = acceptedItemIDs,
        rejected = rejected,
        movedCount = movedCount,
        message = buildTransferMessage("NPC inventory", movedCount, #rejected),
    })

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

    Shared.saveAndRefreshSupplyTransfer(player, worker)
end

Network.Handlers.DepositWarehouseSupplies = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        Shared.syncSupplyTransferResult(player, args, { message = "That worker could not be found.", rejected = {} })
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
                    rejectItem(rejected, itemID, "capacity")
                end
            elseif isRottenProvisionRejection(reason) then
                rottenCount = rottenCount + 1
                rejectItem(rejected, itemID, "rotten")
            else
                rejectItem(rejected, itemID, "not_provision")
            end
        else
            rejectItem(rejected, itemID, "missing")
        end
    end
    Shared.releaseItemTransferLocks(reserved)
    Shared.syncSupplyTransferResult(player, args, {
        acceptedItemIDs = acceptedItemIDs,
        rejected = rejected,
        movedCount = movedCount,
        message = buildTransferMessage("warehouse", movedCount, #rejected),
    })

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

    Shared.saveAndRefreshSupplyTransfer(player, worker, true)
end

Network.Handlers.DepositWarehouseOutput = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        Shared.syncSupplyTransferResult(player, args, { message = "That worker could not be found.", rejected = {} })
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
                            rejectItem(rejected, itemID, "capacity")
                        end
                    else
                        rejectItem(rejected, itemID, "not_provision")
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
                        consumeInventoryItemQuantity(invItem, movedQty)
                        movedCount = movedCount + movedQty
                        acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                    else
                        blockedCount = blockedCount + 1
                        rejectItem(rejected, itemID, "capacity")
                    end
                end
            else
                rejectItem(rejected, itemID, "money")
            end
        else
            rejectItem(rejected, itemID, "missing")
        end
    end
    Shared.releaseItemTransferLocks(reserved)
    Shared.syncSupplyTransferResult(player, args, {
        acceptedItemIDs = acceptedItemIDs,
        rejected = rejected,
        movedCount = movedCount,
        message = buildTransferMessage("warehouse storage", movedCount, #rejected),
    })

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

    Shared.saveAndRefreshSupplyTransfer(player, worker, true)
end

return Network
