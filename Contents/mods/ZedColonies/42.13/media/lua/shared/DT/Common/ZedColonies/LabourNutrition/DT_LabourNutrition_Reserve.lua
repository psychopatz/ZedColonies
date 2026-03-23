DT_Labour = DT_Labour or {}
DT_Labour.Nutrition = DT_Labour.Nutrition or {}
DT_Labour.Nutrition.Internal = DT_Labour.Nutrition.Internal or {}

local Nutrition = DT_Labour.Nutrition
local Internal = Nutrition.Internal

function Internal.GetReserveCaps(caloriesCap, hydrationCap)
    return Internal.ClampAmount(caloriesCap), Internal.ClampAmount(hydrationCap)
end

function Internal.GetOnBodyTotals(worker)
    if not worker then
        return 0, 0
    end

    return Internal.ClampAmount(worker.caloriesCached) + Internal.ClampAmount(worker.caloriesOverflow),
        Internal.ClampAmount(worker.hydrationCached) + Internal.ClampAmount(worker.hydrationOverflow)
end

function Internal.NormalizeOnBodyReserve(worker, caloriesCap, hydrationCap)
    if not worker then
        return 0, 0, 0, 0
    end

    local safeCaloriesCap, safeHydrationCap = Internal.GetReserveCaps(caloriesCap, hydrationCap)
    local totalCalories, totalHydration = Internal.GetOnBodyTotals(worker)

    worker.caloriesCached = math.min(totalCalories, safeCaloriesCap)
    worker.hydrationCached = math.min(totalHydration, safeHydrationCap)
    worker.caloriesOverflow = math.max(0, totalCalories - safeCaloriesCap)
    worker.hydrationOverflow = math.max(0, totalHydration - safeHydrationCap)

    return worker.caloriesCached, worker.hydrationCached, worker.caloriesOverflow, worker.hydrationOverflow
end

function Internal.SetOnBodyTotals(worker, calories, hydration, caloriesCap, hydrationCap)
    if not worker then
        return
    end

    worker.caloriesCached = Internal.ClampAmount(calories)
    worker.hydrationCached = Internal.ClampAmount(hydration)
    worker.caloriesOverflow = 0
    worker.hydrationOverflow = 0
    Internal.NormalizeOnBodyReserve(worker, caloriesCap, hydrationCap)
end

function Nutrition.GetOnBodyTotals(worker)
    return Internal.GetOnBodyTotals(worker)
end

function Nutrition.NormalizeOnBodyReserve(worker, caloriesCap, hydrationCap)
    return Internal.NormalizeOnBodyReserve(worker, caloriesCap, hydrationCap)
end

function Nutrition.SetOnBodyTotals(worker, calories, hydration, caloriesCap, hydrationCap)
    Internal.SetOnBodyTotals(worker, calories, hydration, caloriesCap, hydrationCap)
end

function Nutrition.AddReserveAmounts(worker, calories, hydration, caloriesCap, hydrationCap)
    if not worker then
        return
    end

    local totalCalories, totalHydration = Internal.GetOnBodyTotals(worker)
    Internal.SetOnBodyTotals(
        worker,
        totalCalories + Internal.ClampAmount(calories),
        totalHydration + Internal.ClampAmount(hydration),
        caloriesCap,
        hydrationCap
    )
end

function Nutrition.ConsumeReserveAmounts(worker, caloriesNeeded, hydrationNeeded, caloriesCap, hydrationCap)
    if not worker then
        return true, true
    end

    local caloriesTarget = Internal.ClampAmount(caloriesNeeded)
    local hydrationTarget = Internal.ClampAmount(hydrationNeeded)
    local totalCalories, totalHydration = Internal.GetOnBodyTotals(worker)
    local caloriesUsed = math.min(totalCalories, caloriesTarget)
    local hydrationUsed = math.min(totalHydration, hydrationTarget)

    Internal.SetOnBodyTotals(
        worker,
        totalCalories - caloriesUsed,
        totalHydration - hydrationUsed,
        caloriesCap,
        hydrationCap
    )

    return caloriesUsed >= (caloriesTarget - 0.0001), hydrationUsed >= (hydrationTarget - 0.0001)
end

function Nutrition.ConsumeAmounts(worker, caloriesNeeded, hydrationNeeded)
    if not worker then
        return true, true
    end

    local totalCalories, totalHydration = Internal.GetOnBodyTotals(worker)
    return Nutrition.ConsumeReserveAmounts(worker, caloriesNeeded, hydrationNeeded, totalCalories, totalHydration)
end

function Nutrition.ConsumeForHours(worker, caloriesPerHour, hydrationPerHour, hours)
    if not worker or hours <= 0 then
        return true, true
    end

    local caloriesNeeded = math.max(0, caloriesPerHour * hours)
    local hydrationNeeded = math.max(0, hydrationPerHour * hours)
    return Nutrition.ConsumeAmounts(worker, caloriesNeeded, hydrationNeeded)
end

return Nutrition
