DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

function Internal.getDisplayNameForFullType(fullType)
    if not fullType or not getScriptManager then
        return tostring(fullType or "Unknown Item")
    end

    local item = getScriptManager():getItem(fullType)
    if item and item.getDisplayName then
        return item:getDisplayName()
    end

    return tostring(fullType or "Unknown Item")
end

local function isValidItemTexture(tex)
    return tex and tex.getName and tex:getName() ~= "Question_Highlight"
end

local function safeCall(target, methodName, ...)
    if not target or not target[methodName] then
        return nil
    end

    local ok, result = pcall(target[methodName], target, ...)
    if ok then
        return result
    end

    return nil
end

local function tryTexture(textureName)
    if not textureName or textureName == "" then
        return nil
    end

    local tex = getTexture(textureName)
    if isValidItemTexture(tex) then
        return tex
    end

    return nil
end

local function normalizeIconVariants(rawVariants)
    if not rawVariants then
        return nil
    end

    if type(rawVariants) == "string" then
        local variants = {}
        for entry in string.gmatch(rawVariants, "([^;]+)") do
            entry = entry:gsub("^%s+", ""):gsub("%s+$", "")
            if entry ~= "" then
                variants[#variants + 1] = entry
            end
        end
        return #variants > 0 and variants or nil
    end

    if type(rawVariants) == "table" then
        return #rawVariants > 0 and rawVariants or nil
    end

    if rawVariants.size and rawVariants.get then
        local variants = {}
        for i = 0, rawVariants:size() - 1 do
            local entry = rawVariants:get(i)
            if entry and tostring(entry) ~= "" then
                variants[#variants + 1] = tostring(entry)
            end
        end
        return #variants > 0 and variants or nil
    end

    return nil
end

local function getScriptIconVariants(script)
    if not script then
        return nil
    end

    local candidates = {
        safeCall(script, "getIconsForTexture"),
        safeCall(script, "getIconsForTextures"),
        safeCall(script, "getIconsForTextureString"),
        safeCall(script, "getIconsForTextureChoices"),
    }

    for _, candidate in ipairs(candidates) do
        local variants = normalizeIconVariants(candidate)
        if variants then
            return variants
        end
    end

    return nil
end

local function resolveScriptVariantTexture(script)
    local variants = getScriptIconVariants(script)
    if not variants then
        return nil
    end

    for _, variant in ipairs(variants) do
        local tex = tryTexture("Item_" .. variant)
            or tryTexture(variant)
            or tryTexture("media/textures/Item_" .. variant .. ".png")
        if tex then
            return tex
        end
    end

    return nil
end

local function resolveInventoryItemTexture(item)
    if not item then
        return nil
    end

    if item.getTex then
        local tex = item:getTex()
        if isValidItemTexture(tex) then
            return tex
        end
    end

    if item.getIcon then
        local icon = item:getIcon()
        if icon and type(icon) ~= "string" and isValidItemTexture(icon) then
            return icon
        end
    end

    local tex = safeCall(item, "getTexture")
    if isValidItemTexture(tex) then
        return tex
    end

    return nil
end

function Internal.getTextureForFullType(fullType)
    if not fullType then
        return nil
    end

    local cache = Internal.TextureCache or {}
    Internal.TextureCache = cache
    if cache[fullType] ~= nil then
        return cache[fullType]
    end

    local texture = nil
    local script = getScriptManager and getScriptManager():getItem(fullType) or nil

    if DT_TradingWindow and DT_TradingWindow.GetItemTexture then
        texture = DT_TradingWindow.GetItemTexture(fullType, nil)
    end

    if not isValidItemTexture(texture) and script then
        texture = resolveScriptVariantTexture(script)
    end

    if not isValidItemTexture(texture) and script then
        local iconStr = safeCall(script, "getIcon")
        if iconStr and iconStr ~= "" then
            texture = tryTexture("Item_" .. iconStr)
                or tryTexture(iconStr)
                or tryTexture("media/textures/Item_" .. iconStr .. ".png")
        end
    end

    if not isValidItemTexture(texture) and script and script.getClothingItem then
        local clothingItem = script:getClothingItem()
        if clothingItem and clothingItem ~= "" then
            texture = tryTexture("Item_" .. clothingItem) or tryTexture(clothingItem)
        end
    end

    if not isValidItemTexture(texture) and InventoryItemFactory and InventoryItemFactory.CreateItem then
        local ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
        if ok and item then
            texture = resolveInventoryItemTexture(item)
        end
    end

    cache[fullType] = isValidItemTexture(texture) and texture or false
    return cache[fullType] or nil
end

