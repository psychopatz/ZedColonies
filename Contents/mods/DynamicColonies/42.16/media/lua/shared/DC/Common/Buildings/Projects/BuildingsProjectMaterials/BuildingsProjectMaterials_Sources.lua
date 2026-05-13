DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Materials = Internal.ProjectMaterials or {}

Internal.ProjectMaterials = Materials

function Materials.GetWarehouseOutputCounts(ownerUsername)
    local warehouseApi = Materials.GetWarehouse()
    local warehouse = warehouseApi and warehouseApi.GetOwnerWarehouse and warehouseApi.GetOwnerWarehouse(ownerUsername) or nil
    local counts = {}
    for _, entry in ipairs(warehouse and warehouse.ledgers and warehouse.ledgers.output or {}) do
        local fullType = tostring(entry.fullType or "")
        local qty = math.max(0, math.floor(tonumber(entry.qty) or 0))
        if fullType ~= "" and qty > 0 then
            counts[fullType] = (counts[fullType] or 0) + qty
        end
    end
    return counts
end

function Materials.GetInventoryItemQuantity(item)
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

function Materials.CollectInventoryCountsRecursive(container, counts)
    if not container or not counts then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item then
            local fullType = item.getFullType and item:getFullType() or nil
            if fullType then
                counts[fullType] = (counts[fullType] or 0) + Materials.GetInventoryItemQuantity(item)
            end

            if instanceof(item, "InventoryContainer") then
                Materials.CollectInventoryCountsRecursive(item:getItemContainer(), counts)
            end
        end
    end
end

function Materials.CanReadInventory(value)
    local valueType = type(value)
    return (valueType == "table" or valueType == "userdata") and value.getInventory ~= nil
end

function Materials.ResolveSourcePlayer(ownerUsername, sourcePlayer)
    if Materials.CanReadInventory(sourcePlayer) then
        return sourcePlayer
    end

    if Materials.CanReadInventory(ownerUsername) then
        return ownerUsername
    end

    local colonyConfig = Materials.GetColonyConfig()
    local player = colonyConfig and colonyConfig.GetPlayerObject and colonyConfig.GetPlayerObject() or nil
    if Materials.CanReadInventory(player) then
        local owner = Materials.GetOwnerUsername(ownerUsername)
        if Materials.GetOwnerUsername(player) == owner then
            return player
        end
    end

    return nil
end

function Materials.GetPlayerInventoryCounts(ownerUsername, sourcePlayer)
    local player = Materials.ResolveSourcePlayer(ownerUsername, sourcePlayer)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local counts = {}
    if not inventory then
        return counts
    end

    Materials.CollectInventoryCountsRecursive(inventory, counts)
    return counts
end

function Materials.MergeCounts(baseCounts, extraCounts)
    local merged = {}

    for fullType, qty in pairs(baseCounts or {}) do
        merged[fullType] = math.max(0, math.floor(tonumber(qty) or 0))
    end

    for fullType, qty in pairs(extraCounts or {}) do
        local key = tostring(fullType or "")
        if key ~= "" then
            merged[key] = (merged[key] or 0) + math.max(0, math.floor(tonumber(qty) or 0))
        end
    end

    return merged
end

function Materials.GetAvailableMaterialCounts(ownerUsername, sourcePlayer)
    return Materials.MergeCounts(
        Materials.GetWarehouseOutputCounts(ownerUsername),
        Materials.GetPlayerInventoryCounts(ownerUsername, sourcePlayer)
    )
end

return Buildings