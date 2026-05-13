DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Materials = Internal.ProjectMaterials or {}

Internal.ProjectMaterials = Materials

function Materials.BuildRecipeAvailability(ownerUsername, recipe, sourcePlayer, availableCounts)
    local resolvedAvailableCounts = availableCounts or Materials.GetAvailableMaterialCounts(ownerUsername, sourcePlayer)
    local entries = {}
    local hasAll = true

    for _, entry in ipairs(recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local required = math.max(0, math.floor(tonumber(entry.count) or 0))
        local available = resolvedAvailableCounts[fullType] or 0
        local recipeEntry = {
            fullType = fullType,
            displayName = Materials.GetDisplayName(fullType),
            count = required,
            available = available,
            satisfied = available >= required
        }
        if recipeEntry.satisfied ~= true then
            hasAll = false
        end
        entries[#entries + 1] = recipeEntry
    end

    return {
        hasAll = hasAll,
        entries = entries
    }
end

Internal.GetAvailableMaterialCounts = Materials.GetAvailableMaterialCounts
Internal.BuildRecipeAvailability = Materials.BuildRecipeAvailability

return Buildings