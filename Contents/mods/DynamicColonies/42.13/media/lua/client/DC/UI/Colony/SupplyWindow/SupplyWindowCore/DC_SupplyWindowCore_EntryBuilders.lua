DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getUnitWeight(fullType)
    return math.max(0, tonumber(Internal.Config and Internal.Config.GetItemWeight and Internal.Config.GetItemWeight(fullType)) or 0)
end

local function getTotalWeight(fullType, qty)
    return getUnitWeight(fullType) * math.max(1, tonumber(qty) or 1)
end

function Internal.getCachedInventoryEntryStaticData(fullType)
    local key = tostring(fullType or "")
    if key == "" then
        return {
            treatmentUnits = 0,
            provisionType = "nutrition",
            unitWeight = 0,
            texture = nil,
            isMedicalProvision = false,
        }
    end

    local cache = Internal.InventoryEntryStaticCache or {}
    if cache[key] then
        return cache[key]
    end

    local isMedicalProvision = Internal.Config.IsMedicalProvisionFullType and Internal.Config.IsMedicalProvisionFullType(key) or false
    local staticData = {
        treatmentUnits = isMedicalProvision and (Internal.Config.GetMedicalProvisionUnits and Internal.Config.GetMedicalProvisionUnits(key) or 0) or 0,
        provisionType = isMedicalProvision and "medical" or "nutrition",
        unitWeight = getUnitWeight(key),
        texture = Internal.getTextureForFullType and Internal.getTextureForFullType(key) or nil,
        isMedicalProvision = isMedicalProvision,
    }

    cache[key] = staticData
    Internal.InventoryEntryStaticCache = cache
    return staticData
end

function Internal.ensurePlayerEntryEquipmentData(entry)
    if not entry or entry.kind ~= "player" or entry.equipmentDataReady == true then
        return entry
    end

    local fullType = tostring(entry.fullType or "")
    local matchingEquipmentRequirements = Internal.Config.GetMatchingEquipmentRequirementDefinitions
        and Internal.Config.GetMatchingEquipmentRequirementDefinitions(fullType)
        or {}
    local tags = Internal.Config.GetItemCombinedTags and Internal.Config.GetItemCombinedTags(fullType)
        or (Internal.Config.FindItemTags and Internal.Config.FindItemTags(fullType))
        or {}
    local searchTerms = {}
    for _, definition in ipairs(matchingEquipmentRequirements) do
        searchTerms[#searchTerms + 1] = tostring(definition.label or definition.requirementKey or "")
        searchTerms[#searchTerms + 1] = tostring(definition.searchText or "")
    end

    entry.canAssignTool = #matchingEquipmentRequirements > 0
    entry.equipmentRequirementKeys = matchingEquipmentRequirements
    entry.tags = tags
    entry.searchText = table.concat(searchTerms, " ")
    entry.equipmentDataReady = true
    return entry
end

function Internal.getCachedNutritionPreview(invItem)
    if not invItem then
        return 0, 0
    end

    local hasDynamicFluid = invItem.getFluidContainer and invItem:getFluidContainer() ~= nil
    local fullType = invItem.getFullType and invItem:getFullType() or nil
    local cache = Internal.NutritionPreviewCache

    if not hasDynamicFluid and fullType and cache[fullType] then
        local cached = cache[fullType]
        return cached.calories or 0, cached.hydration or 0
    end

    local calories, hydration = Internal.Nutrition.GetItemNutrition(invItem)
    calories = math.max(0, tonumber(calories) or 0)
    hydration = math.max(0, tonumber(hydration) or 0)

    if not hasDynamicFluid and fullType then
        cache[fullType] = {
            calories = calories,
            hydration = hydration
        }
    end

    return calories, hydration
end

function Internal.buildInventoryEntry(invItem)
    local calories, hydration = Internal.getCachedNutritionPreview(invItem)
    local fullType = invItem:getFullType()
    local staticData = Internal.getCachedInventoryEntryStaticData(fullType)
    return {
        kind = "player",
        invItem = invItem,
        itemID = invItem:getID(),
        displayName = invItem:getDisplayName(),
        fullType = fullType,
        provisionType = staticData.provisionType,
        treatmentUnits = staticData.treatmentUnits,
        calories = calories,
        hydration = hydration,
        unitWeight = staticData.unitWeight,
        totalWeight = staticData.unitWeight,
        canDeposit = staticData.isMedicalProvision or calories > 0 or hydration > 0,
        canAssignTool = false,
        equipmentRequirementKeys = nil,
        tags = nil,
        searchText = "",
        equipmentDataReady = false,
        texture = staticData.texture or (invItem.getTex and invItem:getTex() or nil),
    }
end

function Internal.buildPlayerMoneyEntry(player)
    local wealth = Internal.getPlayerWealth and Internal.getPlayerWealth(player) or 0
    return {
        kind = "money",
        itemID = "player_money",
        displayName = "Cash On Hand",
        fullType = "Base.Money",
        amount = wealth,
        canDeposit = wealth > 0,
        texture = Internal.getTextureForFullType("Base.MoneyBundle") or Internal.getTextureForFullType("Base.Money"),
    }
end

function Internal.buildWorkerSupplyEntry(entry, index)
    if not entry then
        return nil
    end

    local qty = math.max(1, tonumber(entry.qty) or 1)
    local caloriesPerItem = math.max(0, tonumber(entry.caloriesRemaining) or 0)
    local hydrationPerItem = math.max(0, tonumber(entry.hydrationRemaining) or 0)
    local treatmentPerItem = math.max(0, tonumber(entry.treatmentUnitsRemaining) or 0)

    return {
        kind = "worker",
        itemID = entry.itemID,
        ledgerIndex = index,
        displayName = entry.displayName,
        fullType = entry.fullType,
        provisionType = entry.provisionType or ((Internal.Config.IsMedicalProvisionEntry and Internal.Config.IsMedicalProvisionEntry(entry)) and "medical" or "nutrition"),
        treatmentUnits = treatmentPerItem,
        medicalUse = entry.medicalUse,
        calories = caloriesPerItem,
        hydration = hydrationPerItem,
        totalCalories = caloriesPerItem * qty,
        totalHydration = hydrationPerItem * qty,
        totalTreatmentUnits = treatmentPerItem * qty,
        qty = qty,
        unitWeight = getUnitWeight(entry.fullType),
        totalWeight = getTotalWeight(entry.fullType, qty),
        texture = entry.texture or Internal.getTextureForFullType(entry.fullType),
        pending = entry.pending == true,
    }
end

function Internal.buildWorkerMoneyEntry(worker)
    return {
        kind = "money",
        ledgerIndex = "worker_money",
        displayName = "Stored Cash",
        fullType = "Base.Money",
        amount = math.max(0, math.floor(tonumber(worker and worker.moneyStored) or 0)),
        texture = Internal.getTextureForFullType("Base.MoneyBundle") or Internal.getTextureForFullType("Base.Money"),
    }
end

function Internal.buildWorkerToolEntry(entry, index)
    if not entry then
        return nil
    end

    local qty = math.max(1, tonumber(entry.qty) or 1)
    local tags = entry.tags or {}
    if Internal.Config.GetItemCombinedTags and entry.fullType then
        tags = Internal.Config.GetItemCombinedTags(entry.fullType)
    end

    return {
        kind = "tool",
        ledgerIndex = index,
        displayName = entry.displayName,
        fullType = entry.fullType,
        tags = tags,
        qty = qty,
        unitWeight = getUnitWeight(entry.fullType),
        totalWeight = getTotalWeight(entry.fullType, qty),
        texture = entry.texture or Internal.getTextureForFullType(entry.fullType),
        pending = entry.pending == true,
    }
end

function Internal.buildWorkerToolPlaceholderEntry(definition)
    if not definition then
        return nil
    end

    return {
        kind = "placeholder",
        ledgerIndex = definition.ledgerIndex,
        displayName = definition.displayName or "Required Tool",
        fullType = definition.fullType or "DT.RequiredTool",
        tags = definition.requirementTags or {},
        hintText = definition.hintText,
        reasonText = definition.reasonText,
        searchText = definition.searchText,
        requirementKey = definition.requirementKey,
        requirementTags = definition.requirementTags or {},
        supportedFullTypes = definition.supportedFullTypes or {},
        texture = definition.texture or Internal.getTextureForFullType(definition.iconFullType),
    }
end

function Internal.buildWorkerOutputEntry(entry, index)
    if not entry then
        return nil
    end

    return {
        kind = "output",
        ledgerIndex = index,
        displayName = Internal.getDisplayNameForFullType(entry.fullType),
        fullType = entry.fullType,
        qty = math.max(1, tonumber(entry.qty) or 1),
        unitWeight = getUnitWeight(entry.fullType),
        totalWeight = getTotalWeight(entry.fullType, entry.qty),
        texture = entry.texture or Internal.getTextureForFullType(entry.fullType),
    }
end

function Internal.buildWorkerEntryFromPlayerEntry(entry)
    if not entry then
        return nil
    end

    return {
        kind = "worker",
        itemID = entry.itemID,
        displayName = entry.displayName,
        fullType = entry.fullType,
        provisionType = entry.provisionType or "nutrition",
        treatmentUnits = math.max(0, tonumber(entry.treatmentUnits) or 0),
        calories = math.max(0, tonumber(entry.calories) or 0),
        hydration = math.max(0, tonumber(entry.hydration) or 0),
        unitWeight = tonumber(entry.unitWeight) or getUnitWeight(entry.fullType),
        totalWeight = tonumber(entry.totalWeight) or getTotalWeight(entry.fullType, 1),
        texture = entry.texture,
        pending = true,
    }
end

function Internal.buildWorkerToolEntryFromPlayerEntry(entry)
    if not entry then
        return nil
    end

    return {
        kind = "tool",
        displayName = entry.displayName,
        fullType = entry.fullType,
        tags = entry.tags or {},
        unitWeight = tonumber(entry.unitWeight) or getUnitWeight(entry.fullType),
        totalWeight = tonumber(entry.totalWeight) or getTotalWeight(entry.fullType, 1),
        texture = entry.texture,
        pending = true,
    }
end
