DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Nutrition = DC_Colony.Nutrition
local Registry = DC_Colony.Registry
local Internal = Registry.Internal

function Internal.EnsureArray(value)
    return type(value) == "table" and value or {}
end

function Internal.CopyShallow(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

function Internal.CopyDeep(source)
    if type(source) ~= "table" then
        return source
    end

    local copy = {}
    for key, value in pairs(source) do
        copy[key] = Internal.CopyDeep(value)
    end
    return copy
end

function Internal.GetDisplayNameForFullType(fullType)
    if not fullType or not getScriptManager then
        return tostring(fullType or "Unknown Item")
    end

    local item = getScriptManager():getItem(fullType)
    if item and item.getDisplayName then
        return item:getDisplayName()
    end

    return tostring(fullType or "Unknown Item")
end

function Internal.EnsureActivityLog(worker)
    if not worker then
        return {}
    end

    worker.activityLog = Internal.EnsureArray(worker.activityLog)
    local limit = math.max(1, tonumber(Config.WORKER_ACTIVITY_LOG_LIMIT) or 40)
    while #worker.activityLog > limit do
        table.remove(worker.activityLog, 1)
    end
    return worker.activityLog
end

function Internal.AppendActivityLog(worker, message, worldHour, category)
    if not worker or not message or tostring(message) == "" then
        return
    end

    local activityLog = Internal.EnsureActivityLog(worker)
    activityLog[#activityLog + 1] = {
        hour = tonumber(worldHour) or ((Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()),
        text = tostring(message),
        category = tostring(category or "general")
    }

    local limit = math.max(1, tonumber(Config.WORKER_ACTIVITY_LOG_LIMIT) or 40)
    while #activityLog > limit do
        table.remove(activityLog, 1)
    end
end

function Internal.EnsureWorkerCacheState(worker)
    if not worker then
        return
    end

    if worker.nutritionCacheDirty == nil then
        worker.nutritionCacheDirty = worker.storedCalories == nil or worker.storedHydration == nil
    end
    if worker.toolCacheDirty == nil then
        worker.toolCacheDirty = worker.assignedToolTags == nil
    end
    if worker.outputCacheDirty == nil then
        worker.outputCacheDirty = worker.outputCount == nil
    end
end

function Internal.MarkNutritionCacheDirty(worker)
    if worker then
        worker.nutritionCacheDirty = true
    end
end

function Internal.MarkToolCacheDirty(worker)
    if worker then
        worker.toolCacheDirty = true
    end
end

function Internal.MarkOutputCacheDirty(worker)
    if worker then
        worker.outputCacheDirty = true
    end
end

function Internal.ApplyNutritionCacheDelta(worker, caloriesDelta, hydrationDelta)
    if not worker then
        return false
    end

    Internal.EnsureWorkerCacheState(worker)
    if worker.nutritionCacheDirty then
        return false
    end

    worker.storedCalories = math.max(0, (tonumber(worker.storedCalories) or 0) + (tonumber(caloriesDelta) or 0))
    worker.storedHydration = math.max(0, (tonumber(worker.storedHydration) or 0) + (tonumber(hydrationDelta) or 0))
    return true
end

function Internal.ApplyToolTags(worker, tags)
    if not worker then
        return false
    end

    Internal.EnsureWorkerCacheState(worker)
    if worker.toolCacheDirty then
        return false
    end

    worker.assignedToolTags = type(worker.assignedToolTags) == "table" and worker.assignedToolTags or {}
    for _, tag in ipairs(tags or {}) do
        worker.assignedToolTags[tag] = true
    end
    return true
end

function Internal.ApplyOutputCountDelta(worker, qtyDelta)
    if not worker then
        return false
    end

    Internal.EnsureWorkerCacheState(worker)
    if worker.outputCacheDirty then
        return false
    end

    worker.outputCount = math.max(0, (tonumber(worker.outputCount) or 0) + (tonumber(qtyDelta) or 0))
    return true
end

function Internal.ResetOutputCount(worker)
    if not worker then
        return
    end

    worker.outputCount = 0
    worker.outputWeight = 0
    worker.outputCacheDirty = false
end

function Internal.BuildStarterNutritionLedger(template)
    local existing = Internal.CopyShallow(template and template.nutritionLedger or nil)
    if #existing > 0 then
        return existing
    end

    return existing
end

function Internal.GetStarterReserveTotals(template)
    local existing = Internal.CopyShallow(template and template.nutritionLedger or nil)
    local templateCalories = tonumber(template and template.caloriesCached) or 0
    local templateHydration = tonumber(template and template.hydrationCached) or 0
    if #existing > 0 then
        return templateCalories, templateHydration
    end
    if templateCalories > 0 or templateHydration > 0 then
        return templateCalories, templateHydration
    end

    local starterCalories = Config.RandomRangeInclusive(
        Config.RECRUIT_START_CALORIES_MIN,
        Config.RECRUIT_START_CALORIES_MAX
    )
    local starterHydration = Config.RandomRangeInclusive(
        Config.RECRUIT_START_HYDRATION_MIN,
        Config.RECRUIT_START_HYDRATION_MAX
    )

    return starterCalories, starterHydration
end

local function copyStringArray(values)
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

local function resolveKeepOnDeplete(item, scriptItem)
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

    local tempItem = Internal.CreateTransientInventoryItem(fullType)
    local scriptItem = tempItem and tempItem.getScriptItem and tempItem:getScriptItem() or (getScriptManager and getScriptManager():getItem(fullType)) or nil
    local defaultTags = entry.tags
        or (Config.GetItemCombinedTags and Config.GetItemCombinedTags(fullType))
        or {}
    local conditionMax = tempItem and tempItem.getConditionMax and tempItem:getConditionMax() or (scriptItem and scriptItem.getConditionMax and scriptItem:getConditionMax()) or 0
    local isDrainable = tempItem and tempItem.IsDrainable and tempItem:IsDrainable() or false
    local useDelta = tempItem and tempItem.getUseDelta and tempItem:getUseDelta() or (scriptItem and scriptItem.getUseDelta and scriptItem:getUseDelta()) or 0
    local usedDelta = tonumber(entry.usedDelta)
    if usedDelta == nil and isDrainable then
        usedDelta = tempItem and tempItem.getCurrentUsesFloat and tempItem:getCurrentUsesFloat()
            or tempItem and tempItem.getUsedDelta and tempItem:getUsedDelta()
            or 1
    end

    local condition = tonumber(entry.condition)
    if condition == nil and conditionMax > 0 then
        condition = conditionMax
    end

    local hasHeadCondition = tempItem and tempItem.hasHeadCondition and tempItem:hasHeadCondition() or false
    local headConditionMax = hasHeadCondition and tempItem.getHeadConditionMax and tempItem:getHeadConditionMax() or 0
    local headCondition = tonumber(entry.headCondition)
    if headCondition == nil and hasHeadCondition and tempItem and tempItem.getHeadCondition then
        headCondition = tempItem:getHeadCondition()
    end

    local quality = tonumber(entry.quality)
    if quality == nil and tempItem and tempItem.getQuality then
        quality = tempItem:getQuality()
    end

    local haveBeenRepaired = tonumber(entry.haveBeenRepaired)
    if haveBeenRepaired == nil and tempItem and tempItem.getHaveBeenRepaired then
        haveBeenRepaired = tempItem:getHaveBeenRepaired()
    end

    local qty = math.max(1, math.floor(tonumber(entry.qty) or 1))

    return {
        fullType = fullType,
        displayName = tostring(entry.displayName or Internal.GetDisplayNameForFullType(fullType)),
        tags = copyStringArray(defaultTags),
        qty = qty,
        condition = conditionMax > 0 and math.max(0, math.min(conditionMax, math.floor(condition or conditionMax))) or nil,
        conditionMax = conditionMax > 0 and conditionMax or nil,
        headCondition = headConditionMax > 0 and math.max(0, math.min(headConditionMax, math.floor(headCondition or headConditionMax))) or nil,
        headConditionMax = headConditionMax > 0 and headConditionMax or nil,
        isDrainable = isDrainable == true,
        useDelta = isDrainable and math.max(0, tonumber(useDelta) or 0) or nil,
        usedDelta = isDrainable and math.max(0, math.min(1, tonumber(usedDelta) or 0)) or nil,
        quality = quality ~= nil and math.max(0, math.floor(tonumber(quality) or 0)) or nil,
        haveBeenRepaired = haveBeenRepaired ~= nil and math.max(0, math.floor(tonumber(haveBeenRepaired) or 0)) or nil,
        keepOnDeplete = resolveKeepOnDeplete(tempItem, scriptItem),
        pendingVanillaBreak = entry.pendingVanillaBreak == true,
    }
end

function Internal.BuildEquipmentEntryFromInventoryItem(invItem, overrideDisplayName)
    if not invItem or not invItem.getFullType then
        return nil
    end

    return Internal.NormalizeEquipmentEntry({
        fullType = invItem:getFullType(),
        displayName = overrideDisplayName or (invItem.getDisplayName and invItem:getDisplayName() or nil),
        tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(invItem:getFullType()))
            or (Config.FindItemTags and Config.FindItemTags(invItem:getFullType()))
            or {},
        qty = math.max(1, math.floor(tonumber(invItem.getCount and invItem:getCount() or 1) or 1)),
        condition = invItem.getCondition and invItem:getCondition() or nil,
        headCondition = invItem.getHeadCondition and invItem:getHeadCondition() or nil,
        quality = invItem.getQuality and invItem:getQuality() or nil,
        haveBeenRepaired = invItem.getHaveBeenRepaired and invItem:getHaveBeenRepaired() or nil,
        usedDelta = invItem.getCurrentUsesFloat and invItem:getCurrentUsesFloat()
            or invItem.getUsedDelta and invItem:getUsedDelta()
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
    return customData
end

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
        displayName = tostring(entry.displayName or Internal.GetDisplayNameForFullType(fullType)),
        qty = math.max(1, math.floor(tonumber(entry.qty) or 1)),
    }
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
    local isColonyTool = Config.IsColonyToolFullType and Config.IsColonyToolFullType(fullType) or false
    local entry = {
        fullType = fullType,
        displayName = overrideDisplayName or (invItem.getDisplayName and invItem:getDisplayName() or nil),
        qty = math.max(1, math.floor(tonumber(invItem.getCount and invItem:getCount() or 1) or 1)),
    }

    if isColonyTool then
        entry.condition = invItem.getCondition and invItem:getCondition() or nil
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

    if next(customData) ~= nil then
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
        tostring(normalized.isRottenProvision == true and "1" or "0"),
        tostring(normalized.condition ~= nil and normalized.condition or ""),
        tostring(normalized.conditionMax ~= nil and normalized.conditionMax or ""),
        tostring(normalized.usedDelta ~= nil and string.format("%.4f", normalized.usedDelta) or ""),
        tostring(normalized.useDelta ~= nil and string.format("%.4f", normalized.useDelta) or ""),
        tostring(normalized.keepOnDeplete == true and "1" or "0"),
    }, "|")
end

function Internal.GetEquipmentDurabilitySignature(entry)
    local normalized = Internal.NormalizeEquipmentEntry(entry)
    if not normalized then
        return ""
    end

    return table.concat({
        tostring(normalized.fullType or ""),
        tostring(normalized.condition ~= nil and normalized.condition or ""),
        tostring(normalized.conditionMax ~= nil and normalized.conditionMax or ""),
        tostring(normalized.usedDelta ~= nil and string.format("%.4f", normalized.usedDelta) or ""),
        tostring(normalized.useDelta ~= nil and string.format("%.4f", normalized.useDelta) or ""),
        tostring(normalized.keepOnDeplete == true and "1" or "0"),
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

return Internal
