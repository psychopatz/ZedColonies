DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}

local Resources = DC_Colony.Resources

local function collectInventoryItemsRecursive(container, into)
    if not container or not into then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            into[#into + 1] = item
            if instanceof(item, "InventoryContainer") then
                collectInventoryItemsRecursive(item:getItemContainer(), into)
            end
        end
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

local function removeInventoryItem(item)
    local container = item and item:getContainer() or nil
    if container then
        container:DoRemoveItem(item)
    end
end

local function addInventoryItem(container, fullType, count)
    if container and fullType and count and count > 0 then
        container:AddItems(fullType, count)
    end
end

function Resources.ConsumeSeedFromPlayer(player, seedFullType)
    local inventory = player and player:getInventory() or nil
    if not inventory then
        return false
    end

    local items = {}
    collectInventoryItemsRecursive(inventory, items)

    for _, item in ipairs(items) do
        local fullType = item and item.getFullType and item:getFullType() or nil
        if tostring(fullType or "") == tostring(seedFullType or "") then
            local quantity = getInventoryItemQuantity(item)
            local container = item:getContainer()
            removeInventoryItem(item)
            if quantity > 1 and container then
                addInventoryItem(container, fullType, quantity - 1)
            end
            return true
        end
    end

    return false
end