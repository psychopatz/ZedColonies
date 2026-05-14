DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegInternal or {}

function Internal.ApplyEquipmentEntryState(item, entry)
    if not item or type(entry) ~= "table" then
        return item
    end

    if item.getConditionMax and item:getConditionMax() > 0 and entry.condition ~= nil then
        item:setCondition(math.max(0, math.min(item:getConditionMax(), math.floor(tonumber(entry.condition) or item:getConditionMax()))))
    end

    if item.IsDrainable and item:IsDrainable() and entry.usedDelta ~= nil then
        item:setUsedDelta(math.max(0, math.min(1, tonumber(entry.usedDelta) or 0)))
    end

    if item.hasHeadCondition and item:hasHeadCondition() then
        if entry.headCondition ~= nil and item.setHeadCondition and item.getHeadConditionMax then
            item:setHeadCondition(math.max(0, math.min(item:getHeadConditionMax(), math.floor(tonumber(entry.headCondition) or item:getHeadConditionMax()))))
        elseif item.setHeadConditionFromCondition then
            pcall(function()
                item:setHeadConditionFromCondition(item)
            end)
        end

        if item.setConditionFromHeadCondition then
            pcall(function()
                item:setConditionFromHeadCondition(item)
            end)
        end
    end

    if entry.quality ~= nil and item.setQuality then
        item:setQuality(math.max(0, math.floor(tonumber(entry.quality) or 0)))
    end

    if entry.haveBeenRepaired ~= nil and item.setHaveBeenRepaired then
        item:setHaveBeenRepaired(math.max(0, math.floor(tonumber(entry.haveBeenRepaired) or 0)))
    end

    if entry.fluidAmount ~= nil and item.getFluidContainer and item:getFluidContainer() and item:getFluidContainer().setAmount then
        item:getFluidContainer():setAmount(math.max(0, tonumber(entry.fluidAmount) or 0))
    end

    return item
end

function Internal.NormalizeEquipmentEntry(entry)
    if type(entry) ~= "table" or not entry.fullType then
        return nil
    end

    local fullType = tostring(entry.fullType)
    if fullType == "" then
        return nil
    end

    local staticMetadata = Internal.GetEquipmentStaticMetadata(fullType) or {}
    local defaultTags = entry.tags
        or staticMetadata.tags
        or {}
    local ammoEntry = Data.IsAmmoEquipmentEntry(entry, defaultTags)
    local conditionMax = tonumber(staticMetadata.conditionMax) or 0
    local isDrainable = staticMetadata.isDrainable == true
    local useDelta = tonumber(staticMetadata.useDelta) or 0
    local usedDelta = tonumber(entry.usedDelta)
    if usedDelta == nil and isDrainable then
        usedDelta = 1
    end

    if ammoEntry then
        conditionMax = 0
        isDrainable = false
        useDelta = 0
        usedDelta = nil
    end

    local condition = tonumber(entry.condition)
    if condition == nil and conditionMax > 0 then
        condition = conditionMax
    end
    if ammoEntry then
        condition = nil
    end

    local hasHeadCondition = staticMetadata.hasHeadCondition == true
    local headConditionMax = tonumber(staticMetadata.headConditionMax) or 0
    local headCondition = tonumber(entry.headCondition)
    if headCondition == nil and hasHeadCondition then
        headCondition = headConditionMax
    end
    if ammoEntry then
        hasHeadCondition = false
        headConditionMax = 0
        headCondition = nil
    end

    local quality = tonumber(entry.quality)
    if quality == nil then
        quality = staticMetadata.quality
    end

    local haveBeenRepaired = tonumber(entry.haveBeenRepaired)
    if haveBeenRepaired == nil then
        haveBeenRepaired = staticMetadata.haveBeenRepaired
    end

    local assignedRequirementKey = tostring(entry.assignedRequirementKey or "")
    if assignedRequirementKey == "" then
        assignedRequirementKey = nil
    end

    local fluidCapacity = math.max(0, tonumber(entry.fluidCapacity) or tonumber(staticMetadata.fluidCapacity) or 0)
    local fluidAmount = tonumber(entry.fluidAmount)
    if fluidAmount == nil and fluidCapacity > 0 then
        fluidAmount = 0
    end

    return {
        fullType = fullType,
        entryID = tostring(entry.entryID or Internal.GenerateLedgerEntryID("eq")),
        displayName = tostring(entry.displayName or Internal.GetDisplayNameForFullType(fullType)),
        tags = Data.CopyStringArray(defaultTags),
        qty = math.max(1, math.floor(tonumber(entry.qty) or 1)),
        condition = conditionMax > 0 and math.max(0, math.min(conditionMax, math.floor(condition or conditionMax))) or nil,
        conditionMax = conditionMax > 0 and conditionMax or nil,
        headCondition = headConditionMax > 0 and math.max(0, math.min(headConditionMax, math.floor(headCondition or headConditionMax))) or nil,
        headConditionMax = headConditionMax > 0 and headConditionMax or nil,
        isDrainable = ammoEntry ~= true and isDrainable == true,
        useDelta = ammoEntry ~= true and isDrainable and math.max(0, tonumber(useDelta) or 0) or nil,
        usedDelta = ammoEntry ~= true and isDrainable and math.max(0, math.min(1, tonumber(usedDelta) or 0)) or nil,
        quality = quality ~= nil and math.max(0, math.floor(tonumber(quality) or 0)) or nil,
        haveBeenRepaired = haveBeenRepaired ~= nil and math.max(0, math.floor(tonumber(haveBeenRepaired) or 0)) or nil,
        keepOnDeplete = ammoEntry ~= true and staticMetadata.keepOnDeplete == true,
        fluidAmount = fluidAmount ~= nil and math.max(0, tonumber(fluidAmount) or 0) or nil,
        fluidCapacity = fluidCapacity > 0 and fluidCapacity or nil,
        pendingVanillaBreak = entry.pendingVanillaBreak == true,
        assignedRequirementKey = assignedRequirementKey,
    }
end

function Internal.BuildEquipmentEntryFromInventoryItem(invItem, overrideDisplayName, sourceEntry)
    if not invItem or not invItem.getFullType then
        return nil
    end

    local condition = invItem.getCondition and tonumber(invItem:getCondition()) or nil
    local maxCondition = invItem.getConditionMax and tonumber(invItem:getConditionMax()) or 0
    if condition ~= nil and maxCondition > 0 and condition <= 0 then
        local isBroken = invItem.isBroken and invItem:isBroken() == true or false
        if not isBroken then
            condition = maxCondition
        end
    end

    return Internal.NormalizeEquipmentEntry({
        fullType = invItem:getFullType(),
        displayName = overrideDisplayName or (invItem.getDisplayName and invItem:getDisplayName() or nil),
        tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(invItem:getFullType()))
            or (Config.FindItemTags and Config.FindItemTags(invItem:getFullType()))
            or {},
        qty = math.max(1, math.floor(tonumber(invItem.getCount and invItem:getCount() or 1) or 1)),
        condition = condition,
        headCondition = invItem.getHeadCondition and invItem:getHeadCondition() or nil,
        quality = invItem.getQuality and invItem:getQuality() or nil,
        haveBeenRepaired = invItem.getHaveBeenRepaired and invItem:getHaveBeenRepaired() or nil,
        usedDelta = invItem.getCurrentUsesFloat and invItem:getCurrentUsesFloat()
            or invItem.getUsedDelta and invItem:getUsedDelta()
            or nil,
        assignedRequirementKey = sourceEntry and sourceEntry.assignedRequirementKey or nil,
        fluidAmount = invItem.getFluidContainer and invItem:getFluidContainer() and invItem:getFluidContainer().getAmount
            and math.max(0, tonumber(invItem:getFluidContainer():getAmount()) or 0)
            or nil,
        fluidCapacity = invItem.getFluidContainer and invItem:getFluidContainer() and invItem:getFluidContainer().getCapacity
            and math.max(0, tonumber(invItem:getFluidContainer():getCapacity()) or 0)
            or nil,
    })
end

function Internal.BuildEquipmentAddItemCustomData(entry)
    local normalized = Internal.NormalizeEquipmentEntry(entry)
    if not normalized then
        return nil
    end

    local customData = {}
    if normalized.condition ~= nil then
        customData.condition = normalized.condition
    end
    if normalized.headCondition ~= nil then
        customData.headCondition = normalized.headCondition
    end
    if normalized.usedDelta ~= nil then
        customData.usedDelta = normalized.usedDelta
    end
    if normalized.quality ~= nil then
        customData.quality = normalized.quality
    end
    if normalized.haveBeenRepaired ~= nil then
        customData.haveBeenRepaired = normalized.haveBeenRepaired
    end
    if normalized.fluidAmount ~= nil then
        customData.fluidAmount = normalized.fluidAmount
    end
    return customData
end

function Internal.GetEquipmentDurabilitySignature(entry)
    local normalized = Internal.NormalizeEquipmentEntry(entry)
    if not normalized then
        return ""
    end

    local conditionRatio = 0
    if normalized.conditionMax and normalized.conditionMax > 0 then
        conditionRatio = (math.max(0, tonumber(normalized.condition) or 0) / normalized.conditionMax)
    end

    local roundedConditionRatio = math.floor((conditionRatio / 0.10) + 0.5) * 0.10
    local roundedUsedDelta = normalized.usedDelta ~= nil
        and (math.floor((math.max(0, tonumber(normalized.usedDelta) or 0) * 100) + 0.5) / 100)
        or nil

    return table.concat({
        tostring(normalized.fullType or ""),
        tostring(normalized.conditionMax ~= nil and normalized.conditionMax or ""),
        tostring(normalized.condition ~= nil and string.format("%.2f", roundedConditionRatio) or ""),
        tostring(roundedUsedDelta ~= nil and string.format("%.2f", roundedUsedDelta) or ""),
        tostring(normalized.useDelta ~= nil and string.format("%.4f", normalized.useDelta) or ""),
        tostring(normalized.keepOnDeplete == true and "1" or "0"),
        tostring(normalized.fluidAmount ~= nil and string.format("%.4f", normalized.fluidAmount) or ""),
        tostring(normalized.fluidCapacity ~= nil and string.format("%.4f", normalized.fluidCapacity) or ""),
    }, "|")
end

function Internal.IsEquipmentEntryUsable(entry)
    local normalized = Internal.NormalizeEquipmentEntry(entry)
    if not normalized then
        return false
    end

    if normalized.condition ~= nil and normalized.condition <= 0 then
        return false
    end

    if normalized.isDrainable == true then
        local remaining = math.max(0, tonumber(normalized.usedDelta) or 0)
        local step = math.max(0, tonumber(normalized.useDelta) or 0)
        if step > 0 and remaining + 0.0001 < step then
            return false
        end
    end

    return true
end

return Data
