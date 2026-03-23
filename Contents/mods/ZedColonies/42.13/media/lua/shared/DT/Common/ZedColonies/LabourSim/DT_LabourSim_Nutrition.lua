local Config = DT_Labour.Config
local Nutrition = DT_Labour.Nutrition
local Internal = DT_Labour.Sim.Internal

Internal.getHourlyNeed = function(dailyNeed)
    local hoursPerDay = tonumber(Config.HOURS_PER_DAY) or 24
    if hoursPerDay <= 0 then
        return 0
    end
    return math.max(0, tonumber(dailyNeed) or 0) / hoursPerDay
end

Internal.refillReserveToDailyTargets = function(worker, dailyCaloriesNeed, dailyHydrationNeed)
    Nutrition.RefillReserveToTargets(
        worker,
        math.max(0, tonumber(dailyCaloriesNeed) or 0),
        math.max(0, tonumber(dailyHydrationNeed) or 0),
        math.max(0, tonumber(dailyCaloriesNeed) or 0),
        math.max(0, tonumber(dailyHydrationNeed) or 0)
    )
end

Internal.getSupportedHours = function(reserveAmount, hourlyNeed, intervalHours)
    if intervalHours <= 0 then
        return 0
    end
    if hourlyNeed <= 0 then
        return intervalHours
    end
    return math.min(intervalHours, math.max(0, (tonumber(reserveAmount) or 0) / hourlyNeed))
end

Internal.maybeRefillReserve = function(worker, currentHour, checkpointCount, dailyCaloriesNeed, dailyHydrationNeed, forceMealRefill)
    if not worker then
        return
    end

    if forceMealRefill then
        Internal.refillReserveToDailyTargets(worker, dailyCaloriesNeed, dailyHydrationNeed)
        return
    end

    local nextCheckpointHour = Config.GetMealCheckpointHourByCount((tonumber(checkpointCount) or 0) + 1)
    local safeNextHour = tonumber(nextCheckpointHour) or 0
    local safeCurrentHour = tonumber(currentHour) or 0
    local hoursUntilNextMeal = math.max(0, safeNextHour - safeCurrentHour)
    local caloriesThreshold = Internal.getHourlyNeed(dailyCaloriesNeed) * hoursUntilNextMeal
    local hydrationThreshold = Internal.getHourlyNeed(dailyHydrationNeed) * hoursUntilNextMeal
    local activeCalories, activeHydration = Nutrition.GetOnBodyTotals(worker)

    if activeCalories <= (caloriesThreshold + 0.0001) or activeHydration <= (hydrationThreshold + 0.0001) then
        Internal.refillReserveToDailyTargets(worker, dailyCaloriesNeed, dailyHydrationNeed)
    end
end

Internal.applyInterval = function(worker, workableHours, supportedHours, hp, maxHp, intervalHours, caloriesPerHour, hydrationPerHour, canWork)
    if intervalHours <= 0 then
        return workableHours, supportedHours, hp
    end

    local activeCalories, activeHydration = Nutrition.GetOnBodyTotals(worker)
    local fullyFedHours = math.min(
        intervalHours,
        Internal.getSupportedHours(activeCalories, caloriesPerHour, intervalHours),
        Internal.getSupportedHours(activeHydration, hydrationPerHour, intervalHours)
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

    if deprivedHours > 0 then
        hp = Internal.clampHp(hp - (deprivedHours * (Config.WORKER_HP_LOSS_PER_HOUR or 1)), maxHp)
    end

    return workableHours, supportedHours, hp
end

Internal.processNutrition = function(worker, currentHour, dailyCaloriesNeed, dailyHydrationNeed, canWork)
    local lastHour = tonumber(worker.lastSimHour) or tonumber(currentHour) or 0
    local currentCheckpoint = Config.GetMealCheckpointCountAtHour(currentHour)
    local previousCheckpoint = Internal.clampCheckpoint(
        worker.lastNutritionCheckpoint,
        Config.GetMealCheckpointCountAtHour(lastHour)
    )

    if previousCheckpoint > currentCheckpoint then
        previousCheckpoint = currentCheckpoint
    end

    local caloriesPerHour = Internal.getHourlyNeed(dailyCaloriesNeed)
    local hydrationPerHour = Internal.getHourlyNeed(dailyHydrationNeed)
    Internal.maybeRefillReserve(worker, lastHour, previousCheckpoint, dailyCaloriesNeed, dailyHydrationNeed, false)
    local reserveCalories, reserveHydration = Nutrition.GetOnBodyTotals(worker)
    local hasCalories = reserveCalories > 0
    local hasHydration = reserveHydration > 0
    local maxHp = math.max(1, tonumber(worker.maxHp) or Config.DEFAULT_WORKER_MAX_HP or 100)
    local hp = Internal.clampHp(worker.hp, maxHp)
    local workableHours = 0
    local supportedHours = 0
    local segmentStart = lastHour

    for checkpoint = previousCheckpoint + 1, currentCheckpoint do
        local checkpointHour = Config.GetMealCheckpointHourByCount(checkpoint)
        local intervalHours = math.max(0, math.min(currentHour, checkpointHour) - segmentStart)
        workableHours, supportedHours, hp = Internal.applyInterval(
            worker,
            workableHours,
            supportedHours,
            hp,
            maxHp,
            intervalHours,
            caloriesPerHour,
            hydrationPerHour,
            canWork
        )
        segmentStart = math.max(segmentStart, checkpointHour)

        Internal.maybeRefillReserve(worker, checkpointHour, checkpoint, dailyCaloriesNeed, dailyHydrationNeed, true)
        reserveCalories, reserveHydration = Nutrition.GetOnBodyTotals(worker)
        hasCalories = reserveCalories > 0
        hasHydration = reserveHydration > 0
    end

    local tailHours = math.max(0, currentHour - segmentStart)
    workableHours, supportedHours, hp = Internal.applyInterval(
        worker,
        workableHours,
        supportedHours,
        hp,
        maxHp,
        tailHours,
        caloriesPerHour,
        hydrationPerHour,
        canWork
    )
    Internal.maybeRefillReserve(worker, currentHour, currentCheckpoint, dailyCaloriesNeed, dailyHydrationNeed, false)

    reserveCalories, reserveHydration = Nutrition.GetOnBodyTotals(worker)
    hasCalories = reserveCalories > 0
    hasHydration = reserveHydration > 0

    worker.lastNutritionCheckpoint = currentCheckpoint
    worker.hp = hp

    return {
        workableHours = workableHours,
        supportedHours = supportedHours,
        hasCalories = hasCalories,
        hasHydration = hasHydration,
        hp = hp
    }
end
