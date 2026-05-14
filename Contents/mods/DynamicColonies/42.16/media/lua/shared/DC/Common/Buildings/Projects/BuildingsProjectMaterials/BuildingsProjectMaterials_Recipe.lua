DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Materials = Internal.ProjectMaterials or {}

Internal.ProjectMaterials = Materials

function Materials.GetMaterialCountKeyForFullType(fullType)
    local normalized = tostring(fullType or "")
    if normalized == "" then
        return ""
    end
    return "fullType:" .. normalized
end

function Materials.GetMaterialCountKeyForCategory(categoryId)
    local normalized = tostring(categoryId or "")
    if normalized == "" then
        return ""
    end
    return "category:" .. normalized
end

function Materials.GetRecipeEntryKey(entry)
    if type(entry) ~= "table" then
        return ""
    end
    if entry.category then
        return Materials.GetMaterialCountKeyForCategory(entry.category)
    end
    return Materials.GetMaterialCountKeyForFullType(entry.fullType)
end

function Materials.ParseMaterialCountKey(key)
    local normalized = tostring(key or "")
    if string.find(normalized, "category:", 1, true) == 1 then
        return "category", string.sub(normalized, 10)
    end
    if string.find(normalized, "fullType:", 1, true) == 1 then
        return "fullType", string.sub(normalized, 10)
    end
    return "fullType", normalized
end

function Materials.GetRecipeEntryDisplayName(entry)
    if type(entry) ~= "table" then
        return "Unknown"
    end
    if entry.category then
        local definition = DC_Colony and DC_Colony.Config and DC_Colony.Config.GetItemCategoryDefinition
            and DC_Colony.Config.GetItemCategoryDefinition(entry.category) or nil
        return tostring(definition and definition.displayName or entry.category or "Unknown")
    end
    return Materials.GetDisplayName(entry.fullType)
end

function Materials.BuildRecipeMap(recipe)
    local required = {}
    for _, entry in ipairs(recipe or {}) do
        local key = Materials.GetRecipeEntryKey(entry)
        local count = math.max(0, math.floor(tonumber(entry.count) or 0))
        if key ~= "" and count > 0 then
            required[key] = (required[key] or 0) + count
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
    for itemKey, count in pairs(counts) do
        local key = tostring(itemKey or "")
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
        local key = Materials.GetRecipeEntryKey(entry)
        local required = math.max(0, math.floor(tonumber(entry.count) or 0))
        total = total + math.min(required, math.max(0, tonumber(suppliedCounts and suppliedCounts[key]) or 0))
    end
    return total
end

return Buildings
