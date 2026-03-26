local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Skills = DC_Colony.Skills

local function normalizeDamageMultiplier(value)
    return math.max(1, math.floor(tonumber(value) or 1))
end

local function getToolLabel(entry)
    if not entry then
        return "Tool"
    end
    return tostring(entry.displayName or Registry.Internal.GetDisplayNameForFullType(entry.fullType) or entry.fullType or "Tool")
end

local function entryMatchesToolTag(entry, requiredTag)
    if not entry or not requiredTag then
        return false
    end

    for _, itemTag in ipairs(entry.tags or {}) do
        if Config.TagMatches and Config.TagMatches(itemTag, requiredTag) then
            return true
        end
    end

    return false
end

local function getBreakReason(entry)
    if entry and entry.isDrainable == true then
        return "ran empty"
    end
    return "broke"
end

local function getWorkerMaintenanceLevel(worker)
    local entry = Skills and Skills.GetSkillEntry and Skills.GetSkillEntry(worker, "Maintenance") or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

local function grantMaintenanceXP(worker, amount)
    if not worker or not Skills or not Skills.GrantXP then
        return nil
    end

    return Skills.GrantXP(worker, "Maintenance", math.max(1, math.floor(tonumber(amount) or 1)))
end

local function moveBrokenToolToStorage(worker, index, entry, currentHour)
    if not worker or not index or not entry then
        return false
    end

    local brokenEntry = Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry(entry) or entry
    if brokenEntry then
        brokenEntry.pendingVanillaBreak = true
    end

    table.remove(worker.toolLedger, index)
    Registry.Internal.MarkToolCacheDirty(worker)

    if Warehouse and Warehouse.DepositEquipmentEntry then
        Warehouse.DepositEquipmentEntry(worker.ownerUsername, brokenEntry or entry, true)
    end

    if Internal.appendWorkerLog then
        Internal.appendWorkerLog(
            worker,
            getToolLabel(entry) .. " " .. getBreakReason(entry) .. " and was moved to warehouse storage.",
            currentHour,
            "warehouse"
        )
    end

    return true
end

local function applyWearEvent(worker, entry, damageMultiplier)
    local normalized = Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry(entry) or nil
    if not normalized then
        return nil
    end

    local tempItem = Registry.Internal.CreateTransientInventoryItem and Registry.Internal.CreateTransientInventoryItem(normalized.fullType) or nil
    if tempItem then
        Registry.Internal.ApplyEquipmentEntryState(tempItem, normalized)
    end

    local maintenanceLevel = getWorkerMaintenanceLevel(worker)
    local conditionAppliedToTempItem = false
    grantMaintenanceXP(worker, math.max(1, normalizeDamageMultiplier(damageMultiplier)))

    if normalized.condition ~= nil then
        local applied = false
        if tempItem and tempItem.damageCheck then
            local ok = pcall(function()
                tempItem:damageCheck(maintenanceLevel, normalizeDamageMultiplier(damageMultiplier), true)
            end)
            if ok then
                applied = true
                conditionAppliedToTempItem = true
            end
        end

        if not applied then
            local chance = tempItem and tempItem.getConditionLowerChance and tempItem:getConditionLowerChance() or 1
            local maintenanceBonus = 1 + (maintenanceLevel * 0.5)
            local rollMax = math.max(1, math.floor((tonumber(chance) or 1) * maintenanceBonus * normalizeDamageMultiplier(damageMultiplier)))
            if ZombRand(rollMax) == 0 then
                normalized.condition = math.max(0, math.floor(tonumber(normalized.condition) or 0) - 1)
            end
        end
    end

    if tempItem and tempItem.IsDrainable and tempItem:IsDrainable() then
        local useDelta = math.max(0, tonumber(tempItem.getUseDelta and tempItem:getUseDelta() or normalized.useDelta) or 0)
        if useDelta > 0 and tempItem.setUsedDelta then
            tempItem:setUsedDelta(math.max(0, (tonumber(tempItem.getUsedDelta and tempItem:getUsedDelta() or normalized.usedDelta) or 0) - useDelta))
        end

        if tempItem.setConditionFromHeadCondition and tempItem.hasHeadCondition and tempItem:hasHeadCondition() then
            pcall(function()
                tempItem:setConditionFromHeadCondition(tempItem)
            end)
        end

        if not conditionAppliedToTempItem and Registry.Internal.ApplyEquipmentEntryState then
            Registry.Internal.ApplyEquipmentEntryState(tempItem, {
                condition = normalized.condition,
                headCondition = normalized.headCondition,
                quality = normalized.quality,
                haveBeenRepaired = normalized.haveBeenRepaired,
            })
        end

        local rebuilt = Registry.Internal.BuildEquipmentEntryFromInventoryItem
            and Registry.Internal.BuildEquipmentEntryFromInventoryItem(tempItem, normalized.displayName)
            or nil
        if rebuilt then
            return rebuilt
        end
    elseif normalized.isDrainable == true then
        local useDelta = math.max(0, tonumber(normalized.useDelta) or 0)
        if useDelta > 0 then
            normalized.usedDelta = math.max(0, (tonumber(normalized.usedDelta) or 0) - useDelta)
        end
    end

    if tempItem and tempItem.setConditionFromHeadCondition and tempItem.hasHeadCondition and tempItem:hasHeadCondition() then
        pcall(function()
            tempItem:setConditionFromHeadCondition(tempItem)
        end)
    end

    if tempItem then
        if not conditionAppliedToTempItem and Registry.Internal.ApplyEquipmentEntryState then
            Registry.Internal.ApplyEquipmentEntryState(tempItem, {
                condition = normalized.condition,
                headCondition = normalized.headCondition,
                quality = normalized.quality,
                haveBeenRepaired = normalized.haveBeenRepaired,
            })
        end
        local rebuilt = Registry.Internal.BuildEquipmentEntryFromInventoryItem
            and Registry.Internal.BuildEquipmentEntryFromInventoryItem(tempItem, normalized.displayName)
            or nil
        if rebuilt then
            return rebuilt
        end
    end

    return Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry(normalized) or normalized
end

local function persistWearResult(worker, index, wornEntry, currentHour)
    if not worker or not index or not wornEntry then
        return false
    end

    if Registry.Internal.IsEquipmentEntryUsable and not Registry.Internal.IsEquipmentEntryUsable(wornEntry) then
        return moveBrokenToolToStorage(worker, index, wornEntry, currentHour)
    end

    worker.toolLedger[index] = wornEntry
    Registry.Internal.MarkToolCacheDirty(worker)
    return true
end

local function findFirstMatchingUsableTool(worker, requiredTag)
    for index, entry in ipairs(worker and worker.toolLedger or {}) do
        if Registry.Internal.IsEquipmentEntryUsable and Registry.Internal.IsEquipmentEntryUsable(entry) and entryMatchesToolTag(entry, requiredTag) then
            return index, entry
        end
    end
    return nil, nil
end

function Sim.ApplyWearForRequiredTools(worker, profile, currentHour, damageMultiplier)
    if not worker or type(profile) ~= "table" then
        return
    end

    for _, requiredTag in ipairs(profile.requiredToolTags or {}) do
        local index, entry = findFirstMatchingUsableTool(worker, requiredTag)
        if index and entry then
            local wornEntry = applyWearEvent(worker, entry, damageMultiplier)
            if wornEntry then
                persistWearResult(worker, index, wornEntry, currentHour)
            end
        end
    end
end

function Sim.ApplyWearForScavengeTools(worker, currentHour, damageMultiplier)
    if not worker then
        return
    end

    for index = #worker.toolLedger, 1, -1 do
        local entry = worker.toolLedger[index]
        local profile = entry and Config.GetScavengeItemProfile and Config.GetScavengeItemProfile(entry.fullType) or nil
        if profile and Registry.Internal.IsEquipmentEntryUsable and Registry.Internal.IsEquipmentEntryUsable(entry) then
            local wornEntry = applyWearEvent(worker, entry, damageMultiplier)
            if wornEntry then
                persistWearResult(worker, index, wornEntry, currentHour)
            end
        end
    end
end
