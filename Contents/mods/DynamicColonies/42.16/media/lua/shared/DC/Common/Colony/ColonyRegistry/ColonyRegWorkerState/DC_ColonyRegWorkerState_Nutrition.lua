DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegWorkerState or {}

function Data.migrateLegacyNutritionModel(worker)
    local currentVersion = tonumber(worker and worker.nutritionModelVersion) or 0
    local targetVersion = tonumber(Config.NUTRITION_MODEL_VERSION) or 3
    if not worker or currentVersion >= targetVersion then
        return
    end

    worker.nutritionLedger = Internal.EnsureArray(worker.nutritionLedger)
    worker.caloriesOverflow = Data.clampAmount(worker.caloriesOverflow)
    worker.hydrationOverflow = Data.clampAmount(worker.hydrationOverflow)

    local onBodyCalories = Data.clampAmount(worker.caloriesCached) + worker.caloriesOverflow
    local onBodyHydration = Data.clampAmount(worker.hydrationCached) + worker.hydrationOverflow
    for index = #worker.nutritionLedger, 1, -1 do
        local entry = worker.nutritionLedger[index]
        if DC_Colony and DC_Colony.Nutrition and DC_Colony.Nutrition.IsSyntheticReserveEntry and DC_Colony.Nutrition.IsSyntheticReserveEntry(entry) then
            local calories, hydration = Data.normalizeLedgerEntry(entry)
            onBodyCalories = onBodyCalories + calories
            onBodyHydration = onBodyHydration + hydration
            table.remove(worker.nutritionLedger, index)
        end
    end

    local caloriesCap, hydrationCap = Data.getReserveCaps(worker)
    if DC_Colony and DC_Colony.Nutrition and DC_Colony.Nutrition.SetOnBodyTotals then
        DC_Colony.Nutrition.SetOnBodyTotals(worker, onBodyCalories, onBodyHydration, caloriesCap, hydrationCap)
    else
        worker.caloriesCached = onBodyCalories
        worker.hydrationCached = onBodyHydration
    end
    worker.nutritionModelVersion = targetVersion
    worker.nutritionCacheDirty = true
end

return Data