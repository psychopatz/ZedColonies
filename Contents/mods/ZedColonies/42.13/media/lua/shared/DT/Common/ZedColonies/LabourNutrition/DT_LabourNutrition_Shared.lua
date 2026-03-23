DT_Labour = DT_Labour or {}
DT_Labour.Nutrition = DT_Labour.Nutrition or {}
DT_Labour.Nutrition.Internal = DT_Labour.Nutrition.Internal or {}

local Config = DT_Labour.Config
local Nutrition = DT_Labour.Nutrition
local Internal = Nutrition.Internal

Internal.ExpectedStaticNutritionCache = Internal.ExpectedStaticNutritionCache or {}

function Internal.AppendWorkerLog(worker, message, worldHour, category)
    local registryInternal = DT_Labour and DT_Labour.Registry and DT_Labour.Registry.Internal or nil
    if registryInternal and registryInternal.AppendActivityLog then
        registryInternal.AppendActivityLog(worker, message, worldHour, category)
    end
end

function Internal.MarkNutritionDirty(worker)
    local registryInternal = DT_Labour and DT_Labour.Registry and DT_Labour.Registry.Internal or nil
    if registryInternal and registryInternal.MarkNutritionCacheDirty then
        registryInternal.MarkNutritionCacheDirty(worker)
    elseif worker then
        worker.nutritionCacheDirty = true
    end
end

function Internal.ClampAmount(value)
    return math.max(0, tonumber(value) or 0)
end

function Internal.GetScriptItem(invItem)
    if not invItem or not invItem.getFullType then
        return nil
    end
    return getScriptManager():getItem(invItem:getFullType())
end

function Internal.GetScriptItemByFullType(fullType)
    if not fullType or not getScriptManager then
        return nil
    end
    return getScriptManager():getItem(fullType)
end

function Internal.CreateItemByFullType(fullType)
    if not fullType or not InventoryItemFactory or not InventoryItemFactory.CreateItem then
        return nil
    end
    return InventoryItemFactory.CreateItem(fullType)
end

function Internal.ReadNumericValue(source, getterName)
    if not source then
        return 0
    end

    local getter = source[getterName]
    if not getter then
        return 0
    end

    return tonumber(getter(source)) or 0
end

function Internal.ContainsText(haystack, needle)
    if not haystack or not needle then
        return false
    end
    return string.find(string.lower(tostring(haystack)), string.lower(tostring(needle)), 1, true) ~= nil
end

function Internal.IsWaterHydrationSource(invItem, scriptItem)
    if invItem and invItem.isWaterSource and invItem:isWaterSource() then
        return true
    end

    local fullType = invItem and invItem.getFullType and invItem:getFullType() or nil
    local displayName = invItem and invItem.getDisplayName and invItem:getDisplayName() or nil
    local scriptName = scriptItem and scriptItem.getDisplayName and scriptItem:getDisplayName() or nil

    if Internal.ContainsText(fullType, "water")
        or Internal.ContainsText(displayName, "water")
        or Internal.ContainsText(scriptName, "water") then
        return true
    end

    return false
end

function Internal.NormalizeHydrationPoints(rawValue)
    local normalized = math.abs(Config.NormalizeUnitValue(rawValue))
    if normalized <= 0 then
        return 0
    end

    return normalized * (Config.HYDRATION_POINTS_PER_THIRST or 1000)
end

function Internal.NormalizeCaloriesFromHunger(rawValue)
    local normalized = math.abs(Config.NormalizeUnitValue(rawValue))
    if normalized <= 0 then
        return 0
    end

    return normalized * 1800
end

function Internal.ChooseStaticNutrition(instanceValue, scriptValue)
    local instanceAmount = Internal.ClampAmount(instanceValue)
    local scriptAmount = Internal.ClampAmount(scriptValue)

    if scriptAmount <= 0 then
        return instanceAmount
    end

    if instanceAmount <= 0 then
        return scriptAmount
    end

    if instanceAmount <= (scriptAmount * 1.5) then
        return instanceAmount
    end

    return scriptAmount
end

function Internal.GetExpectedStaticNutritionForFullType(fullType)
    if not fullType then
        return 0, 0, nil
    end

    local cached = Internal.ExpectedStaticNutritionCache[fullType]
    if cached then
        return cached.calories or 0, cached.hydration or 0, cached.scriptItem
    end

    local scriptItem = Internal.GetScriptItemByFullType(fullType)
    if not scriptItem then
        return 0, 0, nil
    end

    local createdItem = Internal.CreateItemByFullType(fullType)
    local instanceCalories = Internal.ClampAmount(Internal.ReadNumericValue(createdItem, "getCalories"))
    local scriptCalories = Internal.ClampAmount(Internal.ReadNumericValue(scriptItem, "getCalories"))
    local instanceHungerCalories = Internal.NormalizeCaloriesFromHunger(Internal.ReadNumericValue(createdItem, "getHungerChange"))
    local scriptHungerCalories = 0
    if DynamicTrading and DynamicTrading.Economy and DynamicTrading.Economy.Common then
        scriptHungerCalories = Internal.NormalizeCaloriesFromHunger(DynamicTrading.Economy.Common.GetNormalizedHunger(scriptItem))
    end
    local expectedCalories = Internal.ChooseStaticNutrition(instanceCalories, scriptCalories)
    if expectedCalories <= 0 then
        expectedCalories = Internal.ChooseStaticNutrition(instanceHungerCalories, scriptHungerCalories)
    end

    local instanceHydration = Internal.NormalizeHydrationPoints(Internal.ReadNumericValue(createdItem, "getThirstChange"))
    local scriptHydration = Internal.NormalizeHydrationPoints(Internal.ReadNumericValue(scriptItem, "getThirstChange"))
    local expectedHydration = Internal.ChooseStaticNutrition(instanceHydration, scriptHydration)

    Internal.ExpectedStaticNutritionCache[fullType] = {
        calories = expectedCalories,
        hydration = expectedHydration,
        scriptItem = scriptItem,
    }

    return expectedCalories, expectedHydration, scriptItem
end

return Nutrition
