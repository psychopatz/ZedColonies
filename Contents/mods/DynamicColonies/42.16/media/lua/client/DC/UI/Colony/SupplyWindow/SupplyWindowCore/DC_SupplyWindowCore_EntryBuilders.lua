DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

local function getUnitWeight(fullType)
    return math.max(0, tonumber(Internal.Config and Internal.Config.GetItemWeight and Internal.Config.GetItemWeight(fullType)) or 0)
end

local function getTotalWeight(fullType, qty)
    return getUnitWeight(fullType) * math.max(1, tonumber(qty) or 1)
end

local function getRegistryInternal()
    return DC_Colony and DC_Colony.Registry and DC_Colony.Registry.Internal or nil
end

local function copyEquipmentState(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return target
    end

    target.condition = source.condition
    target.conditionMax = source.conditionMax
    target.isDrainable = source.isDrainable == true
    target.useDelta = source.useDelta
    target.usedDelta = source.usedDelta
    target.keepOnDeplete = source.keepOnDeplete == true
    return target
end

local function copyOutputState(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return target
    end

    target.fluidAmount = source.fluidAmount
    target.isRottenProvision = source.isRottenProvision == true or source.isRotten == true
    target.provisionBlockedReason = source.provisionBlockedReason
    return target
end

local function isInventoryItemRotten(invItem)
    if not invItem or not invItem.isRotten then
        return false
    end

    local ok, result = pcall(function()
        return invItem:isRotten()
    end)
    return ok and result == true
end

local function getNormalizedEquipmentEntry(entry)
    local registryInternal = getRegistryInternal()
    if not registryInternal or not registryInternal.NormalizeEquipmentEntry then
        return nil
    end
    return registryInternal.NormalizeEquipmentEntry(entry)
end

local function getInventoryEquipmentEntry(invItem)
    local registryInternal = getRegistryInternal()
    if not registryInternal or not registryInternal.BuildEquipmentEntryFromInventoryItem then
        return nil
    end
    return registryInternal.BuildEquipmentEntryFromInventoryItem(invItem)
end

local function isUsableEquipmentEntry(entry)
    local registryInternal = getRegistryInternal()
    if not registryInternal or not registryInternal.IsEquipmentEntryUsable then
        return false
    end
    return registryInternal.IsEquipmentEntryUsable(entry)
end

local function getNormalizedOutputEntry(entry)
    local registryInternal = getRegistryInternal()
    if not registryInternal or not registryInternal.NormalizeOutputEntry then
        return nil
    end
    return registryInternal.NormalizeOutputEntry(entry)
end

local function getInventoryOutputEntry(invItem)
    local registryInternal = getRegistryInternal()
    if not registryInternal or not registryInternal.BuildOutputEntryFromInventoryItem then
        return nil
    end
    return registryInternal.BuildOutputEntryFromInventoryItem(invItem)
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
        texture = Internal.peekTextureForFullType and Internal.peekTextureForFullType(key) or nil,
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

    if Internal.hydrateInventoryEntryForEquipment then
        Internal.hydrateInventoryEntryForEquipment(entry, entry.invItem)
    end

    Internal.applyDynamicTradingLockState(entry)

    local fullType = tostring(entry.fullType or "")
    local matchingEquipmentRequirements = Internal.getWorkerRequirementMatches
        and Internal.getWorkerRequirementMatches(fullType, nil)
        or (Internal.Config.GetMatchingEquipmentRequirementDefinitions
            and Internal.Config.GetMatchingEquipmentRequirementDefinitions(fullType))
        or {}
    local tags = Internal.Config.GetItemCombinedTags and Internal.Config.GetItemCombinedTags(fullType)
        or (Internal.Config.FindItemTags and Internal.Config.FindItemTags(fullType))
        or {}
    local searchTerms = {}
    for _, definition in ipairs(matchingEquipmentRequirements) do
        searchTerms[#searchTerms + 1] = tostring(definition.label or definition.requirementKey or "")
        searchTerms[#searchTerms + 1] = tostring(definition.searchText or "")
    end

    entry.hasEquipmentRequirementMatch = #matchingEquipmentRequirements > 0
    entry.canAssignTool = entry.hasEquipmentRequirementMatch
        and entry.isUsableEquipment == true
        and entry.isDynamicTradingLocked ~= true
    entry.equipmentRequirementKeys = matchingEquipmentRequirements
    entry.tags = tags
    entry.searchText = table.concat(searchTerms, " ")
    entry.equipmentDataReady = true
    return entry
end

function Internal.getPlayerEntryEquipmentMatches(entry, worker)
    if not entry or entry.kind ~= "player" then
        return {}
    end

    Internal.ensurePlayerEntryEquipmentData(entry)

    local config = Internal.Config or {}
    local normalizeJobType = config.NormalizeJobType
    local normalizedJob = normalizeJobType and normalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
    local cacheKey = normalizedJob ~= "" and normalizedJob or "__all"
    if config.GetWorkerEquipmentRequirementDefinitions and worker then
        local requirementKeys = {}
        for _, definition in ipairs(config.GetWorkerEquipmentRequirementDefinitions(worker) or {}) do
            requirementKeys[#requirementKeys + 1] = tostring(definition and definition.requirementKey or "")
        end
        table.sort(requirementKeys)
        cacheKey = cacheKey .. "|" .. table.concat(requirementKeys, ",")
    elseif worker and worker.workerID then
        cacheKey = cacheKey .. "|" .. tostring(worker.workerID)
    end

    entry.jobEquipmentMatches = entry.jobEquipmentMatches or {}
    if entry.jobEquipmentMatches[cacheKey] ~= nil then
        return entry.jobEquipmentMatches[cacheKey]
    end

    local matches = config.GetMatchingEquipmentRequirementDefinitionsForWorker
        and config.GetMatchingEquipmentRequirementDefinitionsForWorker(entry.fullType, worker)
        or (config.GetMatchingEquipmentRequirementDefinitions
            and config.GetMatchingEquipmentRequirementDefinitions(entry.fullType, normalizedJob ~= "__all" and normalizedJob or nil))
        or {}
    entry.jobEquipmentMatches[cacheKey] = matches
    return matches
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

local function buildBaseInventoryEntry(invItem)
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
        calories = 0,
        hydration = 0,
        unitWeight = staticData.unitWeight,
        totalWeight = staticData.unitWeight,
        canDeposit = staticData.isMedicalProvision == true,
        canAssignTool = false,
        hasEquipmentRequirementMatch = false,
        isUsableEquipment = false,
        isRottenProvision = false,
        provisionBlockedReason = nil,
        equipmentRequirementKeys = nil,
        tags = nil,
        searchText = "",
        equipmentDataReady = false,
        equipmentHydrated = false,
        outputHydrated = false,
        provisionHydrated = false,
        texture = staticData.texture or (invItem.getTex and invItem:getTex() or nil),
    }
end

local function buildProvisionDescriptor(invItem)
    if not invItem then
        return nil
    end

    local fullType = invItem:getFullType()
    local staticData = Internal.getCachedInventoryEntryStaticData(fullType)
    local rottenProvisionReason = Internal.Nutrition
        and Internal.Nutrition.Internal
        and tostring(Internal.Nutrition.Internal.ROTTEN_PROVISION_MESSAGE or "")
        or "Rotten items cannot be used as colony provisions."
    local isRottenProvision = not staticData.isMedicalProvision and isInventoryItemRotten(invItem)
    local calories = 0
    local hydration = 0

    if not isRottenProvision then
        calories, hydration = Internal.getCachedNutritionPreview(invItem)
        isRottenProvision = not staticData.isMedicalProvision
            and Internal.Nutrition
            and Internal.Nutrition.IsRottenProvisionItem
            and Internal.Nutrition.IsRottenProvisionItem(invItem, calories, hydration)
        if isRottenProvision then
            calories = 0
            hydration = 0
        end
    end

    local canDeposit = staticData.isMedicalProvision or ((calories > 0 or hydration > 0) and not isRottenProvision)
    return {
        kind = "player",
        displayName = invItem:getDisplayName(),
        fullType = fullType,
        provisionType = staticData.provisionType,
        treatmentUnits = staticData.treatmentUnits,
        calories = calories,
        hydration = hydration,
        unitWeight = staticData.unitWeight,
        totalWeight = staticData.unitWeight,
        qty = 1,
        canDeposit = canDeposit,
        canAssignTool = false,
        hasEquipmentRequirementMatch = false,
        isUsableEquipment = false,
        isRottenProvision = isRottenProvision == true,
        provisionBlockedReason = isRottenProvision and rottenProvisionReason or nil,
        texture = nil,
    }
end

local function copyProvisionDescriptor(target, descriptor)
    if type(target) ~= "table" or type(descriptor) ~= "table" then
        return target
    end

    target.displayName = descriptor.displayName
    target.fullType = descriptor.fullType
    target.provisionType = descriptor.provisionType
    target.treatmentUnits = descriptor.treatmentUnits
    target.calories = descriptor.calories
    target.hydration = descriptor.hydration
    target.unitWeight = descriptor.unitWeight
    target.totalWeight = descriptor.totalWeight
    target.qty = descriptor.qty
    target.canDeposit = descriptor.canDeposit == true
    target.isRottenProvision = descriptor.isRottenProvision == true
    target.provisionBlockedReason = descriptor.provisionBlockedReason
    target.texture = descriptor.texture or target.texture
    return target
end

function Internal.buildProvisionDescriptor(invItem)
    return buildProvisionDescriptor(invItem)
end

function Internal.buildProvisionEntryFromDescriptor(invItem, descriptor)
    if not invItem or type(descriptor) ~= "table" then
        return nil
    end

    local entry = buildBaseInventoryEntry(invItem)
    copyProvisionDescriptor(entry, descriptor)
    entry.texture = nil
    entry.provisionHydrated = true
    return entry
end

function Internal.hydrateInventoryEntryForProvisions(entry, invItem)
    if not entry or entry.provisionHydrated == true then
        return entry
    end

    local targetItem = invItem or entry.invItem
    if not targetItem then
        entry.provisionHydrated = true
        return entry
    end

    local descriptor = buildProvisionDescriptor(targetItem)
    if descriptor then
        copyProvisionDescriptor(entry, descriptor)
    end
    entry.provisionHydrated = true
    return entry
end

function Internal.hydrateInventoryEntryForEquipment(entry, invItem)
    if not entry or entry.equipmentHydrated == true then
        return entry
    end

    local targetItem = invItem or entry.invItem
    local equipmentEntry = targetItem and getInventoryEquipmentEntry(targetItem) or nil
    entry.isUsableEquipment = isUsableEquipmentEntry(equipmentEntry)
    copyEquipmentState(entry, equipmentEntry)
    entry.equipmentHydrated = true
    return entry
end

function Internal.hydrateInventoryEntryForOutput(entry, invItem)
    if not entry or entry.outputHydrated == true then
        return entry
    end

    local targetItem = invItem or entry.invItem
    local outputEntry = targetItem and getInventoryOutputEntry(targetItem) or nil
    copyOutputState(entry, outputEntry)
    entry.outputHydrated = true
    return entry
end

function Internal.buildInventoryEntry(invItem)
    local entry = buildBaseInventoryEntry(invItem)
    Internal.hydrateInventoryEntryForProvisions(entry, invItem)
    Internal.hydrateInventoryEntryForEquipment(entry, invItem)
    Internal.hydrateInventoryEntryForOutput(entry, invItem)
    return entry
end

function Internal.buildInventoryEntryForTab(invItem, tabKey, window)
    if not invItem then
        return nil
    end

    local entry = buildBaseInventoryEntry(invItem)
    if tabKey == Internal.Tabs.Equipment then
        Internal.hydrateInventoryEntryForEquipment(entry, invItem)
        Internal.ensurePlayerEntryEquipmentData(entry)
        return entry.hasEquipmentRequirementMatch == true and entry or nil
    end

    if tabKey == Internal.Tabs.Output then
        if not (Internal.isWarehouseView and Internal.isWarehouseView(window)) then
            return nil
        end
        Internal.hydrateInventoryEntryForOutput(entry, invItem)
        return Internal.canStoreInWarehouseOutput and Internal.canStoreInWarehouseOutput(entry) and entry or nil
    end

    local descriptor = buildProvisionDescriptor(invItem)
    if descriptor and (descriptor.canDeposit == true or tostring(descriptor.provisionBlockedReason or "") ~= "") then
        return Internal.buildProvisionEntryFromDescriptor(invItem, descriptor)
    end
    return nil
end

function Internal.buildPlayerMoneyEntry(player, window)
    local wealth = nil
    if window then
        local looseCount = math.max(0, tonumber(window.cachedLooseMoneyCount) or 0)
        local bundleCount = math.max(0, tonumber(window.cachedMoneyBundleCount) or 0)
        wealth = looseCount + (bundleCount * 100)
    end
    if wealth == nil then
        wealth = Internal.getPlayerWealth and Internal.getPlayerWealth(player) or 0
    end
    return {
        kind = "money",
        itemID = "player_money",
        displayName = "Cash On Hand",
        fullType = "Base.Money",
        amount = wealth,
        canDeposit = wealth > 0,
        texture = nil,
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
        texture = entry.texture or (Internal.peekTextureForFullType and Internal.peekTextureForFullType(entry.fullType) or nil),
        entryID = entry.entryID,
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
        texture = nil,
    }
end

function Internal.buildWorkerToolEntry(entry, index)
    if not entry then
        return nil
    end

    local normalizedEntry = getNormalizedEquipmentEntry(entry) or entry
    local tags = normalizedEntry.tags or {}
    local toolEntry = {
        kind = "tool",
        ledgerIndex = index,
        displayName = normalizedEntry.displayName,
        fullType = normalizedEntry.fullType,
        tags = tags,
        qty = math.max(1, tonumber(normalizedEntry.qty) or 1),
        unitWeight = getUnitWeight(normalizedEntry.fullType),
        totalWeight = getTotalWeight(normalizedEntry.fullType, normalizedEntry.qty),
        texture = entry.texture or normalizedEntry.texture or (Internal.peekTextureForFullType and Internal.peekTextureForFullType(normalizedEntry.fullType) or nil),
        pending = entry.pending == true,
        isUsableEquipment = isUsableEquipmentEntry(normalizedEntry),
        assignedRequirementKey = normalizedEntry.assignedRequirementKey,
        entryID = normalizedEntry.entryID or entry.entryID,
    }
    return copyEquipmentState(toolEntry, normalizedEntry)
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
        texture = definition.texture or (Internal.peekTextureForFullType and Internal.peekTextureForFullType(definition.iconFullType) or nil),
        iconFullType = definition.iconFullType,
    }
end

function Internal.buildWorkerOutputEntry(entry, index)
    if not entry then
        return nil
    end

    local normalizedEntry = getNormalizedOutputEntry(entry) or entry
    local outputEntry = copyOutputState({
        kind = "output",
        ledgerIndex = index,
        displayName = normalizedEntry.displayName or Internal.getDisplayNameForFullType(normalizedEntry.fullType),
        fullType = normalizedEntry.fullType,
        qty = math.max(1, tonumber(normalizedEntry.qty) or 1),
        unitWeight = getUnitWeight(normalizedEntry.fullType),
        totalWeight = getTotalWeight(normalizedEntry.fullType, normalizedEntry.qty),
        texture = entry.texture or normalizedEntry.texture or (Internal.peekTextureForFullType and Internal.peekTextureForFullType(normalizedEntry.fullType) or nil),
        pending = entry.pending == true,
        entryID = normalizedEntry.entryID or entry.entryID,
    }, normalizedEntry)
    return copyEquipmentState(outputEntry, normalizedEntry)
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

    local workerEntry = {
        kind = "tool",
        displayName = entry.displayName,
        fullType = entry.fullType,
        tags = entry.tags or {},
        unitWeight = tonumber(entry.unitWeight) or getUnitWeight(entry.fullType),
        totalWeight = tonumber(entry.totalWeight) or getTotalWeight(entry.fullType, 1),
        texture = entry.texture,
        pending = true,
        isUsableEquipment = entry.isUsableEquipment == true,
        assignedRequirementKey = entry.assignedRequirementKey,
    }
    return copyEquipmentState(workerEntry, entry)
end
