DC_Buildings = DC_Buildings or {}
DC_Buildings.Production = DC_Buildings.Production or {}
DC_Buildings.Production.Internal = DC_Buildings.Production.Internal or {}

local Buildings = DC_Buildings
local Production = DC_Buildings.Production
local Internal = Production.Internal
local Warehouse = DC_Colony and DC_Colony.Warehouse or nil

Internal.lastProcessedHourByOwner = Internal.lastProcessedHourByOwner or {}

local function getOwnerKey(ownerUsername)
    local config = DC_Colony and DC_Colony.Config or nil
    return config and config.GetOwnerUsername and config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

local function canRunRecipe(ownerUsername, recipe)
    return Warehouse
        and Warehouse.CanConsumeCategories
        and Warehouse.CanConsumeCategories(ownerUsername, recipe and recipe.inputs or nil)
end

local function applyOutputs(ownerUsername, recipe)
    for _, output in ipairs(recipe and recipe.outputs or {}) do
        if output.category and Warehouse and Warehouse.AddCategory then
            Warehouse.AddCategory(ownerUsername, output.category, output.count or 0, {
                totalWeight = 0,
            })
        end
    end
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
            if Warehouse and Warehouse.ConsumeCategories and Warehouse.ConsumeCategories(ownerUsername, recipe.inputs, {
                reason = "building_production",
                buildingID = instance and instance.buildingID,
                buildingType = instance and instance.buildingType,
                recipeID = recipe.id,
            }) then
                applyOutputs(ownerUsername, recipe)
                cycles = cycles + 1
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
