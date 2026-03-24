DC_Colony = DC_Colony or {}
DC_Colony.Nutrition = DC_Colony.Nutrition or {}

local Nutrition = DC_Colony.Nutrition

local function formatReserveValue(value)
    if DC_MainWindow and DC_MainWindow.Internal and DC_MainWindow.Internal.formatReserveValue then
        return DC_MainWindow.Internal.formatReserveValue(value)
    end
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

function Nutrition.GetCaloriesBarColor()
    return { r = 0.84, g = 0.68, b = 0.24 } -- Yellowish for Food
end

function Nutrition.GetHydrationBarColor()
    return { r = 0.28, g = 0.66, b = 0.58 } -- Bluish/Teal for Water
end

function Nutrition.GetCaloriesBarData(worker)
    local activeCalories = 0
    local maxCalories = 0
    if worker then
        activeCalories = select(1, Nutrition.GetOnBodyTotals(worker))
        maxCalories = DC_Colony.Config.GetEffectiveDailyCaloriesNeed and DC_Colony.Config.GetEffectiveDailyCaloriesNeed(worker) or 0
    end

    local fillRatio = maxCalories > 0 and math.max(0, math.min(1, activeCalories / maxCalories)) or 0

    return {
        stored = activeCalories,
        usage = maxCalories,
        fillRatio = fillRatio,
        overflow = 0,
        daysLeft = nil,
        captionText = "on-body calories",
        summaryText = formatReserveValue(activeCalories)
            .. " / "
            .. formatReserveValue(maxCalories)
    }
end

function Nutrition.GetHydrationBarData(worker)
    local activeHydration = 0
    local maxHydration = 0
    if worker then
        activeHydration = select(2, Nutrition.GetOnBodyTotals(worker))
        maxHydration = DC_Colony.Config.GetEffectiveDailyHydrationNeed and DC_Colony.Config.GetEffectiveDailyHydrationNeed(worker) or 0
    end

    local fillRatio = maxHydration > 0 and math.max(0, math.min(1, activeHydration / maxHydration)) or 0

    return {
        stored = activeHydration,
        usage = maxHydration,
        fillRatio = fillRatio,
        overflow = 0,
        daysLeft = nil,
        captionText = "on-body hydration",
        summaryText = formatReserveValue(activeHydration)
            .. " / "
            .. formatReserveValue(maxHydration)
    }
end

return Nutrition
