DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegInternal or {}

function Data.CopyStringArray(values)
    local copy = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        local key = tostring(value or "")
        if key ~= "" and not seen[key] then
            seen[key] = true
            copy[#copy + 1] = key
        end
    end
    return copy
end

function Data.EntryHasTag(tags, targetTag)
    local targetKey = tostring(targetTag or "")
    if targetKey == "" then
        return false
    end

    for _, itemTag in ipairs(tags or {}) do
        local itemKey = tostring(itemTag or "")
        if itemKey == targetKey then
            return true
        end
        if Config and Config.TagMatches and Config.TagMatches(itemKey, targetKey) then
            return true
        end
    end

    return false
end

function Data.IsAmmoEquipmentEntry(entry, tags)
    if tostring(entry and entry.assignedRequirementKey or "") == "Colony.Combat.Ammo" then
        return true
    end

    return Data.EntryHasTag(tags, "Weapon.Ranged.Ammo")
end

function Data.ResolveKeepOnDeplete(item, scriptItem)
    if item then
        if item.isKeepOnDeplete and item:isKeepOnDeplete() then
            return true
        end
        if item.getKeepOnDeplete and item:getKeepOnDeplete() then
            return true
        end
        if item.getScriptItem and not scriptItem then
            scriptItem = item:getScriptItem()
        end
    end

    if scriptItem then
        if scriptItem.isKeepOnDeplete and scriptItem:isKeepOnDeplete() then
            return true
        end
        if scriptItem.getKeepOnDeplete and scriptItem:getKeepOnDeplete() then
            return true
        end
    end

    return false
end

function Internal.CreateTransientInventoryItem(fullType)
    if not fullType or not InventoryItemFactory or not InventoryItemFactory.CreateItem then
        return nil
    end

    local ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
    if ok then
        return item
    end

    return nil
end

function Internal.GetEquipmentStaticMetadata(fullType)
    local key = tostring(fullType or "")
    if key == "" then
        return nil
    end

    Internal.EquipmentStaticMetadataCache = Internal.EquipmentStaticMetadataCache or {}
    if Internal.EquipmentStaticMetadataCache[key] then
        return Internal.EquipmentStaticMetadataCache[key]
    end

    local tempItem = Internal.CreateTransientInventoryItem(key)
    local scriptItem = tempItem and tempItem.getScriptItem and tempItem:getScriptItem() or (getScriptManager and getScriptManager():getItem(key)) or nil
    local metadata = {
        scriptItem = scriptItem,
        tags = Data.CopyStringArray((Config.GetItemCombinedTags and Config.GetItemCombinedTags(key)) or {}),
        conditionMax = tempItem and tempItem.getConditionMax and tempItem:getConditionMax() or (scriptItem and scriptItem.getConditionMax and scriptItem:getConditionMax()) or 0,
        isDrainable = tempItem and tempItem.IsDrainable and tempItem:IsDrainable() or false,
        useDelta = tempItem and tempItem.getUseDelta and tempItem:getUseDelta() or (scriptItem and scriptItem.getUseDelta and scriptItem:getUseDelta()) or 0,
        keepOnDeplete = Data.ResolveKeepOnDeplete(tempItem, scriptItem),
        hasHeadCondition = tempItem and tempItem.hasHeadCondition and tempItem:hasHeadCondition() or false,
        headConditionMax = tempItem and tempItem.hasHeadCondition and tempItem:hasHeadCondition() and tempItem.getHeadConditionMax and tempItem:getHeadConditionMax() or 0,
        quality = tempItem and tempItem.getQuality and tempItem:getQuality() or nil,
        haveBeenRepaired = tempItem and tempItem.getHaveBeenRepaired and tempItem:getHaveBeenRepaired() or nil,
        fluidCapacity = tempItem and tempItem.getFluidContainer and tempItem:getFluidContainer() and tempItem:getFluidContainer().getCapacity
            and math.max(0, tonumber(tempItem:getFluidContainer():getCapacity()) or 0)
            or (scriptItem and scriptItem.getFluidContainer and scriptItem:getFluidContainer() and scriptItem:getFluidContainer().getCapacity
                and math.max(0, tonumber(scriptItem:getFluidContainer():getCapacity()) or 0)
                or 0),
    }

    Internal.EquipmentStaticMetadataCache[key] = metadata
    return metadata
end

return Data