DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Nutrition = DC_Colony.Nutrition
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegInternal or {}

function Internal.NormalizeOutputEntry(entry)
    if type(entry) ~= "table" or not entry.fullType then
        return nil
    end

    local fullType = tostring(entry.fullType or "")
    if fullType == "" then
        return nil
    end

    local normalized = {
        fullType = fullType,
        entryID = tostring(entry.entryID or Internal.GenerateLedgerEntryID("out")),
        displayName = tostring(entry.displayName or Internal.GetDisplayNameForFullType(fullType)),
        qty = math.max(1, math.floor(tonumber(entry.qty) or 1)),
    }
    if entry.forceLiteral == true then
        normalized.forceLiteral = true
    end
    if entry.literalSpecial == true then
        normalized.literalSpecial = true
    end
    if entry.specialStockType ~= nil then
        normalized.specialStockType = tostring(entry.specialStockType or "")
    end
    if entry.researchJobID ~= nil then
        normalized.researchJobID = tostring(entry.researchJobID or "")
    end
    local isColonyTool = Config.IsColonyToolFullType and Config.IsColonyToolFullType(fullType) or false
    local equipmentState = isColonyTool and Internal.NormalizeEquipmentEntry(entry) or nil
    if equipmentState then
        normalized.condition = equipmentState.condition
        normalized.conditionMax = equipmentState.conditionMax
        normalized.headCondition = equipmentState.headCondition
        normalized.headConditionMax = equipmentState.headConditionMax
        normalized.isDrainable = equipmentState.isDrainable == true
        normalized.useDelta = equipmentState.useDelta
        normalized.usedDelta = equipmentState.usedDelta
        normalized.keepOnDeplete = equipmentState.keepOnDeplete == true
    end

    if entry.fluidAmount ~= nil then
        normalized.fluidAmount = math.max(0, tonumber(entry.fluidAmount) or 0)
    end
    if entry.fluidCapacity ~= nil then
        normalized.fluidCapacity = math.max(0, tonumber(entry.fluidCapacity) or 0)
    elseif normalized.fluidAmount ~= nil then
        local fluidState = Internal.NormalizeEquipmentEntry({
            fullType = fullType,
            fluidAmount = normalized.fluidAmount,
        })
        normalized.fluidCapacity = fluidState and fluidState.fluidCapacity or nil
    end

    if entry.isRottenProvision == true or entry.isRotten == true or tostring(entry.provisionBlockedReason or "") ~= "" then
        normalized.isRottenProvision = true
        normalized.provisionBlockedReason = tostring(
            entry.provisionBlockedReason
                or (Nutrition and Nutrition.Internal and Nutrition.Internal.ROTTEN_PROVISION_MESSAGE)
                or "Rotten items cannot be used as colony provisions."
        )
    end

    return normalized
end

function Internal.BuildOutputEntryFromInventoryItem(invItem, overrideDisplayName)
    if not invItem or not invItem.getFullType then
        return nil
    end

    local fullType = invItem:getFullType()
    local condition = invItem.getCondition and tonumber(invItem:getCondition()) or nil
    local maxCondition = invItem.getConditionMax and tonumber(invItem:getConditionMax()) or 0
    if condition ~= nil and maxCondition > 0 and condition <= 0 then
        local isBroken = invItem.isBroken and invItem:isBroken() == true or false
        if not isBroken then
            condition = maxCondition
        end
    end
    local isColonyTool = Config.IsColonyToolFullType and Config.IsColonyToolFullType(fullType) or false
    local entry = {
        fullType = fullType,
        displayName = overrideDisplayName or (invItem.getDisplayName and invItem:getDisplayName() or nil),
        qty = math.max(1, math.floor(tonumber(invItem.getCount and invItem:getCount() or 1) or 1)),
    }

    if isColonyTool then
        entry.condition = condition
        entry.headCondition = invItem.getHeadCondition and invItem:getHeadCondition() or nil
        entry.usedDelta = invItem.getCurrentUsesFloat and invItem:getCurrentUsesFloat()
            or invItem.getUsedDelta and invItem:getUsedDelta()
            or nil
    end

    if invItem.getFluidContainer and invItem:getFluidContainer() then
        local fluidContainer = invItem:getFluidContainer()
        if fluidContainer and fluidContainer.getAmount then
            entry.fluidAmount = math.max(0, tonumber(fluidContainer:getAmount()) or 0)
        end
        if fluidContainer and fluidContainer.getCapacity then
            entry.fluidCapacity = math.max(0, tonumber(fluidContainer:getCapacity()) or 0)
        end
    end

    if invItem.isRotten and invItem:isRotten() then
        entry.isRottenProvision = true
        entry.provisionBlockedReason = Nutrition
            and Nutrition.Internal
            and tostring(Nutrition.Internal.ROTTEN_PROVISION_MESSAGE or "")
            or "Rotten items cannot be used as colony provisions."
    end

    return Internal.NormalizeOutputEntry(entry)
end

function Internal.IsWarehouseInventoryItemPristine(invItem)
    if not invItem or not invItem.getFullType then
        return false
    end

    local fullType = tostring(invItem:getFullType() or "")
    if fullType == "" or fullType == "Base.Money" or fullType == "Base.MoneyBundle" then
        return false
    end

    local normalized = Internal.BuildOutputEntryFromInventoryItem(invItem)
    if not normalized then
        return false
    end

    if normalized.isRottenProvision == true or tostring(normalized.provisionBlockedReason or "") ~= "" then
        return false
    end

    local conditionMax = math.max(0, tonumber(normalized.conditionMax) or 0)
    if conditionMax > 0 and math.max(0, tonumber(normalized.condition) or 0) + 0.0001 < conditionMax then
        return false
    end

    local headConditionMax = math.max(0, tonumber(normalized.headConditionMax) or 0)
    if headConditionMax > 0 and math.max(0, tonumber(normalized.headCondition) or 0) + 0.0001 < headConditionMax then
        return false
    end

    if normalized.isDrainable == true and math.max(0, tonumber(normalized.usedDelta) or 0) + 0.0001 < 1 then
        return false
    end

    local fluidCapacity = math.max(0, tonumber(normalized.fluidCapacity) or 0)
    if fluidCapacity > 0 and math.max(0, tonumber(normalized.fluidAmount) or 0) + 0.0001 < fluidCapacity then
        return false
    end

    local equipmentEntry = Internal.BuildEquipmentEntryFromInventoryItem and Internal.BuildEquipmentEntryFromInventoryItem(invItem) or nil
    if equipmentEntry then
        local staticMetadata = Internal.GetEquipmentStaticMetadata and Internal.GetEquipmentStaticMetadata(fullType) or {}
        local defaultQuality = tonumber(staticMetadata and staticMetadata.quality)
        local currentQuality = tonumber(equipmentEntry.quality)
        if currentQuality ~= nil and defaultQuality ~= nil and currentQuality ~= defaultQuality then
            return false
        end

        local defaultRepairs = math.max(0, tonumber(staticMetadata and staticMetadata.haveBeenRepaired) or 0)
        local currentRepairs = math.max(0, tonumber(equipmentEntry.haveBeenRepaired) or 0)
        if currentRepairs > defaultRepairs then
            return false
        end
    end

    return true
end

function Internal.BuildOutputAddItemCustomData(entry)
    local normalized = Internal.NormalizeOutputEntry(entry)
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
    if normalized.fluidAmount ~= nil then
        customData.fluidAmount = normalized.fluidAmount
    end

    for _ in pairs(customData) do
        return customData
    end

    return nil
end

function Internal.GetOutputEntryStateSignature(entry)
    local normalized = Internal.NormalizeOutputEntry(entry)
    if not normalized then
        return ""
    end

    return table.concat({
        tostring(normalized.fullType or ""),
        tostring(normalized.displayName or ""),
        tostring(normalized.fluidAmount ~= nil and string.format("%.4f", normalized.fluidAmount) or ""),
        tostring(normalized.fluidCapacity ~= nil and string.format("%.4f", normalized.fluidCapacity) or ""),
        tostring(normalized.isRottenProvision == true and "1" or "0"),
        tostring(normalized.forceLiteral == true and "1" or "0"),
        tostring(normalized.literalSpecial == true and "1" or "0"),
        tostring(normalized.specialStockType or ""),
        tostring(normalized.researchJobID or ""),
        tostring(normalized.condition ~= nil and normalized.condition or ""),
        tostring(normalized.conditionMax ~= nil and normalized.conditionMax or ""),
        tostring(normalized.usedDelta ~= nil and string.format("%.4f", normalized.usedDelta) or ""),
        tostring(normalized.useDelta ~= nil and string.format("%.4f", normalized.useDelta) or ""),
        tostring(normalized.keepOnDeplete == true and "1" or "0"),
    }, "|")
end

return Data
