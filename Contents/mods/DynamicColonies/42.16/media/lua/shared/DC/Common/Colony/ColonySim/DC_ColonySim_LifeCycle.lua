local Sim = DC_Colony.Sim
local Health = DC_Colony.Health
local Nutrition = DC_Colony.Nutrition

-- Sim.RunWorkerLifeCycle(worker, ctx)
--
-- Processes nutrition and health for one simulation tick.
-- Expects ctx to already contain:
--   currentHour, forcedRest, canWork, dailyCaloriesNeed, dailyHydrationNeed
-- Writes back into ctx:
--   workableHours, supportedHours, hasCalories, hasHydration, hp
-- Also resets worker.starvationHours and worker.dehydrationHours to 0.
function Sim.RunWorkerLifeCycle(worker, ctx)
    local nutritionResult = Nutrition
        and Nutrition.ProcessWorkerNutrition
        and Nutrition.ProcessWorkerNutrition(
            worker,
            ctx.currentHour,
            ctx.dailyCaloriesNeed,
            ctx.dailyHydrationNeed,
            ctx.canWork
        )

    ctx.workableHours  = math.max(0, tonumber(nutritionResult and nutritionResult.workableHours)  or 0)
    ctx.supportedHours = math.max(0, tonumber(nutritionResult and nutritionResult.supportedHours) or 0)
    ctx.hasCalories    = nutritionResult and nutritionResult.hasCalories  == true or false
    ctx.hasHydration   = nutritionResult and nutritionResult.hasHydration == true or false

    local hp = Health and Health.GetCurrent(worker) or 100
    if Health and Health.ApplySleepHealing then
        hp = select(1, Health.ApplySleepHealing(worker, ctx.forcedRest, ctx.supportedHours))
    end
    ctx.hp = hp

    worker.starvationHours = 0
    worker.dehydrationHours = 0
end
