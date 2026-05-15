DC_Buildings = DC_Buildings or {}
DC_Buildings.Production = DC_Buildings.Production or {}
DC_Buildings.Production.Internal = DC_Buildings.Production.Internal or {}

local Production = DC_Buildings.Production
local Internal = Production.Internal
local AbstractInventory = DC_Colony and DC_Colony.AbstractInventory or nil

local function getCategoryDisplayName(categoryId)
    local config = DC_Colony and DC_Colony.Config or nil
    local definition = config and config.GetItemCategoryDefinition and config.GetItemCategoryDefinition(categoryId) or nil
    return tostring(definition and definition.displayName or categoryId or "Unknown")
end

local function buildRecipeDisplayName(recipeID)
    local raw = tostring(recipeID or "Production")
    raw = string.gsub(raw, "_", " ")
    raw = string.gsub(raw, "(%a)([%w_']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest or "")
    end)
    return raw
end

local function buildRequirementEntries(ownerUsername, inputs)
    local entries = {}
    local ready = true

    for _, input in ipairs(inputs or {}) do
        local categoryId = tostring(input and input.category or "")
        local requiredCount = math.max(0, math.floor(tonumber(input and input.count) or 0))
        local availableCount = AbstractInventory and AbstractInventory.GetCategoryCount and AbstractInventory.GetCategoryCount(ownerUsername, categoryId) or 0
        local remainingCount = math.max(0, requiredCount - availableCount)
        local satisfied = remainingCount <= 0
        if satisfied ~= true then
            ready = false
        end

        entries[#entries + 1] = {
            category = categoryId,
            displayName = getCategoryDisplayName(categoryId),
            count = requiredCount,
            available = math.max(0, math.floor(tonumber(availableCount) or 0)),
            supplied = satisfied and requiredCount or 0,
            remaining = remainingCount,
            satisfied = satisfied,
        }
    end

    return entries, ready
end

local function buildFoodNutritionEntry(ownerUsername, foodNutrition)
    if type(foodNutrition) ~= "table" then
        return nil, true
    end

    local availableCalories = 0
    local availableHydration = 0
    local snapshot = AbstractInventory and AbstractInventory.GetFoodNutritionSnapshot and AbstractInventory.GetFoodNutritionSnapshot(ownerUsername) or {}
    local allowed = {}
    for _, categoryId in ipairs(foodNutrition.categories or {}) do
        local key = tostring(categoryId or "")
        if key ~= "" then
            allowed[key] = true
        end
    end

    for categoryId, entry in pairs(snapshot or {}) do
        if allowed[tostring(categoryId or "")] == true then
            availableCalories = availableCalories + math.max(0, tonumber(entry and entry.calories) or 0)
            availableHydration = availableHydration + math.max(0, tonumber(entry and entry.hydration) or 0)
        end
    end

    local requiredCalories = math.max(0, tonumber(foodNutrition.calories) or 0)
    local requiredHydration = math.max(0, tonumber(foodNutrition.hydration) or 0)
    local satisfied = availableCalories + 0.0001 >= requiredCalories and availableHydration + 0.0001 >= requiredHydration

    return {
        kind = "foodNutrition",
        displayName = "Food Nutrition",
        categories = foodNutrition.categories or {},
        categoryLabels = (function()
            local labels = {}
            for _, categoryId in ipairs(foodNutrition.categories or {}) do
                labels[#labels + 1] = getCategoryDisplayName(categoryId)
            end
            return labels
        end)(),
        count = 1,
        requiredCalories = requiredCalories,
        requiredHydration = requiredHydration,
        availableCalories = availableCalories,
        availableHydration = availableHydration,
        remainingCalories = math.max(0, requiredCalories - availableCalories),
        remainingHydration = math.max(0, requiredHydration - availableHydration),
        satisfied = satisfied,
    }, satisfied
end

local function buildOutputEntries(outputs)
    local entries = {}
    for _, output in ipairs(outputs or {}) do
        local categoryId = tostring(output and output.category or "")
        entries[#entries + 1] = {
            category = categoryId,
            displayName = getCategoryDisplayName(categoryId),
            count = math.max(0, math.floor(tonumber(output and output.count) or 0)),
        }
    end
    return entries
end

function Production.GetRecipeSnapshots(ownerUsername, buildingType, buildingLevel)
    local recipes = Production.GetRecipesForBuilding and Production.GetRecipesForBuilding(buildingType) or {}
    local snapshots = {}
    local normalizedLevel = math.max(0, math.floor(tonumber(buildingLevel) or 0))

    for _, recipe in ipairs(recipes or {}) do
        local requiredLevel = math.max(1, math.floor(tonumber(recipe and recipe.requiredLevel) or 1))
        if normalizedLevel >= requiredLevel then
            local inputEntries, ready = buildRequirementEntries(ownerUsername, recipe.inputs)
            if recipe.foodNutrition then
                local foodEntry, foodReady = buildFoodNutritionEntry(ownerUsername, recipe.foodNutrition)
                if foodEntry then
                    inputEntries[#inputEntries + 1] = foodEntry
                end
                ready = ready == true and foodReady == true
            end
            snapshots[#snapshots + 1] = {
                id = tostring(recipe.id or ""),
                displayName = buildRecipeDisplayName(recipe.id),
                requiredLevel = requiredLevel,
                ready = ready == true,
                inputs = inputEntries,
                outputs = buildOutputEntries(recipe.outputs),
            }
        end
    end

    return snapshots
end

function Production.GetBuildingMetrics(ownerUsername, instance)
    if type(instance) ~= "table" then
        return {}
    end

    local buildingType = tostring(instance.buildingType or "")
    local buildingLevel = math.max(0, math.floor(tonumber(instance.level) or 0))
    if buildingLevel <= 0 then
        return {}
    end

    local recipes = Production.GetRecipeSnapshots(ownerUsername, buildingType, buildingLevel)
    if #recipes <= 0 then
        return {}
    end

    local readyCount = 0
    for _, recipe in ipairs(recipes) do
        if recipe.ready == true then
            readyCount = readyCount + 1
        end
    end

    return {
        productionRecipeCount = #recipes,
        productionReadyCount = readyCount,
        productionIntervalHours = math.max(1, math.floor(tonumber(Production.Config and Production.Config.IntervalHours) or 1)),
        productionMaxCyclesPerPass = math.max(1, math.floor(tonumber(Production.Config and Production.Config.MaxCyclesPerPass) or 1)),
        productionRecipes = recipes,
    }
end

return Production
