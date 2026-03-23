DT_Labour = DT_Labour or {}
DT_Labour.Nutrition = DT_Labour.Nutrition or {}
DT_Labour.Nutrition.Internal = DT_Labour.Nutrition.Internal or {}

local Config = DT_Labour.Config
local Nutrition = DT_Labour.Nutrition
local Internal = Nutrition.Internal

local function buildConsumedProvisionSample(consumedEntries)
    local countsByName = {}
    local orderedNames = {}

    for _, entry in ipairs(consumedEntries or {}) do
        local displayName = tostring(entry and (entry.displayName or entry.fullType) or "Provision")
        if not countsByName[displayName] then
            countsByName[displayName] = 0
            orderedNames[#orderedNames + 1] = displayName
        end
        countsByName[displayName] = countsByName[displayName] + math.max(1, tonumber(entry and entry.qty) or 1)
    end

    local parts = {}
    for _, displayName in ipairs(orderedNames) do
        local qty = countsByName[displayName] or 0
        if qty > 1 then
            parts[#parts + 1] = displayName .. " x" .. tostring(qty)
        else
            parts[#parts + 1] = displayName
        end
    end

    local count = #parts
    if count <= 0 then
        return ""
    end
    if count == 1 then
        return tostring(parts[1])
    end
    if count == 2 then
        return tostring(parts[1]) .. " and " .. tostring(parts[2])
    end
    return tostring(parts[1]) .. ", " .. tostring(parts[2]) .. ", and " .. tostring(count - 2) .. " more"
end

local function appendProvisionConsumptionLog(worker, consumedEntries, totalCalories, totalHydration, worldHour)
    local entryCount = #(consumedEntries or {})
    if entryCount <= 0 then
        return
    end

    if entryCount == 1 then
        local entry = consumedEntries[1]
        local displayName = tostring(entry.displayName or entry.fullType or "Provision")
        local actionVerb = ((tonumber(totalHydration) or 0) > 0 and (tonumber(totalCalories) or 0) <= 0) and "Drank" or "Ate"
        Internal.AppendWorkerLog(
            worker,
            actionVerb .. " " .. displayName .. " (" .. string.format("%.0f", totalCalories or 0) .. " cal, " .. string.format("%.0f", totalHydration or 0) .. " hyd).",
            worldHour,
            "nutrition"
        )
        return
    end

    local sampleText = buildConsumedProvisionSample(consumedEntries)
    Internal.AppendWorkerLog(
        worker,
        "Consumed "
            .. tostring(entryCount)
            .. " provisions"
            .. (sampleText ~= "" and (": " .. sampleText) or "")
            .. " ("
            .. string.format("%.0f", totalCalories or 0)
            .. " cal, "
            .. string.format("%.0f", totalHydration or 0)
            .. " hyd).",
        worldHour,
        "nutrition"
    )
end

function Internal.FindNextConsumableEntry(worker)
    if not worker then
        return nil, nil
    end

    Internal.PruneEmptyEntries(worker)
    worker.nutritionLedger = worker.nutritionLedger or {}
    for index, entry in ipairs(worker.nutritionLedger) do
        if not (Config.IsMedicalProvisionEntry and Config.IsMedicalProvisionEntry(entry)) then
            return index, entry
        end
    end
    return nil, nil
end

function Nutrition.ConsumeProvisionItem(worker, ledgerIndex, caloriesCap, hydrationCap, options)
    if not worker then
        return 0, 0, nil
    end

    options = options or {}
    local index = tonumber(ledgerIndex) or nil
    local entry = nil

    if index then
        entry = worker.nutritionLedger and worker.nutritionLedger[index] or nil
    else
        index, entry = Internal.FindNextConsumableEntry(worker)
    end

    if not index or not entry then
        return 0, 0, nil
    end

    local calories, hydration, changed = Internal.NormalizeLedgerEntry(entry)
    table.remove(worker.nutritionLedger, index)
    Nutrition.AddReserveAmounts(worker, calories, hydration, caloriesCap, hydrationCap)
    if not changed then
        local registryInternal = DT_Labour and DT_Labour.Registry and DT_Labour.Registry.Internal or nil
        if not (registryInternal and registryInternal.ApplyNutritionCacheDelta and registryInternal.ApplyNutritionCacheDelta(worker, -calories, -hydration)) then
            Internal.MarkNutritionDirty(worker)
        end
    else
        Internal.MarkNutritionDirty(worker)
    end
    if options.skipLog ~= true then
        appendProvisionConsumptionLog(
            worker,
            { entry },
            calories,
            hydration,
            (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()
        )
    end
    Internal.PruneEmptyEntries(worker)
    return calories, hydration, entry
end

function Nutrition.RefillReserveToTargets(worker, caloriesTarget, hydrationTarget, caloriesCap, hydrationCap)
    if not worker then
        return 0, 0
    end

    local caloriesMoved = 0
    local hydrationMoved = 0
    local targetCalories = Internal.ClampAmount(caloriesTarget)
    local targetHydration = Internal.ClampAmount(hydrationTarget)
    local consumedCount = 0
    local consumedEntries = {}

    while consumedCount < 512 do
        local totalCalories, totalHydration = Internal.GetOnBodyTotals(worker)
        if totalCalories >= targetCalories and totalHydration >= targetHydration then
            break
        end

        local addedCalories, addedHydration, consumedEntry = Nutrition.ConsumeProvisionItem(worker, nil, caloriesCap, hydrationCap, {
            skipLog = true
        })
        if addedCalories <= 0 and addedHydration <= 0 then
            break
        end

        caloriesMoved = caloriesMoved + addedCalories
        hydrationMoved = hydrationMoved + addedHydration
        consumedCount = consumedCount + 1
        if consumedEntry then
            consumedEntries[#consumedEntries + 1] = consumedEntry
        end
    end

    appendProvisionConsumptionLog(
        worker,
        consumedEntries,
        caloriesMoved,
        hydrationMoved,
        (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()
    )

    return caloriesMoved, hydrationMoved
end

return Nutrition
