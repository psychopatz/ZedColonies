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

local function addInventoryItem(container, fullType, count, customData)
    if DynamicTrading and DynamicTrading.ServerHelpers then
        if customData and DynamicTrading.ServerHelpers.AddItemWithCondition then
            return DynamicTrading.ServerHelpers.AddItemWithCondition(container, fullType, count, customData)
        end
        if DynamicTrading.ServerHelpers.AddItem then
            return DynamicTrading.ServerHelpers.AddItem(container, fullType, count)
        end
    end

    if not container or not fullType then return nil end
    local items = container:AddItems(fullType, count or 1)
    if items and customData then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if customData.condition ~= nil and item.getConditionMax and item:getConditionMax() > 0 then
                item:setCondition(math.max(0, math.min(item:getConditionMax(), math.floor(tonumber(customData.condition) or item:getConditionMax()))))
            end
            if customData.usedDelta ~= nil and item.IsDrainable and item:IsDrainable() then
                item:setUsedDelta(math.max(0, math.min(1, tonumber(customData.usedDelta) or 0)))
            end
            if customData.fluidAmount ~= nil and item.getFluidContainer and item:getFluidContainer() then
                item:getFluidContainer():setAmount(math.max(0, tonumber(customData.fluidAmount) or 0))
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
Internal.addInventoryItem = addInventoryItem
Internal.removePlayerMoney = removePlayerMoney
Internal.addPlayerMoney = addPlayerMoney
Internal.getInventoryItemByID = getInventoryItemByID

return Network
