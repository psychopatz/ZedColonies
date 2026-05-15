DC_Buildings = DC_Buildings or {}
DC_Buildings.Production = DC_Buildings.Production or {}
DC_Buildings.Production.Internal = DC_Buildings.Production.Internal or {}

local Buildings = DC_Buildings
local Production = DC_Buildings.Production
local Internal = Production.Internal
local AbstractInventory = DC_Colony and DC_Colony.AbstractInventory or nil
local Config = DC_Colony and DC_Colony.Config or nil

Internal.lastProcessedHourByOwner = Internal.lastProcessedHourByOwner or {}

local function getOwnerKey(ownerUsername)
    local config = DC_Colony and DC_Colony.Config or nil
    return config and config.GetOwnerUsername and config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

local function canRunRecipe(ownerUsername, recipe)
    if recipe and recipe.inputs and #recipe.inputs > 0 then
        if not (AbstractInventory
            and AbstractInventory.CanConsumeCategories
            and AbstractInventory.CanConsumeCategories(ownerUsername, recipe.inputs)) then
            return false
        end
    end

    if recipe and recipe.foodNutrition then
        return AbstractInventory
            and AbstractInventory.CanConsumeFoodNutrition
            and AbstractInventory.CanConsumeFoodNutrition(
                ownerUsername,
                { categories = recipe.foodNutrition.categories or {} },
                recipe.foodNutrition.calories,
                recipe.foodNutrition.hydration
            ) == true
    end

    return true
end

local function isFoodCategory(categoryId)
    local definition = Config and Config.GetItemCategoryDefinition and Config.GetItemCategoryDefinition(categoryId) or nil
    return tostring(definition and definition.group or "") == "Food"
end

local function applyOutputs(ownerUsername, recipe, capture)
    local totalOutputUnits = 0
    local totalFoodOutputUnits = 0
    for _, output in ipairs(recipe and recipe.outputs or {}) do
        local count = math.max(0, math.floor(tonumber(output and output.count) or 0))
        totalOutputUnits = totalOutputUnits + count
        if output and output.category and isFoodCategory(output.category) then
            totalFoodOutputUnits = totalFoodOutputUnits + count
        end
    end

    local totalWeightConsumed = math.max(0, tonumber(capture and capture.totalWeightConsumed) or 0)
    local totalCaloriesConsumed = math.max(0, tonumber(capture and capture.totalCaloriesConsumed) or 0)
    local totalHydrationConsumed = math.max(0, tonumber(capture and capture.totalHydrationConsumed) or 0)

    for _, output in ipairs(recipe and recipe.outputs or {}) do
        if output.category and AbstractInventory and AbstractInventory.AddCategory then
            local outputCount = math.max(0, math.floor(tonumber(output.count) or 0))
            local totalWeight = totalOutputUnits > 0 and (totalWeightConsumed * (outputCount / totalOutputUnits)) or 0
            local totalCalories = 0
            local totalHydration = 0
            if isFoodCategory(output.category) and totalFoodOutputUnits > 0 then
                totalCalories = totalCaloriesConsumed * (outputCount / totalFoodOutputUnits)
                totalHydration = totalHydrationConsumed * (outputCount / totalFoodOutputUnits)
            end
            local added = AbstractInventory.AddCategory(ownerUsername, output.category, outputCount, {
                totalWeight = totalWeight,
                totalCalories = totalCalories,
                totalHydration = totalHydration,
            })
            if added <= 0 then
                return false
            end
        end
    end
    return true
end

local function processBuilding(ownerUsername, instance)
    local recipes = Production.GetRecipesForBuilding and Production.GetRecipesForBuilding(instance and instance.buildingType) or {}
    local buildingLevel = math.max(0, math.floor(tonumber(instance and instance.level) or 0))
    local cycles = 0

    for _, recipe in ipairs(recipes) do
        if cycles >= math.max(1, math.floor(tonumber(Production.Config and Production.Config.MaxCyclesPerPass) or 1)) then
            break
        end
        if buildingLevel >= math.max(1, math.floor(tonumber(recipe.requiredLevel) or 1))
            and canRunRecipe(ownerUsername, recipe) then
            local reasonMeta = {
                reason = "building_production",
                buildingID = instance and instance.buildingID,
                buildingType = instance and instance.buildingType,
                recipeID = recipe.id,
                capture = {},
            }
            local consumedCategories = true
            local consumedNutrition = true
            if recipe.inputs and #recipe.inputs > 0 then
                consumedCategories = AbstractInventory
                    and AbstractInventory.ConsumeCategories
                    and AbstractInventory.ConsumeCategories(ownerUsername, recipe.inputs, reasonMeta)
                    or false
            end
            if consumedCategories and recipe.foodNutrition then
                consumedNutrition = AbstractInventory
                    and AbstractInventory.ConsumeFoodNutrition
                    and AbstractInventory.ConsumeFoodNutrition(
                        ownerUsername,
                        { categories = recipe.foodNutrition.categories or {} },
                        recipe.foodNutrition.calories,
                        recipe.foodNutrition.hydration,
                        reasonMeta
                    )
                    or false
            end

            if consumedCategories and consumedNutrition then
                if applyOutputs(ownerUsername, recipe, reasonMeta.capture) then
                    cycles = cycles + 1
                end
            end
        end
    end

    return cycles
end

function Production.ProcessOwner(ownerUsername, currentHour)
    local owner = getOwnerKey(ownerUsername)
    local lastHour = tonumber(Internal.lastProcessedHourByOwner[owner]) or -1
    if lastHour >= 0 and (tonumber(currentHour) or 0) - lastHour < (tonumber(Production.Config and Production.Config.IntervalHours) or 1) then
        return 0
    end

    Internal.lastProcessedHourByOwner[owner] = tonumber(currentHour) or lastHour
    local totalCycles = 0
    for _, instance in ipairs(Buildings.GetBuildingsForOwner and Buildings.GetBuildingsForOwner(owner) or {}) do
        if math.floor(tonumber(instance and instance.level) or 0) > 0 then
            totalCycles = totalCycles + processBuilding(owner, instance)
        end
    end
    return totalCycles
end

function Production.ProcessAllOwners(currentHour)
    local registry = DC_Colony and DC_Colony.Registry or nil
    local totalCycles = 0
    for _, ownerUsername in ipairs(registry and registry.GetOwnerUsernames and registry.GetOwnerUsernames() or {}) do
        totalCycles = totalCycles + Production.ProcessOwner(ownerUsername, currentHour)
    end
    return totalCycles
end

return Production
