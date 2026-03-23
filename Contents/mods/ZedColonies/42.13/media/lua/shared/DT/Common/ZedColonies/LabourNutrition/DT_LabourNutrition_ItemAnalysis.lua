DT_Labour = DT_Labour or {}
DT_Labour.Nutrition = DT_Labour.Nutrition or {}
DT_Labour.Nutrition.Internal = DT_Labour.Nutrition.Internal or {}

local Nutrition = DT_Labour.Nutrition
local Internal = Nutrition.Internal

function Nutrition.GetItemNutrition(invItem)
    if not invItem then
        return 0, 0
    end

    local scriptItem = Internal.GetScriptItem(invItem)
    local instanceCalories = Internal.ClampAmount(Internal.ReadNumericValue(invItem, "getCalories"))
    local scriptCalories = Internal.ClampAmount(Internal.ReadNumericValue(scriptItem, "getCalories"))
    local instanceHungerCalories = Internal.NormalizeCaloriesFromHunger(Internal.ReadNumericValue(invItem, "getHungerChange"))
    local scriptHungerCalories = 0
    if scriptItem and DynamicTrading and DynamicTrading.Economy and DynamicTrading.Economy.Common then
        scriptHungerCalories = Internal.NormalizeCaloriesFromHunger(DynamicTrading.Economy.Common.GetNormalizedHunger(scriptItem))
    end

    local calories = Internal.ChooseStaticNutrition(instanceCalories, scriptCalories)
    if calories <= 0 then
        calories = Internal.ChooseStaticNutrition(instanceHungerCalories, scriptHungerCalories)
    end

    local dynamicFluidItem = Internal.IsWaterHydrationSource(invItem, scriptItem)
        and invItem.getFluidContainer
        and invItem:getFluidContainer()
    local instanceHydration = Internal.NormalizeHydrationPoints(Internal.ReadNumericValue(invItem, "getThirstChange"))
    local scriptHydration = Internal.NormalizeHydrationPoints(Internal.ReadNumericValue(scriptItem, "getThirstChange"))
    local hydration = 0

    if dynamicFluidItem then
        local fluidContainer = invItem:getFluidContainer()
        if fluidContainer and fluidContainer.getAmount then
            local amount = tonumber(fluidContainer:getAmount()) or 0
            if amount > 0 then
                hydration = amount > 10 and amount or (amount * 100)
            end
        end
    end

    if hydration <= 0 then
        hydration = Internal.ChooseStaticNutrition(instanceHydration, scriptHydration)
    end

    return calories, hydration
end

function Nutrition.BuildEntryFromItem(invItem)
    if not invItem then
        return nil, "Missing item."
    end

    local fullType = invItem:getFullType()
    if DT_Labour
        and DT_Labour.Config
        and DT_Labour.Config.IsMedicalProvisionFullType
        and DT_Labour.Config.IsMedicalProvisionFullType(fullType) then
        return {
            fullType = fullType,
            displayName = invItem.getDisplayName and invItem:getDisplayName() or fullType,
            itemID = invItem.getID and invItem:getID() or nil,
            provisionType = "medical",
            medicalUse = "bandage",
            treatmentUnitsRemaining = DT_Labour.Config.GetMedicalProvisionUnits(fullType)
        }
    end

    local calories, hydration = Nutrition.GetItemNutrition(invItem)
    if calories <= 0 and hydration <= 0 then
        return nil, "Item does not provide calories or hydration."
    end

    return {
        fullType = fullType,
        displayName = invItem.getDisplayName and invItem:getDisplayName() or fullType,
        itemID = invItem.getID and invItem:getID() or nil,
        provisionType = "nutrition",
        caloriesRemaining = calories,
        hydrationRemaining = hydration
    }
end

function Nutrition.BuildStarterReserveEntry(calories, hydration)
    return {
        fullType = "DT.LabourStarterReserve",
        displayName = "Starter Reserve",
        provisionType = "nutrition",
        caloriesRemaining = math.max(0, tonumber(calories) or 0),
        hydrationRemaining = math.max(0, tonumber(hydration) or 0)
    }
end

return Nutrition
