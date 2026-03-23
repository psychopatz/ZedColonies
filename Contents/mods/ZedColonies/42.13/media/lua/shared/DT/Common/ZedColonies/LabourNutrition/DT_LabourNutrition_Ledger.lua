DT_Labour = DT_Labour or {}
DT_Labour.Nutrition = DT_Labour.Nutrition or {}
DT_Labour.Nutrition.Internal = DT_Labour.Nutrition.Internal or {}

local Config = DT_Labour.Config
local Nutrition = DT_Labour.Nutrition
local Internal = Nutrition.Internal

function Nutrition.IsSyntheticReserveEntry(entry)
    local fullType = entry and tostring(entry.fullType or "") or ""
    return string.find(fullType, "^DT%.Labour") ~= nil
end

function Nutrition.SanitizeLedgerEntry(entry)
    if not entry then
        return 0, 0, false
    end

    if Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry) then
        local originalUnits = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0)
        local units = originalUnits
        if units <= 0 and Config.GetMedicalProvisionUnits then
            units = Config.GetMedicalProvisionUnits(entry.fullType)
        end
        entry.provisionType = "medical"
        entry.medicalUse = tostring(entry.medicalUse or "bandage")
        entry.treatmentUnitsRemaining = math.max(0, units)
        return 0, 0, originalUnits ~= entry.treatmentUnitsRemaining
    end

    entry.provisionType = "nutrition"

    local originalCalories = Internal.ClampAmount(entry.caloriesRemaining)
    local originalHydration = Internal.ClampAmount(entry.hydrationRemaining)
    local calories = originalCalories
    local hydration = originalHydration
    if hydration > 0 and hydration < 25 then
        hydration = hydration * (Config.HYDRATION_POINTS_PER_THIRST or 1000)
    end

    local expectedCalories, expectedHydration, scriptItem = Internal.GetExpectedStaticNutritionForFullType(entry.fullType)
    local isStaticFood = not Nutrition.IsSyntheticReserveEntry(entry) and not Internal.IsWaterHydrationSource(nil, scriptItem)

    if expectedCalories > 0 and calories > (expectedCalories * 1.5) then
        calories = expectedCalories
    end
    if expectedHydration > 0 and hydration > (expectedHydration * 1.5) then
        hydration = expectedHydration
    end
    if isStaticFood then
        if expectedCalories > 0 and calories <= 0 and hydration > 0 then
            calories = expectedCalories
        end
        if expectedHydration > 0 and hydration <= 0 and calories > 0 then
            hydration = expectedHydration
        end
    end

    entry.caloriesRemaining = calories
    entry.hydrationRemaining = hydration
    return calories, hydration, originalCalories ~= calories or originalHydration ~= hydration
end

function Internal.NormalizeLedgerEntry(entry)
    return Nutrition.SanitizeLedgerEntry(entry)
end

function Internal.PruneEmptyEntries(worker)
    if not worker then
        return
    end

    worker.nutritionLedger = worker.nutritionLedger or {}
    local removedAny = false
    local changedAny = false
    for i = #worker.nutritionLedger, 1, -1 do
        local entry = worker.nutritionLedger[i]
        local calories, hydration, changed = Internal.NormalizeLedgerEntry(entry)
        changedAny = changedAny or changed == true
        local hasMedicalUnits = Config.IsMedicalProvisionEntry
            and Config.IsMedicalProvisionEntry(entry)
            and math.max(0, tonumber(entry and entry.treatmentUnitsRemaining) or 0) > 0.0001
        if not hasMedicalUnits and calories <= 0.0001 and hydration <= 0.0001 then
            table.remove(worker.nutritionLedger, i)
            removedAny = true
        end
    end
    if removedAny or changedAny then
        Internal.MarkNutritionDirty(worker)
    end
end

function Nutrition.PruneEmptyEntries(worker)
    Internal.PruneEmptyEntries(worker)
end

function Nutrition.GetLedgerTotals(worker)
    if worker and worker.nutritionCacheDirty == false then
        return Internal.ClampAmount(worker.storedCalories), Internal.ClampAmount(worker.storedHydration)
    end

    local calories = 0
    local hydration = 0
    for _, entry in ipairs(worker and worker.nutritionLedger or {}) do
        if not (Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry)) then
            local entryCalories, entryHydration = Internal.NormalizeLedgerEntry(entry)
            calories = calories + entryCalories
            hydration = hydration + entryHydration
        end
    end
    return calories, hydration
end

function Nutrition.GetTotalAvailableAmounts(worker)
    local onBodyCalories, onBodyHydration = Internal.GetOnBodyTotals(worker)
    local ledgerCalories, ledgerHydration = Nutrition.GetLedgerTotals(worker)
    return onBodyCalories + ledgerCalories, onBodyHydration + ledgerHydration
end

return Nutrition
