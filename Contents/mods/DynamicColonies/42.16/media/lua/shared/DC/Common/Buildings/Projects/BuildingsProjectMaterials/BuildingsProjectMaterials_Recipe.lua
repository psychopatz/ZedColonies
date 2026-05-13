DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Materials = Internal.ProjectMaterials or {}

Internal.ProjectMaterials = Materials

function Materials.BuildRecipeMap(recipe)
    local required = {}
    for _, entry in ipairs(recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local count = math.max(0, math.floor(tonumber(entry.count) or 0))
        if fullType ~= "" and count > 0 then
            required[fullType] = (required[fullType] or 0) + count
        end
    end
    return required
end

function Materials.HasRecipeEntries(required)
    for _, _ in pairs(required or {}) do
        return true
    end
    return false
end

function Materials.NormalizeMaterialCountMap(value)
    local counts = type(value) == "table" and value or {}
    local normalized = {}
    for fullType, count in pairs(counts) do
        local key = tostring(fullType or "")
        if key ~= "" then
            normalized[key] = math.max(0, math.floor(tonumber(count) or 0))
        end
    end
    return normalized
end

function Materials.CountRecipeUnits(recipe)
    local total = 0
    for _, entry in ipairs(recipe or {}) do
        total = total + math.max(0, math.floor(tonumber(entry.count) or 0))
    end
    return total
end

function Materials.CountSuppliedRecipeUnits(recipe, suppliedCounts)
    local total = 0
    for _, entry in ipairs(recipe or {}) do
        local fullType = tostring(entry.fullType or "")
        local required = math.max(0, math.floor(tonumber(entry.count) or 0))
        total = total + math.min(required, math.max(0, tonumber(suppliedCounts and suppliedCounts[fullType]) or 0))
    end
    return total
end

return Buildings