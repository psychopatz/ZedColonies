DT_Labour = DT_Labour or {}
DT_Labour.Config = DT_Labour.Config or {}

local Config = DT_Labour.Config

function Config.GetMealSchedule()
    return Config.MEAL_SCHEDULE or {}
end

function Config.GetMealsPerDay()
    return #Config.GetMealSchedule()
end

function Config.GetMealCheckpointCountAtHour(worldHour)
    local safeHour = math.max(0, math.floor(tonumber(worldHour) or 0))
    local hoursPerDay = tonumber(Config.HOURS_PER_DAY) or 24
    if hoursPerDay <= 0 then
        return 0
    end

    local day = math.floor(safeHour / hoursPerDay)
    local hourOfDay = safeHour % hoursPerDay
    local count = day * Config.GetMealsPerDay()

    for _, meal in ipairs(Config.GetMealSchedule()) do
        if hourOfDay >= (tonumber(meal.hour) or 0) then
            count = count + 1
        end
    end

    return count
end

function Config.GetMealProfileByCheckpoint(checkpointCount)
    local mealsPerDay = Config.GetMealsPerDay()
    if mealsPerDay <= 0 then
        return nil
    end

    local safeCount = math.floor(tonumber(checkpointCount) or 0)
    if safeCount <= 0 then
        return nil
    end

    local slotIndex = ((safeCount - 1) % mealsPerDay) + 1
    return Config.GetMealSchedule()[slotIndex]
end

function Config.GetNextMealProfile(checkpointCount)
    local safeCount = math.max(0, math.floor(tonumber(checkpointCount) or 0))
    return Config.GetMealProfileByCheckpoint(safeCount + 1)
end

function Config.GetMealNeeds(dailyCaloriesNeed, dailyHydrationNeed, mealProfile)
    local meal = mealProfile or {}
    return math.max(0, (tonumber(dailyCaloriesNeed) or 0) * (tonumber(meal.caloriesShare) or 0)),
        math.max(0, (tonumber(dailyHydrationNeed) or 0) * (tonumber(meal.hydrationShare) or 0))
end

function Config.GetMealCheckpointHourByCount(checkpointCount)
    local mealsPerDay = Config.GetMealsPerDay()
    local hoursPerDay = tonumber(Config.HOURS_PER_DAY) or 24
    if mealsPerDay <= 0 or hoursPerDay <= 0 then
        return 0
    end

    local safeCount = math.floor(tonumber(checkpointCount) or 0)
    if safeCount <= 0 then
        return 0
    end

    local day = math.floor((safeCount - 1) / mealsPerDay)
    local meal = Config.GetMealProfileByCheckpoint(safeCount) or {}
    return (day * hoursPerDay) + math.floor(tonumber(meal.hour) or 0)
end

return Config
