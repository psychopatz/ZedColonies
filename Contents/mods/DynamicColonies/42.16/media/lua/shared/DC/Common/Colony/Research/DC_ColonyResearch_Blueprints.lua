DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

local Research = DC_Colony.Research
local Internal = Research.Internal
Internal.RecipeBlueprintCache = Internal.RecipeBlueprintCache or {}

local function safeCall(target, methodName, ...)
    if not target or not methodName or type(target[methodName]) ~= "function" then
        return nil
    end

    local ok, result = pcall(target[methodName], target, ...)
    if ok then
        return result
    end
    return nil
end

local function iterateCollection(collection, callback)
    if not collection or not callback then
        return
    end

    if type(collection) == "table" then
        for _, value in ipairs(collection) do
            callback(value)
        end
        return
    end

    if collection.size and collection.get then
        local size = tonumber(safeCall(collection, "size")) or tonumber(collection:size()) or 0
        local index = 0
        while index < size do
            callback(collection:get(index))
            index = index + 1
        end
        return
    end

    local iterator = safeCall(collection, "iterator")
    if iterator and iterator.hasNext and iterator.next then
        while iterator:hasNext() do
            callback(iterator:next())
        end
    end
end

local function normalizeFullType(moduleName, itemType)
    local normalizedType = tostring(itemType or "")
    if normalizedType == "" then
        return ""
    end
    if string.find(normalizedType, "%.") then
        return normalizedType
    end

    local normalizedModule = tostring(moduleName or "")
    if normalizedModule == "" then
        return normalizedType
    end
    return normalizedModule .. "." .. normalizedType
end

local function getTags(fullType)
    local config = DC_Colony and DC_Colony.Config or nil
    return config and config.FindItemTags and config.FindItemTags(fullType) or {}
end

local function getRegistryEntry(fullType)
    local masterList = DynamicTrading and DynamicTrading.Config and DynamicTrading.Config.MasterList or nil
    return masterList and masterList[tostring(fullType or "")] or nil
end

local function getBuildingsModule()
    return DC_Buildings or nil
end

local function getProductionStations()
    local buildings = getBuildingsModule()
    local production = buildings and buildings.Production or nil
    return production and production.Config and production.Config.ColonyProductionStations or nil
end

local function isKnownRegistryItem(fullType)
    if getRegistryEntry(fullType) then
        return true
    end

    local tags = getTags(fullType)
    return type(tags) == "table" and #tags > 0
end

local function resolveBuildingFromTags(tags)
    local stations = getProductionStations()
    local config = DC_Colony and DC_Colony.Config or nil
    if type(stations) ~= "table" or type(tags) ~= "table" then
        return nil
    end

    local bestBuilding = nil
    local bestScore = -1
    for buildingType, queries in pairs(stations) do
        for _, queryTag in ipairs(type(queries) == "table" and queries or {}) do
            if config and config.HasMatchingTag and config.HasMatchingTag(tags, queryTag) then
                local score = string.len(tostring(queryTag or ""))
                if score > bestScore then
                    bestScore = score
                    bestBuilding = tostring(buildingType or "")
                end
            end
        end
    end

    return bestBuilding
end

local function getBuildingDisplayName(buildingType)
    local buildings = getBuildingsModule()
    local definition = buildings and buildings.Config and buildings.Config.GetDefinition and buildings.Config.GetDefinition(buildingType) or nil
    if definition and definition.displayName then
        return tostring(definition.displayName)
    end
    return tostring(buildingType or "Workshop")
end

local function getRecipeName(recipe)
    return tostring(
        safeCall(recipe, "getOriginalname")
        or safeCall(recipe, "getName")
        or recipe and recipe.name
        or "Unknown Recipe"
    )
end

local function getRecipeResult(recipe)
    return safeCall(recipe, "getResult") or recipe and recipe.Result or recipe and recipe.result or nil
end

local function getRecipeResultFullType(recipe)
    local result = getRecipeResult(recipe)
    if not result then
        return ""
    end

    local fullType = safeCall(result, "getFullType") or result.fullType
    if fullType and tostring(fullType) ~= "" then
        return tostring(fullType)
    end

    local moduleName = safeCall(result, "getModule") or result.module or result.moduleName
    local itemType = safeCall(result, "getType") or result.type or result.itemType
    return normalizeFullType(moduleName, itemType)
end

local function getRecipeResultCount(recipe)
    local result = getRecipeResult(recipe)
    local count = tonumber(result and (safeCall(result, "getCount") or result.count)) or 1
    return math.max(1, math.floor(count))
end

local function getRecipeSources(recipe)
    return safeCall(recipe, "getSource") or recipe and recipe.Source or recipe and recipe.sources or nil
end

local function getRecipeModuleName(recipe)
    return tostring(safeCall(recipe, "getModule") or recipe and recipe.module or recipe and recipe.moduleName or "")
end

local function isWaterSource(source)
    if safeCall(source, "isWater") == true then
        return true
    end
    if source and source.isWater == true then
        return true
    end

    local items = safeCall(source, "getItems") or source and source.items or nil
    local foundWater = false
    iterateCollection(items, function(itemName)
        local normalized = string.lower(tostring(itemName or ""))
        if normalized == "water" or normalized == "source=water" then
            foundWater = true
        end
    end)
    return foundWater
end

local function isKeepSource(source)
    if safeCall(source, "isKeep") == true then
        return true
    end
    if source and source.keep == true then
        return true
    end
    return false
end

local function getSourceCount(source)
    local count = tonumber(safeCall(source, "getCount") or source and source.count) or 1
    return math.max(1, math.floor(count))
end

local function resolveSourceItemFullType(rawValue, recipe)
    local value = tostring(rawValue or "")
    if value == "" then
        return ""
    end

    if string.find(value, "%.") then
        return value
    end

    local manager = getScriptManager and getScriptManager() or nil
    local recipeModule = getRecipeModuleName(recipe)
    local preferredCandidates = {}
    if recipeModule ~= "" then
        preferredCandidates[#preferredCandidates + 1] = recipeModule .. "." .. value
    end
    preferredCandidates[#preferredCandidates + 1] = "Base." .. value
    preferredCandidates[#preferredCandidates + 1] = value

    for _, candidate in ipairs(preferredCandidates) do
        local found = manager and safeCall(manager, "FindItem", candidate) or nil
        if found then
            local fullType = safeCall(found, "getFullName") or safeCall(found, "getFullType") or nil
            if fullType and tostring(fullType) ~= "" then
                return tostring(fullType)
            end
            if string.find(candidate, "%.") then
                return tostring(candidate)
            end
        end
    end

    if recipeModule ~= "" then
        return recipeModule .. "." .. value
    end
    return "Base." .. value
end

local function collectSourceItems(source, recipe)
    local items = {}
    local seen = {}
    local rawItems = safeCall(source, "getItems") or source and source.items or nil
    iterateCollection(rawItems, function(rawValue)
        local value = tostring(rawValue or "")
        if value == "" then
            return
        end

        local slashIndex = string.find(value, "/", 1, true)
        if slashIndex then
            local fragment = string.sub(value, 1, slashIndex - 1)
            if fragment ~= "" then
                value = fragment
            end
        end

        if string.find(value, "=", 1, true) then
            return
        end

        value = resolveSourceItemFullType(value, recipe)
        if value == "" then
            return
        end

        if not seen[value] then
            seen[value] = true
            items[#items + 1] = value
        end
    end)
    return items
end

local function buildCategoryInput(alternatives, count)
    local config = DC_Colony and DC_Colony.Config or nil
    local resolvedCategory = nil
    local resolvedGroup = nil
    for _, fullType in ipairs(alternatives or {}) do
        local converted = config and config.GetItemCategoryData and config.GetItemCategoryData(fullType) or nil
        if not converted or converted.isFallback == true then
            return nil
        end

        local categoryId = tostring(converted.category or "")
        local groupId = tostring(converted.group or "")
        if categoryId == "" then
            return nil
        end

        if resolvedCategory == nil then
            resolvedCategory = categoryId
            resolvedGroup = groupId
        elseif resolvedCategory ~= categoryId or resolvedGroup ~= groupId then
            return nil
        end
    end

    if resolvedCategory == nil then
        return nil
    end

    return {
        kind = "category",
        category = resolvedCategory,
        count = count,
    }
end

local function buildSourceInput(source, recipe)
    local count = getSourceCount(source)
    if isKeepSource(source) then
        return nil, true
    end
    if isWaterSource(source) then
        return {
            kind = "category",
            category = "Water",
            count = count,
        }, true
    end

    local items = collectSourceItems(source, recipe)
    if #items <= 0 then
        return nil, false
    end
    if #items == 1 then
        return {
            kind = "fullType",
            fullType = items[1],
            count = count,
        }, true
    end

    local categoryInput = buildCategoryInput(items, count)
    if categoryInput then
        return categoryInput, true
    end

    return nil, false
end

local function buildRecipeInputs(recipe)
    local inputs = {}
    local sources = getRecipeSources(recipe)
    local isSupported = true

    iterateCollection(sources, function(source)
        if isSupported ~= true then
            return
        end

        local input, okay = buildSourceInput(source, recipe)
        if okay ~= true then
            isSupported = false
            return
        end
        if input then
            inputs[#inputs + 1] = input
        end
    end)

    if isSupported ~= true then
        return nil
    end
    return inputs
end

local function getAllRecipes()
    local manager = getScriptManager and getScriptManager() or nil
    if not manager then
        return nil
    end
    return safeCall(manager, "getAllRecipes")
end

local function buildRecipeBlueprint(fullType)
    local normalizedFullType = tostring(fullType or "")
    if normalizedFullType == "" or not isKnownRegistryItem(normalizedFullType) then
        return nil
    end

    local tags = getTags(normalizedFullType)
    local buildingType = resolveBuildingFromTags(tags)
    if not buildingType or buildingType == "" then
        return nil
    end

    local config = DC_Colony and DC_Colony.Config or nil
    local converted = config and config.GetItemCategoryData and config.GetItemCategoryData(normalizedFullType) or nil
    local allRecipes = getAllRecipes()
    local selected = nil

    iterateCollection(allRecipes, function(recipe)
        if selected then
            return
        end

        if tostring(getRecipeResultFullType(recipe) or "") ~= normalizedFullType then
            return
        end

        local inputs = buildRecipeInputs(recipe)
        if not inputs then
            return
        end

        selected = {
            fullType = normalizedFullType,
            category = tostring(converted and converted.category or ""),
            group = tostring(converted and converted.group or ""),
            buildingType = buildingType,
            buildingDisplayName = getBuildingDisplayName(buildingType),
            inputs = inputs,
            workCost = Research.Config and Research.Config.GetBaseWork and Research.Config.GetBaseWork()
                or math.max(1, math.floor(tonumber(Research.Config and Research.Config.BaseWork) or 1000)),
            recipeName = getRecipeName(recipe),
            outputCount = getRecipeResultCount(recipe),
        }
    end)

    return selected
end

function Research.GetBlueprint(ownerUsername, fullType)
    local data = Internal.EnsureOwnerData(ownerUsername)
    return data and data.blueprints and data.blueprints[tostring(fullType or "")] or nil
end

function Research.IsBlueprintUnlocked(ownerUsername, fullType)
    return Research.GetBlueprint(ownerUsername, fullType) ~= nil
end

function Research.CanResearchItem(fullType)
    return Internal.BuildBlueprintRecord(fullType) ~= nil
end

function Internal.BuildBlueprintRecord(fullType)
    local normalizedFullType = tostring(fullType or "")
    if normalizedFullType == "" then
        return nil
    end

    local cached = Internal.RecipeBlueprintCache[normalizedFullType]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end

    local blueprint = buildRecipeBlueprint(normalizedFullType)
    Internal.RecipeBlueprintCache[normalizedFullType] = blueprint or false
    return blueprint
end

return Research
