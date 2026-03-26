DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function boolKey(value)
    return value == true and "1" or "0"
end

local function normalizeTagKey(tags)
    if type(tags) ~= "table" or #tags <= 0 then
        return ""
    end

    local values = {}
    for _, tag in ipairs(tags) do
        values[#values + 1] = tostring(tag or "")
    end
    table.sort(values)
    return table.concat(values, ",")
end

local function canGroupEntry(entry)
    return entry
        and entry.kind ~= "money"
        and entry.kind ~= "placeholder"
        and entry.kind ~= "group"
end

local function getStateGroupKey(entry, activeTab)
    local registryInternal = DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
    if activeTab == Internal.Tabs.Equipment then
        if not registryInternal or not registryInternal.GetEquipmentDurabilitySignature then
            return ""
        end
        return registryInternal.GetEquipmentDurabilitySignature(entry)
    end

    if activeTab == Internal.Tabs.Output then
        if not registryInternal or not registryInternal.GetOutputEntryStateSignature then
            return ""
        end
        return registryInternal.GetOutputEntryStateSignature(entry)
    end

    return ""
end

local function getDurabilityGroupKey(entry, activeTab)
    if activeTab ~= Internal.Tabs.Equipment and activeTab ~= Internal.Tabs.Output then
        return ""
    end
    return getStateGroupKey(entry, activeTab)
end

local function buildGroupKey(entry, activeTab, side)
    local parts = {
        tostring(side or "player"),
        tostring(activeTab or Internal.Tabs.Provisions),
        tostring(entry.kind or ""),
        tostring(entry.fullType or ""),
        tostring(entry.displayName or ""),
        tostring(entry.provisionType or ""),
        boolKey(entry.canDeposit),
        boolKey(entry.canAssignTool),
        boolKey(entry.pending),
        normalizeTagKey(entry.tags),
        getDurabilityGroupKey(entry, activeTab),
    }
    return table.concat(parts, "|")
end

local function getExpansionField(side)
    return side == "worker" and "workerExpandedGroups" or "playerExpandedGroups"
end

local function getSelectionField(side)
    return side == "worker" and "selectedWorkerEntry" or "selectedPlayerEntry"
end

function Internal.isGroupEntry(entry)
    return type(entry) == "table" and entry.kind == "group"
end

function Internal.getEntrySelectionKey(entry)
    if not entry then
        return nil
    end

    if Internal.isGroupEntry(entry) then
        return "group:" .. tostring(entry.groupKey or "")
    end

    if entry.kind == "placeholder" then
        return "placeholder:" .. tostring(entry.requirementKey or entry.ledgerIndex or entry.displayName or entry.fullType or "")
    end

    return tostring(entry.itemID or entry.ledgerIndex or entry.fullType or entry.displayName or "")
end

function Internal.getGroupedEntryChildren(entry)
    if not entry then
        return {}
    end

    if Internal.isGroupEntry(entry) then
        return entry.childEntries or {}
    end

    return { entry }
end

function Internal.getExpandedGroupState(window, side)
    if not window then
        return {}
    end

    local field = getExpansionField(side)
    window[field] = window[field] or {}
    return window[field]
end

function Internal.isGroupExpanded(window, side, groupKey)
    return Internal.getExpandedGroupState(window, side)[tostring(groupKey or "")] == true
end

function Internal.toggleGroupExpanded(window, side, entry)
    if not window or not Internal.isGroupEntry(entry) then
        return
    end

    local expansionState = Internal.getExpandedGroupState(window, side)
    local key = tostring(entry.groupKey or "")
    expansionState[key] = not expansionState[key]

    if side == "worker" then
        window:rebuildWorkerList()
    else
        window:rebuildPlayerList()
    end
end

function Internal.buildGroupedRows(entries, activeTab, side, window)
    local grouped = {}
    local sequence = {}
    local rows = {}

    for _, entry in ipairs(entries or {}) do
        entry.groupChild = nil
        entry.groupParentKey = nil

        if canGroupEntry(entry) then
            local groupKey = buildGroupKey(entry, activeTab, side)
            local group = grouped[groupKey]
            if not group then
                group = {
                    key = groupKey,
                    entries = {},
                }
                grouped[groupKey] = group
                sequence[#sequence + 1] = group
            end
            group.entries[#group.entries + 1] = entry
        else
            sequence[#sequence + 1] = entry
        end
    end

    for _, part in ipairs(sequence) do
        if type(part) == "table" and part.entries then
            local entriesForGroup = part.entries
            if #entriesForGroup <= 1 then
                rows[#rows + 1] = entriesForGroup[1]
            else
                local first = entriesForGroup[1]
                local header = {
                    kind = "group",
                    side = side,
                    groupKey = part.key,
                    displayName = first.displayName,
                    fullType = first.fullType,
                    provisionType = first.provisionType,
                    texture = first.texture or (Internal.getTextureForFullType and Internal.getTextureForFullType(first.fullType) or nil),
                    childEntries = entriesForGroup,
                    childCount = #entriesForGroup,
                    totalWeight = 0,
                    totalCalories = 0,
                    totalHydration = 0,
                    totalTreatmentUnits = 0,
                    totalQty = 0,
                    calories = 0,
                    hydration = 0,
                    treatmentUnits = 0,
                    qty = 0,
                    amount = 0,
                    canDeposit = false,
                    canAssignTool = false,
                    provisionBlockedReason = first.provisionBlockedReason,
                    isRottenProvision = first.isRottenProvision == true,
                    hasEquipmentRequirementMatch = first.hasEquipmentRequirementMatch == true,
                    isUsableEquipment = first.isUsableEquipment == true,
                    pending = false,
                    tags = first.tags or {},
                    condition = first.condition,
                    conditionMax = first.conditionMax,
                    isDrainable = first.isDrainable == true,
                    useDelta = first.useDelta,
                    usedDelta = first.usedDelta,
                    keepOnDeplete = first.keepOnDeplete == true,
                }

                for _, child in ipairs(entriesForGroup) do
                    header.totalWeight = header.totalWeight + math.max(0, tonumber(child.totalWeight) or tonumber(child.unitWeight) or 0)
                    header.totalCalories = header.totalCalories + math.max(0, tonumber(child.calories) or 0)
                    header.totalHydration = header.totalHydration + math.max(0, tonumber(child.hydration) or 0)
                    header.totalTreatmentUnits = header.totalTreatmentUnits + math.max(0, tonumber(child.treatmentUnits) or 0)
                    header.totalQty = header.totalQty + math.max(1, tonumber(child.qty) or 1)
                    header.amount = header.amount + math.max(0, tonumber(child.amount) or 0)
                    header.canDeposit = header.canDeposit or child.canDeposit == true
                    header.canAssignTool = header.canAssignTool or child.canAssignTool == true
                    header.isRottenProvision = header.isRottenProvision or child.isRottenProvision == true
                    if tostring(header.provisionBlockedReason or "") == "" and tostring(child.provisionBlockedReason or "") ~= "" then
                        header.provisionBlockedReason = child.provisionBlockedReason
                    end
                    header.hasEquipmentRequirementMatch = header.hasEquipmentRequirementMatch or child.hasEquipmentRequirementMatch == true
                    header.isUsableEquipment = header.isUsableEquipment or child.isUsableEquipment == true
                    header.pending = header.pending or child.pending == true
                end

                header.calories = header.totalCalories
                header.hydration = header.totalHydration
                header.treatmentUnits = header.totalTreatmentUnits
                header.qty = header.totalQty

                rows[#rows + 1] = header

                if Internal.isGroupExpanded(window, side, part.key) then
                    for _, child in ipairs(entriesForGroup) do
                        child.groupChild = true
                        child.groupParentKey = part.key
                        rows[#rows + 1] = child
                    end
                end
            end
        else
            rows[#rows + 1] = part
        end
    end

    return rows
end

function Internal.getConcreteTransferEntries(entry)
    local expanded = Internal.getGroupedEntryChildren(entry)
    local result = {}
    for _, child in ipairs(expanded) do
        if child and not Internal.isGroupEntry(child) then
            result[#result + 1] = child
        end
    end
    return result
end

function Internal.setSelectedEntry(window, side, entry)
    if not window then
        return
    end

    window[getSelectionField(side)] = entry
end
