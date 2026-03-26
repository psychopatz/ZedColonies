DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Nutrition = DC_Colony.Nutrition
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal

local function getProvisionStackKey(entry)
    return table.concat({
        tostring(entry and entry.fullType or ""),
        tostring(entry and entry.provisionType or ""),
        tostring(math.max(0, tonumber(entry and entry.caloriesRemaining) or 0)),
        tostring(math.max(0, tonumber(entry and entry.hydrationRemaining) or 0)),
        tostring(math.max(0, tonumber(entry and entry.treatmentUnitsRemaining) or 0)),
        tostring(entry and entry.medicalUse or ""),
        tostring(entry and entry.consumedOutputFullType or ""),
        tostring(entry and entry.consumedOutputDisplayName or ""),
        tostring(entry and entry.consumedOutputFluidAmount ~= nil and string.format("%.4f", entry.consumedOutputFluidAmount) or "")
    }, "|")
end

local function appendProvisionEntry(warehouse, entry)
    if not warehouse or not entry or not entry.fullType then
        return false
    end

    local weight = Internal.GetEntryWeight(entry.fullType, 1)
    if weight > 0 and weight > Warehouse.GetRemainingCapacity(warehouse) then
        return false
    end

    local normalized = {
        fullType = entry.fullType,
        displayName = entry.displayName or Registry.Internal.GetDisplayNameForFullType(entry.fullType),
        provisionType = Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) and "medical" or "nutrition",
        caloriesRemaining = math.max(0, tonumber(entry.caloriesRemaining) or 0),
        hydrationRemaining = math.max(0, tonumber(entry.hydrationRemaining) or 0),
        treatmentUnitsRemaining = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0),
        medicalUse = Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) and tostring(entry.medicalUse or "bandage") or nil,
        qty = math.max(1, math.floor(tonumber(entry.qty) or 1))
    }
    if entry.consumedOutputFullType then
        normalized.consumedOutputFullType = tostring(entry.consumedOutputFullType)
        normalized.consumedOutputDisplayName = tostring(entry.consumedOutputDisplayName or Registry.Internal.GetDisplayNameForFullType(entry.consumedOutputFullType))
        if entry.consumedOutputFluidAmount ~= nil then
            normalized.consumedOutputFluidAmount = math.max(0, tonumber(entry.consumedOutputFluidAmount) or 0)
        end
    end

    local stackKey = getProvisionStackKey(normalized)
    for _, existing in ipairs(warehouse.ledgers.provisions) do
        if getProvisionStackKey(existing) == stackKey then
            existing.qty = math.max(1, math.floor(tonumber(existing.qty) or 1)) + normalized.qty
            Warehouse.TouchItemsVersion(warehouse.ownerUsername)
            Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
            Warehouse.Recalculate(warehouse)
            return true
        end
    end

    warehouse.ledgers.provisions[#warehouse.ledgers.provisions + 1] = normalized
    Warehouse.TouchItemsVersion(warehouse.ownerUsername)
    Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
    Warehouse.Recalculate(warehouse)
    return true
end

local function appendEquipmentEntry(warehouse, entry, ignoreCapacity)
    if not warehouse or not entry or not entry.fullType then
        return false
    end

    local normalized = Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry(entry) or nil
    if not normalized then
        return false
    end

    local weight = Internal.GetEntryWeight(normalized.fullType, 1)
    if ignoreCapacity ~= true and weight > 0 and weight > Warehouse.GetRemainingCapacity(warehouse) then
        return false
    end

    warehouse.ledgers.equipment[#warehouse.ledgers.equipment + 1] = normalized
    Warehouse.TouchItemsVersion(warehouse.ownerUsername)
    Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
    Warehouse.Recalculate(warehouse)
    return true
end

local function mergeOutputEntry(warehouse, entry)
    local normalized = Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or nil
    if not warehouse or not normalized or not normalized.fullType then
        return 0
    end

    local qty = math.max(1, tonumber(normalized.qty) or 1)
    local unitWeight = Internal.GetEntryWeight(normalized.fullType, 1)
    local remainingCapacity = Warehouse.GetRemainingCapacity(warehouse)
    local fitQty = qty

    if unitWeight > 0 and remainingCapacity < (unitWeight * qty) then
        fitQty = math.floor(remainingCapacity / unitWeight)
    end

    if fitQty <= 0 and unitWeight > 0 then
        return 0
    end
    if fitQty <= 0 then
        fitQty = qty
    end

    local stackKey = Registry.Internal.GetOutputEntryStateSignature and Registry.Internal.GetOutputEntryStateSignature(normalized)
        or normalized.fullType
    for _, existing in ipairs(warehouse.ledgers.output) do
        local existingKey = Registry.Internal.GetOutputEntryStateSignature and Registry.Internal.GetOutputEntryStateSignature(existing)
            or tostring(existing and existing.fullType or "")
        if existingKey == stackKey then
            existing.qty = math.max(1, tonumber(existing.qty) or 1) + fitQty
            Warehouse.TouchItemsVersion(warehouse.ownerUsername)
            Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
            Warehouse.Recalculate(warehouse)
            return fitQty
        end
    end

    normalized.qty = fitQty
    warehouse.ledgers.output[#warehouse.ledgers.output + 1] = normalized
    Warehouse.TouchItemsVersion(warehouse.ownerUsername)
    Warehouse.TouchSummaryVersion(warehouse.ownerUsername)
    Warehouse.Recalculate(warehouse)
    return fitQty
end

local function buildProvisionEntryFromFullType(fullType)
    if Nutrition and Nutrition.BuildEntryFromItem and Nutrition.Internal and Nutrition.Internal.CreateItemByFullType then
        local createdItem = Nutrition.Internal.CreateItemByFullType(fullType)
        local entry = createdItem and Nutrition.BuildEntryFromItem(createdItem) or nil
        if entry then
            return entry
        end
    end

    if Config.IsMedicalProvisionFullType and Config.IsMedicalProvisionFullType(fullType) then
        return {
            fullType = fullType,
            displayName = Registry.Internal.GetDisplayNameForFullType(fullType),
            provisionType = "medical",
            medicalUse = "bandage",
            treatmentUnitsRemaining = Config.GetMedicalProvisionUnits and Config.GetMedicalProvisionUnits(fullType) or 0
        }
    end

    local calories, hydration = 0, 0
    local nutritionInternal = Nutrition and Nutrition.Internal or nil
    if nutritionInternal and nutritionInternal.GetExpectedStaticNutritionForFullType then
        calories, hydration = nutritionInternal.GetExpectedStaticNutritionForFullType(fullType)
    end

    calories = math.max(0, tonumber(calories) or 0)
    hydration = math.max(0, tonumber(hydration) or 0)
    if calories <= 0 and hydration <= 0 then
        return nil
    end

    return {
        fullType = fullType,
        displayName = Registry.Internal.GetDisplayNameForFullType(fullType),
        provisionType = "nutrition",
        caloriesRemaining = calories,
        hydrationRemaining = hydration
    }
end

local function buildEquipmentEntryFromFullType(fullType)
    if not fullType then
        return nil
    end

    return Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry({
        fullType = fullType,
        displayName = Registry.Internal.GetDisplayNameForFullType(fullType),
        tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(fullType)) or {}
    }) or nil
end

function Warehouse.DepositProvisionEntry(ownerUsername, entry)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return appendProvisionEntry(warehouse, entry)
end

function Warehouse.DepositEquipmentEntry(ownerUsername, entry, ignoreCapacity)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return appendEquipmentEntry(warehouse, entry, ignoreCapacity)
end

function Warehouse.DepositOutputEntry(ownerUsername, entry)
    if not entry or not entry.fullType then
        return 0
    end
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    return mergeOutputEntry(warehouse, entry)
end

function Warehouse.DepositHaulEntry(ownerUsername, entry)
    if not entry or not entry.fullType then
        return 0, 0
    end

    local fullType = entry.fullType
    local totalQty = math.max(1, tonumber(entry.qty) or 1)
    local movedQty = 0
    if Config.IsMedicalProvisionFullType and Config.IsMedicalProvisionFullType(fullType) then
        local provisionEntry = buildProvisionEntryFromFullType(fullType)
        if provisionEntry then
            for _ = 1, totalQty do
                if not Warehouse.DepositProvisionEntry(ownerUsername, provisionEntry) then
                    break
                end
                movedQty = movedQty + 1
            end
        end
    else
        local calories, hydration = 0, 0
        local nutritionInternal = Nutrition and Nutrition.Internal or nil
        if nutritionInternal and nutritionInternal.GetExpectedStaticNutritionForFullType then
            calories, hydration = nutritionInternal.GetExpectedStaticNutritionForFullType(fullType)
        end

        if math.max(0, tonumber(calories) or 0) > 0 or math.max(0, tonumber(hydration) or 0) > 0 then
        local provisionEntry = buildProvisionEntryFromFullType(fullType)
        if provisionEntry then
            for _ = 1, totalQty do
                if not Warehouse.DepositProvisionEntry(ownerUsername, provisionEntry) then
                    break
                end
                movedQty = movedQty + 1
            end
        end
        elseif Config.IsColonyToolFullType and Config.IsColonyToolFullType(fullType) then
            local equipmentEntry = buildEquipmentEntryFromFullType(fullType)
            if equipmentEntry then
                for _ = 1, totalQty do
                    if not Warehouse.DepositEquipmentEntry(ownerUsername, equipmentEntry) then
                        break
                    end
                    movedQty = movedQty + 1
                end
            end
        else
            movedQty = Warehouse.DepositOutputEntry(ownerUsername, entry)
        end
    end

    return movedQty, math.max(0, totalQty - movedQty)
end

function Warehouse.DepositWorkerHaul(worker)
    if not worker then
        return 0, 0, 0, 0
    end

    local remainingEntries = {}
    local movedStacks = 0
    local movedCount = 0
    local movedWeight = 0
    local leftoverCount = 0

    for _, entry in ipairs(worker.haulLedger or {}) do
        local qty = math.max(1, tonumber(entry.qty) or 1)
        local movedQty, leftoverQty = Warehouse.DepositHaulEntry(worker.ownerUsername, entry)
        if movedQty > 0 then
            movedStacks = movedStacks + 1
            movedCount = movedCount + movedQty
            movedWeight = movedWeight + Internal.GetEntryWeight(entry.fullType, movedQty)
        end
        if leftoverQty > 0 then
            leftoverCount = leftoverCount + leftoverQty
            local leftoverEntry = Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or Registry.Internal.CopyShallow(entry)
            leftoverEntry.qty = leftoverQty
            remainingEntries[#remainingEntries + 1] = leftoverEntry
        elseif movedQty <= 0 then
            leftoverCount = leftoverCount + qty
            local leftoverEntry = Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or Registry.Internal.CopyShallow(entry)
            leftoverEntry.qty = qty
            remainingEntries[#remainingEntries + 1] = leftoverEntry
        end
    end

    worker.haulLedger = remainingEntries
    return movedStacks, movedCount, movedWeight, leftoverCount
end

function Warehouse.DepositWorkerOutput(worker)
    if not worker then
        return 0, 0, 0, 0
    end

    local remainingEntries = {}
    local movedStacks = 0
    local movedCount = 0
    local movedWeight = 0
    local leftoverCount = 0

    for _, entry in ipairs(worker.outputLedger or {}) do
        local normalized = Registry.Internal.NormalizeOutputEntry and Registry.Internal.NormalizeOutputEntry(entry) or nil
        if normalized then
            local requestedQty = math.max(1, tonumber(normalized.qty) or 1)
            local movedQty = Warehouse.DepositOutputEntry(worker.ownerUsername, normalized)
            if movedQty > 0 then
                movedStacks = movedStacks + 1
                movedCount = movedCount + movedQty
                movedWeight = movedWeight + Internal.GetEntryWeight(normalized.fullType, movedQty)
            end

            local leftoverQty = requestedQty - movedQty
            if leftoverQty > 0 then
                leftoverCount = leftoverCount + leftoverQty
                normalized.qty = leftoverQty
                remainingEntries[#remainingEntries + 1] = normalized
            elseif movedQty <= 0 then
                leftoverCount = leftoverCount + requestedQty
                normalized.qty = requestedQty
                remainingEntries[#remainingEntries + 1] = normalized
            end
        end
    end

    if movedCount > 0 then
        worker.outputLedger = remainingEntries
        if Registry.Internal and Registry.Internal.MarkOutputCacheDirty then
            Registry.Internal.MarkOutputCacheDirty(worker)
        end
    else
        worker.outputLedger = remainingEntries
    end

    return movedStacks, movedCount, movedWeight, leftoverCount
end

local function takeEntries(ledger, indexes)
    local entries = {}
    table.sort(indexes or {}, function(a, b)
        return a > b
    end)

    for _, index in ipairs(indexes or {}) do
        local normalized = math.floor(tonumber(index) or 0)
        local entry = ledger and ledger[normalized] or nil
        if entry then
            entries[#entries + 1] = Registry.Internal.CopyShallow(entry)
            table.remove(ledger, normalized)
        end
    end

    return entries
end

function Warehouse.TakeProvisionEntries(ownerUsername, indexes)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local entries = takeEntries(warehouse.ledgers.provisions, indexes)
    if #entries > 0 then
        Warehouse.TouchItemsVersion(ownerUsername)
        Warehouse.TouchSummaryVersion(ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return entries
end

function Warehouse.TakeEquipmentEntries(ownerUsername, indexes)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local entries = takeEntries(warehouse.ledgers.equipment, indexes)
    if #entries > 0 then
        Warehouse.TouchItemsVersion(ownerUsername)
        Warehouse.TouchSummaryVersion(ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return entries
end

function Warehouse.TakeOutputEntries(ownerUsername, indexes)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local entries = takeEntries(warehouse.ledgers.output, indexes)
    if #entries > 0 then
        Warehouse.TouchItemsVersion(ownerUsername)
        Warehouse.TouchSummaryVersion(ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return entries
end

function Warehouse.CollectAllOutput(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local entries = Internal.CopyArray(warehouse.ledgers.output)
    warehouse.ledgers.output = {}
    if #entries > 0 then
        Warehouse.TouchItemsVersion(ownerUsername)
        Warehouse.TouchSummaryVersion(ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return entries
end

function Warehouse.GetMedicalProvisionUnitTotal(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local totalUnits = 0
    for _, entry in ipairs(warehouse and warehouse.ledgers and warehouse.ledgers.provisions or {}) do
        if Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) then
            totalUnits = totalUnits + (math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0) * math.max(1, tonumber(entry.qty) or 1))
        end
    end
    return totalUnits
end

function Warehouse.GetMedicalProvisionHourBudget(ownerUsername)
    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local totalHours = Warehouse.GetMedicalProvisionUnitTotal(ownerUsername) * 8
    local reservedHours = math.max(0, tonumber(warehouse and warehouse.medicalProvisionCarryoverHours) or 0)
    return math.max(0, totalHours - reservedHours)
end

function Warehouse.ConsumeMedicalProvisionHours(ownerUsername, usedHours)
    local hours = math.max(0, tonumber(usedHours) or 0)
    if hours <= 0 then
        return 0
    end

    local warehouse = Warehouse.GetOwnerWarehouse(ownerUsername)
    local totalHours = math.max(0, tonumber(warehouse.medicalProvisionCarryoverHours) or 0) + hours
    local unitsToConsume = math.floor(totalHours / 8)
    warehouse.medicalProvisionCarryoverHours = totalHours - (unitsToConsume * 8)

    if unitsToConsume <= 0 then
        Warehouse.Recalculate(warehouse)
        return 0
    end

    local consumedUnits = 0
    for index = #warehouse.ledgers.provisions, 1, -1 do
        local entry = warehouse.ledgers.provisions[index]
        if Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) then
            local unitsPerItem = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0)
            local availableQty = math.max(1, tonumber(entry.qty) or 1)
            local availableUnits = unitsPerItem * availableQty
            if availableUnits > 0 then
                local takeUnits = math.min(availableUnits, unitsToConsume - consumedUnits)
                if takeUnits > 0 then
                    local remainingUnits = availableUnits - takeUnits
                    if remainingUnits <= 0 then
                        table.remove(warehouse.ledgers.provisions, index)
                    else
                        entry.qty = math.max(1, math.ceil(remainingUnits / math.max(1, unitsPerItem)))
                    end
                    consumedUnits = consumedUnits + takeUnits
                    if consumedUnits >= unitsToConsume then
                        break
                    end
                end
            end
        end
    end

    if consumedUnits > 0 then
        Warehouse.TouchItemsVersion(ownerUsername)
        Warehouse.TouchSummaryVersion(ownerUsername)
    end
    Warehouse.Recalculate(warehouse)
    return consumedUnits
end

return Warehouse
