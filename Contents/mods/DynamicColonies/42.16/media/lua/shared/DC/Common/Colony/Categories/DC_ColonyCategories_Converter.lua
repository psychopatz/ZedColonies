DC_Colony = DC_Colony or {}
DC_Colony.Categories = DC_Colony.Categories or {}
DC_Colony.Categories.Internal = DC_Colony.Categories.Internal or {}

local Config = DC_Colony.Config
local Categories = DC_Colony.Categories
local Internal = Categories.Internal

Internal.ConvertCache = Internal.ConvertCache or {}

local function getMasterEntry(fullType)
    local masterList = DynamicTrading and DynamicTrading.Config and DynamicTrading.Config.MasterList or nil
    return masterList and masterList[tostring(fullType or "")] or nil
end

local function copyArray(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

local function copyConverted(source)
    local copied = {}
    for key, value in pairs(source or {}) do
        if key == "modifiers" then
            copied[key] = copyArray(value)
        else
            copied[key] = value
        end
    end
    return copied
end

local function getEntryName(entry, fullType)
    local name = entry and (entry.displayName or entry.name or entry.item) or nil
    if name and name ~= "" then
        return tostring(name)
    end
    return tostring(fullType or "")
end

local function resolveTagRule(tags)
    for _, rule in ipairs(Categories.TagRules or {}) do
        if Config.HasMatchingTag and Config.HasMatchingTag(tags, rule.tag) then
            return rule
        end
    end
    return nil
end

local function resolveNameHeuristic(fullType, entry)
    local lowered = string.lower(getEntryName(entry, fullType))
    local fullTypeLower = string.lower(tostring(fullType or ""))

    if string.find(lowered, "skill book", 1, true) then
        return { category = "SkillBooks", group = "Research" }
    end
    if string.find(lowered, "schematic", 1, true)
        or string.find(fullTypeLower, "schematic", 1, true) then
        return { category = "Schematics", group = "Research" }
    end
    if string.find(lowered, "manual", 1, true)
        or string.find(lowered, "magazine", 1, true)
        or string.find(fullTypeLower, "mag", 1, true) then
        return { category = "Books", group = "Research" }
    end
    if string.find(lowered, "book", 1, true) then
        return { category = "Books", group = "Research" }
    end
    if string.find(fullTypeLower, "infectedsamplequest", 1, true)
        or string.find(fullTypeLower, "sample", 1, true) then
        return { category = "ContaminatedMaterial", group = "Waste" }
    end
    if string.find(fullTypeLower, "quest", 1, true)
        or string.find(fullTypeLower, "package", 1, true) then
        return { category = "QuestGoods", group = "Waste" }
    end

    return nil
end

local function buildFallback(fullType)
    return {
        fullType = tostring(fullType or ""),
        group = "Waste",
        category = "Junk",
        modifiers = {},
        units = 1,
        matchedTag = nil,
        isFallback = true,
    }
end

function Categories.ClearCache()
    Internal.ConvertCache = {}
end

function Categories.Convert(fullType)
    local normalizedFullType = tostring(fullType or "")
    if normalizedFullType == "" then
        return buildFallback(fullType)
    end

    local cached = Internal.ConvertCache[normalizedFullType]
    if cached then
        return copyConverted(cached)
    end

    local entry = getMasterEntry(normalizedFullType)
    local tags = Config.FindItemTags and Config.FindItemTags(normalizedFullType) or {}
    local matchedRule = resolveTagRule(tags)
    local specialCase = nil
    local resolved = nil

    if matchedRule then
        resolved = {
            fullType = normalizedFullType,
            group = tostring(matchedRule.group or "Waste"),
            category = tostring(matchedRule.category or "Junk"),
            modifiers = Categories.ExtractModifiers and Categories.ExtractModifiers(tags) or {},
            units = 1,
            matchedTag = tostring(matchedRule.tag or ""),
            isFallback = false,
        }
    else
        specialCase = resolveNameHeuristic(normalizedFullType, entry)
        if specialCase then
            resolved = {
                fullType = normalizedFullType,
                group = tostring(specialCase.group or "Waste"),
                category = tostring(specialCase.category or "Junk"),
                modifiers = Categories.ExtractModifiers and Categories.ExtractModifiers(tags) or {},
                units = 1,
                matchedTag = nil,
                isFallback = false,
            }
        else
            resolved = buildFallback(normalizedFullType)
        end
    end

    local categoryDef = Categories.Get and Categories.Get(resolved.category) or nil
    if categoryDef and categoryDef.group then
        resolved.group = tostring(categoryDef.group)
    end

    Internal.ConvertCache[normalizedFullType] = copyConverted(resolved)
    return copyConverted(resolved)
end

return Categories
