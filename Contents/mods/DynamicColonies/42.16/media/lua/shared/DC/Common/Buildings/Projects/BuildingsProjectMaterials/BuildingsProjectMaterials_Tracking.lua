DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Materials = Internal.ProjectMaterials or {}

Internal.ProjectMaterials = Materials

function Materials.EnsureProjectMaterialTracking(project)
    if type(project) ~= "table" then
        return nil
    end

    project.materialTrackingVersion = math.max(0, math.floor(tonumber(project.materialTrackingVersion) or 0))
    project.materialCounts = Materials.NormalizeMaterialCountMap(project.materialCounts)

    if project.materialTrackingVersion <= 0 then
        project.materialTrackingVersion = 1
        project.materialCounts = Materials.BuildRecipeMap(project.recipe)
        project.materialState = "Ready"
    end

    return project
end

function Materials.PullProjectMaterialsFromWarehouse(project)
    local warehouseApi = Materials.GetWarehouse()
    local owner = project and Materials.GetOwnerUsername(project.ownerUsername) or nil
    local warehouse = owner and warehouseApi and warehouseApi.GetOwnerWarehouse and warehouseApi.GetOwnerWarehouse(owner) or nil
    if not project or not warehouse then
        return 0
    end

    Materials.EnsureProjectMaterialTracking(project)

    local required = Materials.BuildRecipeMap(project.recipe)
    if not Materials.HasRecipeEntries(required) then
        return 0
    end

    local moved = 0
    local outputLedger = warehouse.ledgers and warehouse.ledgers.output or {}

    for recipeKey, requiredCount in pairs(required) do
        local kind, value = Materials.ParseMaterialCountKey(recipeKey)
        local needed = math.max(0, requiredCount - (project.materialCounts[recipeKey] or 0))
        if needed > 0 and kind == "category" and warehouseApi and warehouseApi.TakeCategoryUnits then
            local taken = warehouseApi.TakeCategoryUnits(owner, value, needed)
            if taken and taken > 0 then
                project.materialCounts[recipeKey] = math.max(0, tonumber(project.materialCounts[recipeKey]) or 0) + taken
                moved = moved + taken
            end
        end
    end

    for index = #outputLedger, 1, -1 do
        local entry = outputLedger[index]
        local fullType = tostring(entry and entry.fullType or "")
        local recipeKey = Materials.GetMaterialCountKeyForFullType(fullType)
        local needed = math.max(0, (required[recipeKey] or 0) - (project.materialCounts[recipeKey] or 0))
        if fullType ~= "" and needed > 0 and entry then
            local qty = math.max(0, math.floor(tonumber(entry.qty) or 0))
            local toTake = math.min(qty, needed)
            if toTake > 0 then
                project.materialCounts[recipeKey] = math.max(0, tonumber(project.materialCounts[recipeKey]) or 0) + toTake
                qty = qty - toTake
                moved = moved + toTake
                if qty <= 0 then
                    table.remove(outputLedger, index)
                else
                    entry.qty = qty
                end
            end
        end
    end

    if moved > 0 and warehouseApi and warehouseApi.Recalculate then
        warehouseApi.Recalculate(warehouse)
    end

    return moved
end

function Materials.BuildProjectMaterialStatus(project, sourcePlayer, availableCounts)
    Materials.EnsureProjectMaterialTracking(project)

    local owner = project and Materials.GetOwnerUsername(project.ownerUsername) or nil
    local resolvedAvailableCounts = availableCounts or (owner and Materials.GetAvailableMaterialCounts(owner, sourcePlayer) or {})
    local entries = {}
    local hasAll = true
    local totalRequired = Materials.CountRecipeUnits(project and project.recipe or {})
    local totalSupplied = Materials.CountSuppliedRecipeUnits(project and project.recipe or {}, project and project.materialCounts or nil)

    for _, entry in ipairs(project and project.recipe or {}) do
        local key = Materials.GetRecipeEntryKey(entry)
        local required = math.max(0, math.floor(tonumber(entry.count) or 0))
        local supplied = math.min(required, math.max(0, tonumber(project and project.materialCounts and project.materialCounts[key]) or 0))
        local available = math.max(0, resolvedAvailableCounts[key] or 0)
        local remaining = math.max(0, required - supplied)
        local recipeEntry = {
            fullType = entry.fullType,
            category = entry.category,
            key = key,
            displayName = Materials.GetRecipeEntryDisplayName(entry),
            count = required,
            available = available,
            supplied = supplied,
            remaining = remaining,
            satisfied = remaining <= 0
        }
        if recipeEntry.satisfied ~= true then
            hasAll = false
        end
        entries[#entries + 1] = recipeEntry
    end

    return {
        hasAll = hasAll,
        entries = entries,
        totalRequired = totalRequired,
        totalSupplied = totalSupplied,
        progressRatio = totalRequired > 0 and math.max(0, math.min(1, totalSupplied / totalRequired)) or 1
    }
end

function Materials.ConsumeRecipe(ownerUsername, recipe)
    local warehouseApi = Materials.GetWarehouse()
    local warehouse = warehouseApi and warehouseApi.GetOwnerWarehouse and warehouseApi.GetOwnerWarehouse(ownerUsername) or nil
    if not warehouse then
        return false
    end

    local required = Materials.BuildRecipeMap(recipe)
    if not Materials.HasRecipeEntries(required) then
        return true
    end

    local categoryRequirements = {}
    local outputLedger = warehouse.ledgers and warehouse.ledgers.output or {}

    for itemKey, needed in pairs(required) do
        local kind, value = Materials.ParseMaterialCountKey(itemKey)
        if kind == "category" then
            categoryRequirements[#categoryRequirements + 1] = {
                category = value,
                count = needed,
            }
        else
            local available = 0
            for _, entry in ipairs(outputLedger) do
                if entry.fullType == value then
                    available = available + math.max(0, math.floor(tonumber(entry.qty) or 0))
                end
            end
            if available < needed then
                return false
            end
        end
    end

    if #categoryRequirements > 0 and not (warehouseApi and warehouseApi.CanConsumeCategories and warehouseApi.CanConsumeCategories(ownerUsername, categoryRequirements)) then
        return false
    end

    if #categoryRequirements > 0 and warehouseApi and warehouseApi.ConsumeCategories then
        warehouseApi.ConsumeCategories(ownerUsername, categoryRequirements, {
            reason = "project_recipe",
        })
    end

    for index = #outputLedger, 1, -1 do
        local entry = outputLedger[index]
        local fullType = tostring(entry and entry.fullType or "")
        local needed = required[Materials.GetMaterialCountKeyForFullType(fullType)]
        if needed and needed > 0 and entry then
            local qty = math.max(0, math.floor(tonumber(entry.qty) or 0))
            local toTake = math.min(qty, needed)
            qty = qty - toTake
            required[Materials.GetMaterialCountKeyForFullType(fullType)] = needed - toTake
            if qty <= 0 then
                table.remove(outputLedger, index)
            else
                entry.qty = qty
            end
        end
    end

    if warehouseApi and warehouseApi.Recalculate then
        warehouseApi.Recalculate(warehouse)
    end
    return true
end

Internal.BuildingsConsumeRecipe = Materials.ConsumeRecipe

return Buildings
