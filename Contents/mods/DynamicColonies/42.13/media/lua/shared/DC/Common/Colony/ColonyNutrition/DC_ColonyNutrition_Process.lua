DC_Colony = DC_Colony or {}
DC_Colony.Nutrition = DC_Colony.Nutrition or {}

local Config = DC_Colony.Config
local Nutrition = DC_Colony.Nutrition

function Nutrition.GetHourlyNeed(dailyNeed)
    local hoursPerDay = tonumber(Config.HOURS_PER_DAY) or 24
    if hoursPerDay <= 0 then
        return 0
    end
    return math.max(0, tonumber(dailyNeed) or 0) / hoursPerDay
end

function Nutrition.GetSupportedHours(reserveAmount, hourlyNeed, intervalHours)
    if intervalHours <= 0 then
        return 0
    end
    if hourlyNeed <= 0 then
        return intervalHours
    end
    return math.min(intervalHours, math.max(0, (tonumber(reserveAmount) or 0) / hourlyNeed))
end

function Nutrition.MaybeRefillReserve(worker, currentHour, checkpointCount, dailyCaloriesNeed, dailyHydrationNeed, forceMealRefill)
    if not worker then
        return
    end

    if forceMealRefill then
        Nutrition.RefillReserveToTargets(
            worker,
            math.max(0, tonumber(dailyCaloriesNeed) or 0),
            math.max(0, tonumber(dailyHydrationNeed) or 0),
            math.max(0, tonumber(dailyCaloriesNeed) or 0),
            math.max(0, tonumber(dailyHydrationNeed) or 0)
        )
        return
    end

    local nextCheckpointHour = Config.GetMealCheckpointHourByCount((tonumber(checkpointCount) or 0) + 1)
    local safeNextHour = tonumber(nextCheckpointHour) or 0
    local safeCurrentHour = tonumber(currentHour) or 0
    local hoursUntilNextMeal = math.max(0, safeNextHour - safeCurrentHour)
    local caloriesThreshold = Nutrition.GetHourlyNeed(dailyCaloriesNeed) * hoursUntilNextMeal
    local hydrationThreshold = Nutrition.GetHourlyNeed(dailyHydrationNeed) * hoursUntilNextMeal
    local activeCalories, activeHydration = Nutrition.GetOnBodyTotals(worker)

    if activeCalories <= (caloriesThreshold + 0.0001) or activeHydration <= (hydrationThreshold + 0.0001) then
        Nutrition.RefillReserveToTargets(
            worker,
            math.max(0, tonumber(dailyCaloriesNeed) or 0),
            math.max(0, tonumber(dailyHydrationNeed) or 0),
            math.max(0, tonumber(dailyCaloriesNeed) or 0),
            math.max(0, tonumber(dailyHydrationNeed) or 0)
        )
    end
end

function Nutrition.ApplyInterval(worker, workableHours, supportedHours, intervalHours, caloriesPerHour, hydrationPerHour, canWork)
    if intervalHours <= 0 then
        return workableHours, supportedHours
    end

    local activeCalories, activeHydration = Nutrition.GetOnBodyTotals(worker)
    local fullyFedHours = math.min(
        intervalHours,
        Nutrition.GetSupportedHours(activeCalories, caloriesPerHour, intervalHours),
        Nutrition.GetSupportedHours(activeHydration, hydrationPerHour, intervalHours)
    )
    local deprivedHours = math.max(0, intervalHours - fullyFedHours)

    Nutrition.ConsumeReserveAmounts(
        worker,
        math.max(0, tonumber(caloriesPerHour) or 0) * intervalHours,
        math.max(0, tonumber(hydrationPerHour) or 0) * intervalHours,
        math.max(0, tonumber(caloriesPerHour) or 0) * (tonumber(Config.HOURS_PER_DAY) or 24),
        math.max(0, tonumber(hydrationPerHour) or 0) * (tonumber(Config.HOURS_PER_DAY) or 24)
    )

    if canWork and fullyFedHours > 0 then
        workableHours = workableHours + fullyFedHours
    end
    if fullyFedHours > 0 then
        supportedHours = supportedHours + fullyFedHours
    end

    if deprivedHours > 0 and DC_Colony.Health and DC_Colony.Health.ApplyDeprivationDamage then
        DC_Colony.Health.ApplyDeprivationDamage(worker, deprivedHours)
    end

    return workableHours, supportedHours
end

function Nutrition.ClampCheckpoint(value, fallback)
    local safeValue = math.floor(tonumber(value) or tonumber(fallback) or 0)
    return math.max(0, safeValue)
end

function Nutrition.ProcessWorkerNutrition(worker, currentHour, dailyCaloriesNeed, dailyHydrationNeed, canWork)
    local lastHour = tonumber(worker.lastSimHour) or tonumber(currentHour) or 0
    local currentCheckpoint = Config.GetMealCheckpointCountAtHour(currentHour)
    local previousCheckpoint = Nutrition.ClampCheckpoint(
        worker.lastNutritionCheckpoint,
        Config.GetMealCheckpointCountAtHour(lastHour)
    )

    if previousCheckpoint > currentCheckpoint then
        previousCheckpoint = currentCheckpoint
    end

    local caloriesPerHour = Nutrition.GetHourlyNeed(dailyCaloriesNeed)
    local hydrationPerHour = Nutrition.GetHourlyNeed(dailyHydrationNeed)
    Nutrition.MaybeRefillReserve(worker, lastHour, previousCheckpoint, dailyCaloriesNeed, dailyHydrationNeed, false)
    local workableHours = 0
    local supportedHours = 0
    local segmentStart = lastHour

    for checkpoint = previousCheckpoint + 1, currentCheckpoint do
        local checkpointHour = Config.GetMealCheckpointHourByCount(checkpoint)
        local intervalHours = math.max(0, math.min(currentHour, checkpointHour) - segmentStart)
        workableHours, supportedHours = Nutrition.ApplyInterval(
            worker,
            workableHours,
            supportedHours,
            intervalHours,
            caloriesPerHour,
            hydrationPerHour,
            canWork
        )
        segmentStart = math.max(segmentStart, checkpointHour)

        Nutrition.MaybeRefillReserve(worker, checkpointHour, checkpoint, dailyCaloriesNeed, dailyHydrationNeed, true)
    end

    local tailHours = math.max(0, currentHour - segmentStart)
    workableHours, supportedHours = Nutrition.ApplyInterval(
        worker,
        workableHours,
        supportedHours,
        tailHours,
        caloriesPerHour,
        hydrationPerHour,
        canWork
    )
    Nutrition.MaybeRefillReserve(worker, currentHour, currentCheckpoint, dailyCaloriesNeed, dailyHydrationNeed, false)

    local reserveCalories, reserveHydration = Nutrition.GetOnBodyTotals(worker)
    local hasCalories = reserveCalories > 0
    local hasHydration = reserveHydration > 0

    worker.lastNutritionCheckpoint = currentCheckpoint

    return {
        workableHours = workableHours,
        supportedHours = supportedHours,
        hasCalories = hasCalories,
        hasHydration = hasHydration,
        hp = worker.hp -- maintained for backwards compatibility
    }
end

return Nutrition
