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

local function buildInventoryToolEntry(invItem)
    local fullType = invItem and invItem.getFullType and invItem:getFullType() or nil
    return Registry.Internal.BuildEquipmentEntryFromInventoryItem and Registry.Internal.BuildEquipmentEntryFromInventoryItem(invItem, invItem:getDisplayName()) or {
        fullType = fullType,
        displayName = invItem and invItem.getDisplayName and invItem:getDisplayName() or fullType,
        tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(fullType)) or Config.FindItemTags(fullType)
    }
end

local function getAmmoTypeForWeapon(fullType)
    local key = tostring(fullType or "")
    if key == "" or not getScriptManager then
        return nil
    end
    local scriptItem = getScriptManager():getItem(key)
    local ammoType = scriptItem and scriptItem.getAmmoType and scriptItem:getAmmoType() or nil
    ammoType = tostring(ammoType or "")
    return ammoType ~= "" and ammoType or nil
end

local function getWorkerRangedAmmoType(worker)
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if tostring(entry and entry.assignedRequirementKey or "") == "Colony.Combat.Ranged" then
            return getAmmoTypeForWeapon(entry.fullType)
        end
    end
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(entry and entry.fullType, "Colony.Combat.Ranged", worker) then
            return getAmmoTypeForWeapon(entry.fullType)
        end
    end
    return nil
end

local function itemMatchesWorkerRangedAmmo(worker, fullType)
    local ammoType = tostring(getWorkerRangedAmmoType(worker) or "")
    local itemType = tostring(fullType or "")
    if ammoType == "" or itemType == "" then
        return false
    end
    return itemType == ammoType or itemType == ammoType .. "Box" or itemType:gsub("Box$", "") == ammoType
end

local function canAssignRequirement(worker, fullType, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "Colony.Combat.Ammo" then
        return itemMatchesWorkerRangedAmmo(worker, fullType)
    end
    if targetKey ~= "" then
        return Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(fullType, targetKey, worker)
    end

    return Config.IsRequiredEquipmentFullTypeForWorker
        and Config.IsRequiredEquipmentFullTypeForWorker(fullType, worker)
        or (Config.IsRequiredEquipmentFullType and Config.IsRequiredEquipmentFullType(fullType, worker and worker.jobType))
end

local function storeWorkerToolEntry(worker, toolEntry, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey ~= "" and Registry.AddToolEntryForRequirement then
        return Registry.AddToolEntryForRequirement(worker, toolEntry, targetKey)
    end

    return Registry.AddToolEntry(worker, toolEntry)
end

local function getRequirementLabel(requirementKey)
    local definition = Config.GetEquipmentRequirementDefinition and Config.GetEquipmentRequirementDefinition(requirementKey) or nil
    return tostring(definition and definition.label or requirementKey or "the selected requirement")
end

local function formatWeight(value)
    return string.format("%.2f", math.max(0, tonumber(value) or 0))
end

local function getEquipmentEntryWeight(entry)
    local fullType = entry and entry.fullType
    if not fullType then
        return 0
    end
    local qty = math.max(1, tonumber(entry and entry.qty) or 1)
    return math.max(0, tonumber(Config.GetItemWeight and Config.GetItemWeight(fullType)) or 0) * qty
end

local function getRequirementEntry(worker, requirementKey)
    local targetKey = tostring(requirementKey or "")
    if targetKey == "" then
        return nil
    end

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if tostring(entry and entry.assignedRequirementKey or "") == targetKey then
            return entry
        end
    end

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if Config.ItemMatchesWorkerEquipmentRequirement
            and Config.ItemMatchesWorkerEquipmentRequirement(entry and entry.fullType, targetKey, worker) then
            return entry
        end
    end

    return nil
end

local function buildWorkerCapacityDetail(worker, toolEntry, requirementKey)
    local itemWeight = getEquipmentEntryWeight(toolEntry)
    local state = Registry.GetInventoryWeightState and Registry.GetInventoryWeightState(worker) or nil
    local remaining = math.max(0, tonumber(state and state.remainingWeight) or 0)
    local replacingEntry = getRequirementEntry(worker, requirementKey)
    local replacingWeight = getEquipmentEntryWeight(replacingEntry)
    local adjustedRemaining = replacingEntry and (remaining + replacingWeight) or remaining
    if itemWeight <= 0 then
        return nil
    end
    return "NPC inventory does not have enough carry capacity (item weight "
        .. formatWeight(itemWeight) .. ", remaining " .. formatWeight(adjustedRemaining) .. ")"
end

local function buildWarehouseCapacityDetail(owner, toolEntry)
    local warehouse = Warehouse.GetOrCreate and Warehouse.GetOrCreate(owner) or nil
    local remaining = warehouse and Warehouse.GetRemainingCapacity and Warehouse.GetRemainingCapacity(warehouse) or 0
    local itemWeight = Warehouse.Internal and Warehouse.Internal.GetEntryWeight
        and Warehouse.Internal.GetEntryWeight(toolEntry and toolEntry.fullType, math.max(1, tonumber(toolEntry and toolEntry.qty) or 1))
        or getEquipmentEntryWeight(toolEntry)
    if itemWeight <= 0 then
        return nil
    end
    return "warehouse storage does not have enough capacity (item weight "
        .. formatWeight(itemWeight) .. ", remaining " .. formatWeight(remaining) .. ")"
end

local function rejectItem(rejected, itemID, reason, fullType, detailText)
    rejected[#rejected + 1] = {
        itemID = itemID,
        reason = tostring(reason or "rejected"),
        fullType = fullType and tostring(fullType) or nil,
        detailText = detailText and tostring(detailText) or nil,
    }
end

local function countRejectedReasons(rejected)
    local counts = {}
    local examples = {}
    local total = 0
    for _, entry in ipairs(rejected or {}) do
        local reason = tostring(entry and entry.reason or "rejected")
        counts[reason] = (counts[reason] or 0) + 1
        examples[reason] = examples[reason] or entry
        total = total + 1
    end
    return counts, total, examples
end

local function buildFailureReason(targetLabel, reason, requirementKey, example)
    local detailText = tostring(example and example.detailText or "")
    if detailText ~= "" then
        return detailText
    end

    local label = getRequirementLabel(requirementKey)
    if reason == "capacity" then
        if tostring(targetLabel or "") == "warehouse" then
            return "warehouse storage is full or the item exceeds remaining warehouse capacity"
        end
        return "NPC inventory is full or the item exceeds remaining carry capacity"
    end
    if reason == "broken" then
        return "the selected equipment is broken or unusable"
    end
    if reason == "not_required_equipment" then
        return "the selected item does not match the " .. label .. " requirement for this worker"
    end
    if reason == "missing" then
        return "the item is no longer in your inventory"
    end
    return "the item was rejected"
end

local function buildEquipmentTransferMessage(targetLabel, movedCount, rejected, requirementKey)
    local reasonCounts, rejectedCount, reasonExamples = countRejectedReasons(rejected)
    local targetText = tostring(targetLabel or "")
    local isWarehouse = targetText == "warehouse"
    local movedVerb = isWarehouse and "Stored" or "Assigned"
    local targetPhrase = isWarehouse and " in warehouse" or (" to " .. targetText)
    local nonePrefix = isWarehouse and "No equipment stored" or "No equipment assigned"
    local rejectedReasonText = nil
    if rejectedCount > 0 then
        local primaryReason = nil
        for reason, count in pairs(reasonCounts) do
            if count == rejectedCount then
                primaryReason = reason
                break
            end
        end

        if primaryReason then
            rejectedReasonText = buildFailureReason(targetLabel, primaryReason, requirementKey, reasonExamples[primaryReason])
        else
            local parts = {}
            for reason, count in pairs(reasonCounts) do
                parts[#parts + 1] = tostring(count) .. " " .. buildFailureReason(targetLabel, reason, requirementKey, reasonExamples[reason])
            end
            table.sort(parts)
            rejectedReasonText = table.concat(parts, "; ")
        end
    end

    if movedCount > 0 and rejectedCount > 0 then
        return movedVerb .. " " .. tostring(movedCount) .. " equipment item" .. (movedCount == 1 and "" or "s")
            .. targetPhrase .. "; " .. tostring(rejectedCount) .. " failed: " .. rejectedReasonText .. "."
    end
    if movedCount > 0 then
        return movedVerb .. " " .. tostring(movedCount) .. " equipment item" .. (movedCount == 1 and "" or "s")
            .. targetPhrase .. "."
    end
    if rejectedCount <= 0 then
        return "No equipment was selected."
    end

    return nonePrefix .. ": " .. rejectedReasonText .. "."
end

local function resolveWarehouseEquipmentIndexes(owner, args)
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
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    local requirementKey = args.requirementKey and tostring(args.requirementKey) or nil
    if not worker then
        Shared.syncSupplyTransferResult(player, args, { message = "That worker could not be found.", rejected = {} })
        return
    end

    local reserved, rejected = Shared.beginItemTransferLocks(player, Shared.normalizeItemIDs(args))
    local acceptedItemIDs = {}
    local movedCount = 0

    for _, lock in ipairs(reserved) do
        local itemID = lock.itemID
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local fullType = invItem:getFullType()
            if canAssignRequirement(worker, fullType, requirementKey) then
                local toolEntry = buildInventoryToolEntry(invItem)
                if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry) then
                    rejectItem(rejected, itemID, "broken", fullType)
                elseif storeWorkerToolEntry(worker, toolEntry, requirementKey) then
                    Internal.removeInventoryItem(invItem)
                    acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                    movedCount = movedCount + 1
                else
                    rejectItem(rejected, itemID, "capacity", fullType, buildWorkerCapacityDetail(worker, toolEntry, requirementKey))
                end
            else
                rejectItem(rejected, itemID, "not_required_equipment", fullType)
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
        message = buildEquipmentTransferMessage("NPC inventory", movedCount, rejected, requirementKey),
    })

    if movedCount > 0 then
        Shared.saveAndRefreshSupplyTransfer(player, worker)
    else
        if #rejected > 0 then
            Internal.syncNotice(player, buildEquipmentTransferMessage("NPC inventory", movedCount, rejected, requirementKey), "error", true)
        end
        Shared.saveAndRefreshBasic(player, worker)
    end
end

Network.Handlers.AssignWarehouseToolset = function(player, args)
    if not args or not args.workerID then return end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        Shared.syncSupplyTransferResult(player, args, { message = "That worker could not be found.", rejected = {} })
        return
    end

    local reserved, rejected = Shared.beginItemTransferLocks(player, Shared.normalizeItemIDs(args))
    local acceptedItemIDs = {}
    local movedCount = 0

    for _, lock in ipairs(reserved) do
        local itemID = lock.itemID
        local invItem = Internal.getInventoryItemByID(player, itemID)
        if invItem then
            local fullType = invItem:getFullType()
            local isRequiredEquipment = Config.IsRequiredEquipmentFullTypeForWorker
                and Config.IsRequiredEquipmentFullTypeForWorker(fullType, worker)
                or (Config.IsRequiredEquipmentFullType and Config.IsRequiredEquipmentFullType(fullType, worker.jobType))
            if isRequiredEquipment then
                local toolEntry = buildInventoryToolEntry(invItem)
                if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry) then
                    rejectItem(rejected, itemID, "broken", fullType)
                elseif Warehouse.DepositEquipmentEntry(owner, toolEntry) then
                    Internal.removeInventoryItem(invItem)
                    acceptedItemIDs[#acceptedItemIDs + 1] = itemID
                    movedCount = movedCount + 1
                else
                    rejectItem(rejected, itemID, "capacity", fullType, buildWarehouseCapacityDetail(owner, toolEntry))
                end
            else
                rejectItem(rejected, itemID, "not_required_equipment", fullType)
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
        message = buildEquipmentTransferMessage("warehouse", movedCount, rejected, nil),
    })

    if movedCount > 0 then
        Shared.saveAndRefreshSupplyTransfer(player, worker, true)
    else
        if #rejected > 0 then
            Internal.syncNotice(player, buildEquipmentTransferMessage("warehouse", movedCount, rejected, nil), "error", true)
        end
        Shared.saveAndRefreshBasic(player, worker, true)
    end
end

Network.Handlers.AssignWarehouseToolToWorker = function(player, args)
    if not args or not args.workerID or not args.ledgerIndex or not args.requirementKey then
        return
    end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        return
    end

    local requirementKey = tostring(args.requirementKey or "")
    if requirementKey == "" then
        return
    end

    local taken = Warehouse.TakeEquipmentEntries(owner, resolveWarehouseEquipmentIndexes(owner, args))
    local toolEntry = taken and taken[1] or nil
    if not toolEntry or not toolEntry.fullType then
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    local fullType = tostring(toolEntry.fullType or "")
    if fullType == ""
        or not canAssignRequirement(worker, fullType, requirementKey)
        or (Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(toolEntry)) then
        Warehouse.DepositEquipmentEntry(owner, toolEntry, true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    if not storeWorkerToolEntry(worker, toolEntry, requirementKey) then
        Warehouse.DepositEquipmentEntry(owner, toolEntry, true)
        Internal.syncNotice(player, "NPC inventory is full. No space for that equipment.", "error", true)
        Shared.saveAndRefreshBasic(player, worker, true)
        return
    end

    Shared.saveAndRefreshProcessed(player, worker, true)
end

Network.Handlers.SetWarehouseAutoEquipEnabled = function(player, args)
    local owner = Config.GetOwnerUsername(player)
    local enabled = args and args.enabled == true or false
    Warehouse.SetAutoEquipEnabled(owner, enabled)
    if Registry.Save then
        Registry.Save()
    end
    Internal.syncWarehouse(player, nil, true)
end

Network.Handlers.AutoEquipWorkerFromWarehouse = function(player, args)
    if not args or not args.workerID then
        return
    end

    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerForOwner(owner, args.workerID)
    if not worker then
        return
    end

    local added = Warehouse.RestockWorkerEquipment and Warehouse.RestockWorkerEquipment(worker, {
        includeOptional = true
    }) or 0
    Registry.RecalculateWorker(worker)
    Shared.saveAndRefreshBasic(player, worker, true)

    if added > 0 then
        Internal.syncNotice(player, "Auto-equipped " .. tostring(added) .. " warehouse item" .. (added == 1 and "" or "s") .. ".", "info", false)
    else
        Internal.syncNotice(player, "No matching warehouse equipment was available for this worker.", "info", false)
    end
end

return Network
