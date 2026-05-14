DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}

Network.Internal = Internal

local function removeInventoryItem(item)
    if DynamicTrading and DynamicTrading.ServerHelpers and DynamicTrading.ServerHelpers.RemoveItem then
        DynamicTrading.ServerHelpers.RemoveItem(item)
        return
    end

    if not item then return end
    local container = item:getContainer()
    if container then
        container:DoRemoveItem(item)
    end
end

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

local function syncExistingInventoryItem(item)
    if not item then
        return
    end

    if isServer() and item.syncItemFields then
        item:syncItemFields()
    end
end

local function applyProvisionEntryState(item, customData)
    if not item or type(customData) ~= "table" then
        return
    end

    local caloriesRemaining = tonumber(customData.caloriesRemaining)
    local hydrationRemaining = tonumber(customData.hydrationRemaining)
    if caloriesRemaining == nil and hydrationRemaining == nil then
        return
    end

    local nutritionInternal = DC_Colony and DC_Colony.Nutrition and DC_Colony.Nutrition.Internal or nil
    local fullType = item.getFullType and item:getFullType() or nil
    local expectedCalories, expectedHydration, scriptItem = 0, 0, nil
    if nutritionInternal and nutritionInternal.GetExpectedStaticNutritionForFullType then
        expectedCalories, expectedHydration, scriptItem = nutritionInternal.GetExpectedStaticNutritionForFullType(fullType)
    end

    if caloriesRemaining ~= nil and item.setCalories then
        item:setCalories(math.max(0, caloriesRemaining))
    end

    if expectedCalories and expectedCalories > 0 and item.setHungChange and scriptItem and scriptItem.getHungerChange then
        local hungerChange = tonumber(scriptItem:getHungerChange()) or 0
        item:setHungChange(hungerChange * math.max(0, math.min(1, math.max(0, caloriesRemaining or expectedCalories) / expectedCalories)))
    end

    if expectedHydration and expectedHydration > 0 and item.setThirstChange and scriptItem and scriptItem.getThirstChange then
        local thirstChange = tonumber(scriptItem:getThirstChange()) or 0
        item:setThirstChange(thirstChange * math.max(0, math.min(1, math.max(0, hydrationRemaining or expectedHydration) / expectedHydration)))
    end
end

local function applyInventoryItemCustomData(item, customData)
    if not item or type(customData) ~= "table" then
        return
    end

    applyProvisionEntryState(item, customData)

    if DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal and DC_Colony.Registry.Internal.ApplyEquipmentEntryState then
        DC_Colony.Registry.Internal.ApplyEquipmentEntryState(item, customData)
    else
        if customData.condition ~= nil and item.getConditionMax and item:getConditionMax() > 0 then
            item:setCondition(math.max(0, math.min(item:getConditionMax(), math.floor(tonumber(customData.condition) or item:getConditionMax()))))
        end
        if customData.usedDelta ~= nil and item.IsDrainable and item:IsDrainable() then
            item:setUsedDelta(math.max(0, math.min(1, tonumber(customData.usedDelta) or 0)))
        end
        if customData.headCondition ~= nil and item.setHeadCondition and item.getHeadConditionMax then
            item:setHeadCondition(math.max(0, math.min(item:getHeadConditionMax(), math.floor(tonumber(customData.headCondition) or item:getHeadConditionMax()))))
        elseif customData.condition ~= nil and item.setHeadConditionFromCondition then
            pcall(function()
                item:setHeadConditionFromCondition(item)
            end)
        end
    end

    if customData.fluidAmount ~= nil and item.getFluidContainer and item:getFluidContainer() then
        item:getFluidContainer():setAmount(math.max(0, tonumber(customData.fluidAmount) or 0))
    end
end

local function removeInventoryItemUnits(item, count)
    local quantity = math.max(0, math.floor(tonumber(count) or 0))
    if quantity <= 0 or not item then
        return 0
    end

    local available = getInventoryItemQuantity(item)
    if available <= 0 then
        return 0
    end

    local removed = math.min(available, quantity)
    if removed >= available then
        removeInventoryItem(item)
        return removed
    end

    if item.setCount then
        item:setCount(available - removed)
        syncExistingInventoryItem(item)
        return removed
    end

    local remaining = removed
    while remaining > 0 and item and item:getContainer() do
        if item.Use then
            item:Use()
            remaining = remaining - 1
        else
            break
        end
    end

    if item and item:getContainer() then
        syncExistingInventoryItem(item)
    end
    return removed - remaining
end

local function addInventoryItem(container, fullType, count, customData)
    if DynamicTrading and DynamicTrading.ServerHelpers then
        if customData and DynamicTrading.ServerHelpers.AddItemWithCondition then
            local items = DynamicTrading.ServerHelpers.AddItemWithCondition(container, fullType, count, customData)
            if items then
                for i = 0, items:size() - 1 do
                    local item = items:get(i)
                    applyInventoryItemCustomData(item, customData)
                    if isServer() and item.syncItemFields then
                        item:syncItemFields()
                    end
                end
            end
            return items
        end
        if DynamicTrading.ServerHelpers.AddItem then
            local items = DynamicTrading.ServerHelpers.AddItem(container, fullType, count)
            if items then
                for i = 0, items:size() - 1 do
                    local item = items:get(i)
                    applyInventoryItemCustomData(item, customData)
                    if isServer() and item.syncItemFields then
                        item:syncItemFields()
                    end
                end
            end
            return items
        end
    end

    if not container or not fullType then return nil end
    local items = container:AddItems(fullType, count or 1)
    if items and customData then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            applyInventoryItemCustomData(item, customData)
            if isServer() and item.syncItemFields then
                item:syncItemFields()
            end
        end
    end
    return items
end

local function removePlayerMoney(player, amount)
    local normalized = math.max(0, math.floor(tonumber(amount) or 0))
    if normalized <= 0 or not player then
        return false
    end

    if DynamicTrading and DynamicTrading.ServerHelpers and DynamicTrading.ServerHelpers.RemoveMoney then
        return DynamicTrading.ServerHelpers.RemoveMoney(player, normalized)
    end

    local inventory = player:getInventory()
    if not inventory then
        return false
    end

    local function getWealth()
        local loose = inventory:getItemsFromType("Base.Money", true)
        local bundles = inventory:getItemsFromType("Base.MoneyBundle", true)
        local looseCount = loose and loose:size() or 0
        local bundleCount = bundles and bundles:size() or 0
        return looseCount + (bundleCount * 100)
    end

    if getWealth() < normalized then
        return false
    end

    local remaining = normalized
    local looseList = inventory:getItemsFromType("Base.Money", true)
    local bundleList = inventory:getItemsFromType("Base.MoneyBundle", true)
    local looseItems = {}
    local bundleItems = {}

    if looseList then
        for i = 0, looseList:size() - 1 do
            looseItems[#looseItems + 1] = looseList:get(i)
        end
    end

    if bundleList then
        for i = 0, bundleList:size() - 1 do
            bundleItems[#bundleItems + 1] = bundleList:get(i)
        end
    end

    for _, item in ipairs(looseItems) do
        if remaining <= 0 then break end
        removeInventoryItem(item)
        remaining = remaining - 1
    end

    for _, item in ipairs(bundleItems) do
        if remaining <= 0 then break end
        removeInventoryItem(item)
        remaining = remaining - 100
    end

    if remaining < 0 then
        local changeDue = math.abs(remaining)
        local bundlesBack = math.floor(changeDue / 100)
        local looseBack = changeDue % 100
        if bundlesBack > 0 then
            addInventoryItem(inventory, "Base.MoneyBundle", bundlesBack)
        end
        if looseBack > 0 then
            addInventoryItem(inventory, "Base.Money", looseBack)
        end
    end

    return true
end

local function addPlayerMoney(player, amount)
    local normalized = math.max(0, math.floor(tonumber(amount) or 0))
    if normalized <= 0 or not player then
        return false
    end

    local inventory = player:getInventory()
    if not inventory then
        return false
    end

    local bundles = math.floor(normalized / 100)
    local loose = normalized % 100
    if bundles > 0 then
        addInventoryItem(inventory, "Base.MoneyBundle", bundles)
    end
    if loose > 0 then
        addInventoryItem(inventory, "Base.Money", loose)
    end
    return true
end

local function findInventoryItemRecursive(container, itemID)
    if not container or not itemID then return nil end
    local items = container:getItems()
    if not items then return nil end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getID() == itemID then
            return item
        end
        if item and instanceof(item, "InventoryContainer") then
            local subContainer = item:getItemContainer()
            local found = findInventoryItemRecursive(subContainer, itemID)
            if found then return found end
        end
    end

    return nil
end

local function getInventoryItemByID(player, itemID)
    if not player or not itemID then return nil end
    return findInventoryItemRecursive(player:getInventory(), itemID)
end

Internal.removeInventoryItem = removeInventoryItem
Internal.removeInventoryItemUnits = removeInventoryItemUnits
Internal.addInventoryItem = addInventoryItem
Internal.removePlayerMoney = removePlayerMoney
Internal.addPlayerMoney = addPlayerMoney
Internal.getInventoryItemByID = getInventoryItemByID
Internal.getInventoryItemQuantity = getInventoryItemQuantity

return Network
