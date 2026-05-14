DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Data = Internal.Data or {}

Internal.Data = Data

local PROVISION_BUCKET_STEP = 5
local PROVISION_FLUID_BUCKET_STEP = 0.25
local EQUIPMENT_USED_DELTA_STEP = 0.02
local EQUIPMENT_PERCENT_BUCKET_STEP = 0.10
local EQUIPMENT_FLUID_BUCKET_STEP = 0.10
local WAREHOUSE_ITEMS_SCHEMA_VERSION = 4

local function roundToStep(value, step)
    local normalizedStep = math.max(0, tonumber(step) or 0)
    local normalizedValue = math.max(0, tonumber(value) or 0)
    if normalizedStep <= 0 then
        return normalizedValue
    end
    return math.floor((normalizedValue / normalizedStep) + 0.5) * normalizedStep
end

local function roundToDecimals(value, decimals)
    local places = math.max(0, math.floor(tonumber(decimals) or 0))
    local factor = math.pow(10, places)
    return math.floor((math.max(0, tonumber(value) or 0) * factor) + 0.5) / factor
end

local function buildProvisionEntryID()
    return tostring(Registry.Internal.GenerateLedgerEntryID and Registry.Internal.GenerateLedgerEntryID("prov") or "")
end

local function buildEquipmentEntryID()
    return tostring(Registry.Internal.GenerateLedgerEntryID and Registry.Internal.GenerateLedgerEntryID("eq") or "")
end

local function getPerItemAverage(total, qty, decimals)
    local normalizedQty = math.max(1, math.floor(tonumber(qty) or 1))
    return roundToDecimals((math.max(0, tonumber(total) or 0) / normalizedQty), decimals or 2)
end

local function copyEntry(source)
    local copied = {}
    for key, value in pairs(source or {}) do
        copied[key] = value
    end
    return copied
end

local function getEntrySchemaVersion(entry)
    local schemaVersion = math.floor(tonumber(entry and entry.schemaVersion) or 0)
    if schemaVersion > 0 then
        return schemaVersion
    end
    return Config.MOD_DATA_SCHEMA_VERSION or 3
end

function Data.GetWarehouseItemsSchemaVersion()
    return WAREHOUSE_ITEMS_SCHEMA_VERSION
end

function Data.RefreshProvisionAggregateState(entry)
    if type(entry) ~= "table" then
        return nil
    end

    entry.schemaVersion = math.max(WAREHOUSE_ITEMS_SCHEMA_VERSION, getEntrySchemaVersion(entry))
    entry.qty = math.max(1, math.floor(tonumber(entry.qty) or 1))
    entry.totalCaloriesRemaining = roundToDecimals(
        tonumber(entry.totalCaloriesRemaining) ~= nil
            and entry.totalCaloriesRemaining
            or ((math.max(0, tonumber(entry.caloriesRemaining) or 0)) * entry.qty),
        2
    )
    entry.totalHydrationRemaining = roundToDecimals(
        tonumber(entry.totalHydrationRemaining) ~= nil
            and entry.totalHydrationRemaining
            or ((math.max(0, tonumber(entry.hydrationRemaining) or 0)) * entry.qty),
        2
    )
    entry.totalTreatmentUnitsRemaining = math.max(
        0,
        roundToDecimals(
            tonumber(entry.totalTreatmentUnitsRemaining) ~= nil
                and entry.totalTreatmentUnitsRemaining
                or ((math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0)) * entry.qty),
            0
        )
    )
    entry.caloriesRemaining = getPerItemAverage(entry.totalCaloriesRemaining, entry.qty, 2)
    entry.hydrationRemaining = getPerItemAverage(entry.totalHydrationRemaining, entry.qty, 2)
    entry.treatmentUnitsRemaining = getPerItemAverage(entry.totalTreatmentUnitsRemaining, entry.qty, 0)
    return entry
end

function Data.RefreshEquipmentAggregateState(entry)
    if type(entry) ~= "table" then
        return nil
    end

    entry.schemaVersion = math.max(WAREHOUSE_ITEMS_SCHEMA_VERSION, getEntrySchemaVersion(entry))
    entry.qty = math.max(1, math.floor(tonumber(entry.qty) or 1))

    if entry.condition ~= nil or entry.totalCondition ~= nil then
        entry.totalCondition = math.max(
            0,
            roundToDecimals(
                tonumber(entry.totalCondition) ~= nil
                    and entry.totalCondition
                    or ((math.max(0, tonumber(entry.condition) or 0)) * entry.qty),
                0
            )
        )
        entry.condition = math.floor(getPerItemAverage(entry.totalCondition, entry.qty, 0) + 0.5)
    else
        entry.totalCondition = nil
    end

    if entry.headCondition ~= nil or entry.totalHeadCondition ~= nil then
        entry.totalHeadCondition = math.max(
            0,
            roundToDecimals(
                tonumber(entry.totalHeadCondition) ~= nil
                    and entry.totalHeadCondition
                    or ((math.max(0, tonumber(entry.headCondition) or 0)) * entry.qty),
                0
            )
        )
        entry.headCondition = math.floor(getPerItemAverage(entry.totalHeadCondition, entry.qty, 0) + 0.5)
    else
        entry.totalHeadCondition = nil
    end

    if entry.usedDelta ~= nil or entry.totalUsedDelta ~= nil then
        entry.totalUsedDelta = roundToDecimals(
            tonumber(entry.totalUsedDelta) ~= nil
                and entry.totalUsedDelta
                or ((math.max(0, tonumber(entry.usedDelta) or 0)) * entry.qty),
            4
        )
        entry.usedDelta = getPerItemAverage(entry.totalUsedDelta, entry.qty, 4)
    else
        entry.totalUsedDelta = nil
    end

    if entry.fluidAmount ~= nil or entry.totalFluidAmount ~= nil then
        entry.totalFluidAmount = roundToDecimals(
            tonumber(entry.totalFluidAmount) ~= nil
                and entry.totalFluidAmount
                or ((math.max(0, tonumber(entry.fluidAmount) or 0)) * entry.qty),
            4
        )
        entry.fluidAmount = getPerItemAverage(entry.totalFluidAmount, entry.qty, 4)
    else
        entry.totalFluidAmount = nil
    end

    return entry
end

function Data.NormalizeProvisionEntry(entry)
    if type(entry) ~= "table" or not entry.fullType then
        return nil
    end

    local normalized = {
        schemaVersion = math.max(WAREHOUSE_ITEMS_SCHEMA_VERSION, getEntrySchemaVersion(entry)),
        fullType = tostring(entry.fullType),
        entryID = tostring(entry.entryID or buildProvisionEntryID()),
        displayName = entry.displayName or Registry.Internal.GetDisplayNameForFullType(entry.fullType),
        provisionType = Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) and "medical" or tostring(entry.provisionType or "nutrition"),
        caloriesRemaining = math.max(0, tonumber(entry.caloriesRemaining) or 0),
        hydrationRemaining = math.max(0, tonumber(entry.hydrationRemaining) or 0),
        treatmentUnitsRemaining = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0),
        medicalUse = entry.medicalUse and tostring(entry.medicalUse) or nil,
        qty = math.max(1, math.floor(tonumber(entry.qty) or 1)),
        totalCaloriesRemaining = tonumber(entry.totalCaloriesRemaining),
        totalHydrationRemaining = tonumber(entry.totalHydrationRemaining),
        totalTreatmentUnitsRemaining = tonumber(entry.totalTreatmentUnitsRemaining),
    }
    if entry.consumedOutputFullType then
        normalized.consumedOutputFullType = tostring(entry.consumedOutputFullType)
        normalized.consumedOutputDisplayName = tostring(entry.consumedOutputDisplayName or Registry.Internal.GetDisplayNameForFullType(entry.consumedOutputFullType))
        if entry.consumedOutputFluidAmount ~= nil then
            normalized.consumedOutputFluidAmount = math.max(0, tonumber(entry.consumedOutputFluidAmount) or 0)
        end
    end
    return Data.RefreshProvisionAggregateState(normalized)
end

function Data.NormalizeEquipmentEntry(entry)
    local normalized = Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry(entry) or nil
    if not normalized then
        return nil
    end

    normalized.schemaVersion = math.max(WAREHOUSE_ITEMS_SCHEMA_VERSION, getEntrySchemaVersion(entry or normalized))
    normalized.totalCondition = tonumber(entry and entry.totalCondition)
    normalized.totalHeadCondition = tonumber(entry and entry.totalHeadCondition)
    normalized.totalUsedDelta = tonumber(entry and entry.totalUsedDelta)
    normalized.totalFluidAmount = tonumber(entry and entry.totalFluidAmount)
    if not normalized.entryID or normalized.entryID == "" then
        normalized.entryID = buildEquipmentEntryID()
    end
    return Data.RefreshEquipmentAggregateState(normalized)
end

function Data.NormalizeOutputEntry(entry)
    return Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or nil
end

function Data.GetProvisionBucketKey(entry)
    local normalized = Data.NormalizeProvisionEntry(entry)
    if not normalized then
        return ""
    end

    return table.concat({
        normalized.fullType,
        normalized.provisionType or "",
        tostring(roundToStep(normalized.caloriesRemaining or 0, PROVISION_BUCKET_STEP)),
        tostring(roundToStep(normalized.hydrationRemaining or 0, PROVISION_BUCKET_STEP)),
        tostring(roundToStep(normalized.treatmentUnitsRemaining or 0, 1)),
        tostring(normalized.medicalUse or ""),
        tostring(normalized.consumedOutputFullType or ""),
        tostring(normalized.consumedOutputDisplayName or ""),
        tostring(normalized.consumedOutputFluidAmount ~= nil and roundToStep(normalized.consumedOutputFluidAmount, PROVISION_FLUID_BUCKET_STEP) or "")
    }, "|")
end

function Data.GetEquipmentStackKey(entry)
    local normalized = Data.NormalizeEquipmentEntry(entry)
    if not normalized then
        return ""
    end

    local conditionRatio = 0
    if normalized.conditionMax and normalized.conditionMax > 0 then
        conditionRatio = (math.max(0, tonumber(normalized.condition) or 0) / normalized.conditionMax)
    end

    local headConditionRatio = 0
    if normalized.headConditionMax and normalized.headConditionMax > 0 then
        headConditionRatio = (math.max(0, tonumber(normalized.headCondition) or 0) / normalized.headConditionMax)
    end

    local fluidRatio = 0
    if normalized.fluidCapacity and normalized.fluidCapacity > 0 then
        fluidRatio = (math.max(0, tonumber(normalized.fluidAmount) or 0) / normalized.fluidCapacity)
    end

    return table.concat({
        tostring(normalized.fullType or ""),
        tostring(normalized.conditionMax or ""),
        tostring(roundToStep(conditionRatio, EQUIPMENT_PERCENT_BUCKET_STEP)),
        tostring(normalized.headConditionMax or ""),
        tostring(roundToStep(headConditionRatio, EQUIPMENT_PERCENT_BUCKET_STEP)),
        tostring(normalized.isDrainable == true and "1" or "0"),
        tostring(normalized.useDelta ~= nil and string.format("%.4f", normalized.useDelta) or ""),
        tostring(normalized.usedDelta ~= nil and string.format("%.2f", roundToStep(normalized.usedDelta, EQUIPMENT_USED_DELTA_STEP)) or ""),
        tostring(normalized.keepOnDeplete == true and "1" or "0"),
        tostring(normalized.quality ~= nil and normalized.quality or ""),
        tostring(normalized.haveBeenRepaired ~= nil and normalized.haveBeenRepaired or ""),
        tostring(normalized.fluidCapacity ~= nil and string.format("%.4f", normalized.fluidCapacity) or ""),
        tostring(normalized.fluidAmount ~= nil and string.format("%.2f", roundToStep(fluidRatio, EQUIPMENT_FLUID_BUCKET_STEP)) or ""),
    }, "|")
end

function Data.MergeProvisionEntries(existing, incoming)
    local target = Data.NormalizeProvisionEntry(existing)
    local source = Data.NormalizeProvisionEntry(incoming)
    if not target or not source then
        return target
    end

    target.qty = target.qty + source.qty
    target.totalCaloriesRemaining = (target.totalCaloriesRemaining or 0) + (source.totalCaloriesRemaining or 0)
    target.totalHydrationRemaining = (target.totalHydrationRemaining or 0) + (source.totalHydrationRemaining or 0)
    target.totalTreatmentUnitsRemaining = (target.totalTreatmentUnitsRemaining or 0) + (source.totalTreatmentUnitsRemaining or 0)
    return Data.RefreshProvisionAggregateState(target)
end

function Data.MergeEquipmentEntries(existing, incoming)
    local target = Data.NormalizeEquipmentEntry(existing)
    local source = Data.NormalizeEquipmentEntry(incoming)
    if not target or not source then
        return target
    end

    target.qty = target.qty + source.qty
    if source.totalCondition ~= nil then
        target.totalCondition = math.max(0, tonumber(target.totalCondition) or 0) + math.max(0, tonumber(source.totalCondition) or 0)
    end
    if source.totalHeadCondition ~= nil then
        target.totalHeadCondition = math.max(0, tonumber(target.totalHeadCondition) or 0) + math.max(0, tonumber(source.totalHeadCondition) or 0)
    end
    if source.totalUsedDelta ~= nil then
        target.totalUsedDelta = roundToDecimals((tonumber(target.totalUsedDelta) or 0) + (tonumber(source.totalUsedDelta) or 0), 4)
    end
    if source.totalFluidAmount ~= nil then
        target.totalFluidAmount = roundToDecimals((tonumber(target.totalFluidAmount) or 0) + (tonumber(source.totalFluidAmount) or 0), 4)
    end
    return Data.RefreshEquipmentAggregateState(target)
end

local function assignSplitValue(remainingTotal, remainingItems, decimals)
    if remainingItems <= 1 then
        return roundToDecimals(remainingTotal, decimals)
    end
    local value = roundToDecimals((remainingTotal / remainingItems), decimals)
    if value > remainingTotal then
        return roundToDecimals(remainingTotal, decimals)
    end
    return value
end

function Data.TakeProvisionQuantity(entry, requestedQty)
    local normalized = Data.NormalizeProvisionEntry(entry)
    if not normalized then
        return {}, nil
    end

    local qty = math.max(1, math.floor(tonumber(normalized.qty) or 1))
    local takeQty = math.max(0, math.min(qty, math.floor(tonumber(requestedQty) or qty)))
    if takeQty <= 0 then
        return {}, normalized
    end

    local remainingCalories = math.max(0, tonumber(normalized.totalCaloriesRemaining) or 0)
    local remainingHydration = math.max(0, tonumber(normalized.totalHydrationRemaining) or 0)
    local remainingUnits = math.max(0, tonumber(normalized.totalTreatmentUnitsRemaining) or 0)
    local removed = {}

    for index = 1, takeQty do
        local itemsLeft = takeQty - index + 1
        local removedEntry = copyEntry(normalized)
        removedEntry.entryID = buildProvisionEntryID()
        removedEntry.qty = 1
        removedEntry.totalCaloriesRemaining = assignSplitValue(remainingCalories, itemsLeft, 2)
        removedEntry.totalHydrationRemaining = assignSplitValue(remainingHydration, itemsLeft, 2)
        removedEntry.totalTreatmentUnitsRemaining = assignSplitValue(remainingUnits, itemsLeft, 0)
        remainingCalories = roundToDecimals(remainingCalories - removedEntry.totalCaloriesRemaining, 2)
        remainingHydration = roundToDecimals(remainingHydration - removedEntry.totalHydrationRemaining, 2)
        remainingUnits = math.max(0, roundToDecimals(remainingUnits - removedEntry.totalTreatmentUnitsRemaining, 0))
        removed[#removed + 1] = Data.RefreshProvisionAggregateState(removedEntry)
    end

    normalized.qty = qty - takeQty
    normalized.totalCaloriesRemaining = remainingCalories
    normalized.totalHydrationRemaining = remainingHydration
    normalized.totalTreatmentUnitsRemaining = remainingUnits
    if normalized.qty <= 0 then
        normalized = nil
    else
        normalized = Data.RefreshProvisionAggregateState(normalized)
    end

    return removed, normalized
end

function Data.TakeEquipmentQuantity(entry, requestedQty)
    local normalized = Data.NormalizeEquipmentEntry(entry)
    if not normalized then
        return {}, nil
    end

    local qty = math.max(1, math.floor(tonumber(normalized.qty) or 1))
    local takeQty = math.max(0, math.min(qty, math.floor(tonumber(requestedQty) or qty)))
    if takeQty <= 0 then
        return {}, normalized
    end

    local remainingCondition = math.max(0, tonumber(normalized.totalCondition) or 0)
    local remainingHeadCondition = math.max(0, tonumber(normalized.totalHeadCondition) or 0)
    local remainingUsedDelta = math.max(0, tonumber(normalized.totalUsedDelta) or 0)
    local remainingFluidAmount = math.max(0, tonumber(normalized.totalFluidAmount) or 0)
    local removed = {}

    for index = 1, takeQty do
        local itemsLeft = takeQty - index + 1
        local removedEntry = copyEntry(normalized)
        removedEntry.entryID = buildEquipmentEntryID()
        removedEntry.qty = 1
        if normalized.totalCondition ~= nil then
            removedEntry.totalCondition = assignSplitValue(remainingCondition, itemsLeft, 0)
            remainingCondition = math.max(0, roundToDecimals(remainingCondition - removedEntry.totalCondition, 0))
        end
        if normalized.totalHeadCondition ~= nil then
            removedEntry.totalHeadCondition = assignSplitValue(remainingHeadCondition, itemsLeft, 0)
            remainingHeadCondition = math.max(0, roundToDecimals(remainingHeadCondition - removedEntry.totalHeadCondition, 0))
        end
        if normalized.totalUsedDelta ~= nil then
            removedEntry.totalUsedDelta = assignSplitValue(remainingUsedDelta, itemsLeft, 4)
            remainingUsedDelta = math.max(0, roundToDecimals(remainingUsedDelta - removedEntry.totalUsedDelta, 4))
        end
        if normalized.totalFluidAmount ~= nil then
            removedEntry.totalFluidAmount = assignSplitValue(remainingFluidAmount, itemsLeft, 4)
            remainingFluidAmount = math.max(0, roundToDecimals(remainingFluidAmount - removedEntry.totalFluidAmount, 4))
        end
        removed[#removed + 1] = Data.RefreshEquipmentAggregateState(removedEntry)
    end

    normalized.qty = qty - takeQty
    normalized.totalCondition = normalized.totalCondition ~= nil and remainingCondition or nil
    normalized.totalHeadCondition = normalized.totalHeadCondition ~= nil and remainingHeadCondition or nil
    normalized.totalUsedDelta = normalized.totalUsedDelta ~= nil and remainingUsedDelta or nil
    normalized.totalFluidAmount = normalized.totalFluidAmount ~= nil and remainingFluidAmount or nil
    if normalized.qty <= 0 then
        normalized = nil
    else
        normalized = Data.RefreshEquipmentAggregateState(normalized)
    end

    return removed, normalized
end

function Data.StackProvisionEntries(entries)
    local stacked = {}
    local byKey = {}

    for _, raw in ipairs(entries or {}) do
        local entry = Data.NormalizeProvisionEntry(raw)
        if entry then
            local key = Data.GetProvisionBucketKey(entry)
            local existing = byKey[key]
            if existing then
                Data.MergeProvisionEntries(existing, entry)
            else
                byKey[key] = entry
                stacked[#stacked + 1] = entry
            end
        end
    end

    return stacked
end

function Data.StackEquipmentEntries(entries)
    local stacked = {}
    local byKey = {}

    for _, raw in ipairs(entries or {}) do
        local entry = Data.NormalizeEquipmentEntry(raw)
        if entry then
            local key = Data.GetEquipmentStackKey(entry)
            local existing = byKey[key]
            if existing then
                Data.MergeEquipmentEntries(existing, entry)
            else
                byKey[key] = entry
                stacked[#stacked + 1] = entry
            end
        end
    end

    return stacked
end

function Data.StackOutputEntries(entries)
    local stacked = {}
    local byKey = {}

    for _, raw in ipairs(entries or {}) do
        local entry = Data.NormalizeOutputEntry(raw)
        if entry then
            local key = Registry.Internal.GetOutputEntryStateSignature and Registry.Internal.GetOutputEntryStateSignature(entry)
                or entry.fullType
            local existing = byKey[key]
            if existing then
                existing.qty = existing.qty + entry.qty
            else
                byKey[key] = entry
                stacked[#stacked + 1] = entry
            end
        end
    end

    return stacked
end

function Data.StackLiteralSpecialEntries(entries)
    local stacked = {}
    local byKey = {}

    for _, raw in ipairs(entries or {}) do
        local entry = Data.NormalizeOutputEntry(raw)
        if entry and entry.literalSpecial == true then
            local key = Registry.Internal.GetOutputEntryStateSignature and Registry.Internal.GetOutputEntryStateSignature(entry)
                or entry.fullType
            local existing = byKey[key]
            if existing then
                existing.qty = existing.qty + entry.qty
            else
                byKey[key] = entry
                stacked[#stacked + 1] = entry
            end
        end
    end

    return stacked
end

Internal.NormalizeProvisionEntry = Data.NormalizeProvisionEntry
Internal.NormalizeEquipmentEntry = Data.NormalizeEquipmentEntry
Internal.NormalizeOutputEntry = Data.NormalizeOutputEntry

return Warehouse
