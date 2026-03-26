DC_Colony = DC_Colony or {}
DC_Colony.Nutrition = DC_Colony.Nutrition or {}
DC_Colony.Nutrition.Internal = DC_Colony.Nutrition.Internal or {}

local Config = DC_Colony.Config
local Nutrition = DC_Colony.Nutrition
local Internal = Nutrition.Internal
local Registry = DC_Colony.Registry

Internal.ROTTEN_PROVISION_MESSAGE = "That item is rotten and cannot be used as colony provisions."

local function resolveModuleDotType(moduleName, itemType)
    local normalizedType = tostring(itemType or "")
    if normalizedType == "" then
        return nil
    end
    if string.find(normalizedType, ".", 1, true) then
        return normalizedType
    end

    local normalizedModule = tostring(moduleName or "")
    if normalizedModule == "" then
        return normalizedType
    end
    return normalizedModule .. "." .. normalizedType
end

local function buildConsumedOutputMetadata(invItem, fullType, displayName, scriptItem)
    local replaceOnUse = invItem and invItem.getReplaceOnUse and invItem:getReplaceOnUse()
        or scriptItem and scriptItem.getReplaceOnUse and scriptItem:getReplaceOnUse()
        or nil
    if replaceOnUse and tostring(replaceOnUse) ~= "" then
        local moduleName = invItem and invItem.getModule and invItem:getModule()
            or invItem and invItem.getModuleName and invItem:getModuleName()
            or scriptItem and scriptItem.getModuleName and scriptItem:getModuleName()
            or scriptItem and scriptItem.getModule and scriptItem:getModule()
            or nil
        local replacementFullType = resolveModuleDotType(moduleName, replaceOnUse)
        if replacementFullType then
            return {
                consumedOutputFullType = replacementFullType,
                consumedOutputDisplayName = Registry and Registry.Internal and Registry.Internal.GetDisplayNameForFullType
                    and Registry.Internal.GetDisplayNameForFullType(replacementFullType)
                    or replacementFullType,
            }
        end
    end

    local probeItem = invItem or (Internal.CreateItemByFullType and Internal.CreateItemByFullType(fullType)) or nil
    local fluidContainer = probeItem and probeItem.getFluidContainer and probeItem:getFluidContainer() or nil
    if fluidContainer then
        return {
            consumedOutputFullType = tostring(fullType or ""),
            consumedOutputDisplayName = tostring(displayName or fullType or ""),
            consumedOutputFluidAmount = 0,
        }
    end

    return nil
end

local function applyConsumedOutputMetadata(entry, invItem, fullType, displayName)
    if type(entry) ~= "table" or tostring(entry.provisionType or "nutrition") == "medical" then
        return entry
    end

    if entry.consumedOutputFullType ~= nil then
        return entry
    end

    local resolvedFullType = tostring(fullType or entry.fullType or "")
    if resolvedFullType == "" then
        return entry
    end

    local scriptItem = Internal.GetScriptItem(invItem) or Internal.GetScriptItemByFullType(resolvedFullType)
    local metadata = buildConsumedOutputMetadata(invItem, resolvedFullType, displayName or entry.displayName, scriptItem)
    if not metadata then
        return entry
    end

    entry.consumedOutputFullType = metadata.consumedOutputFullType
    entry.consumedOutputDisplayName = metadata.consumedOutputDisplayName
    if metadata.consumedOutputFluidAmount ~= nil then
        entry.consumedOutputFluidAmount = metadata.consumedOutputFluidAmount
    end
    return entry
end

function Nutrition.IsRottenProvisionItem(invItem, calories, hydration)
    if not invItem or not invItem.isRotten or not invItem:isRotten() then
        return false
    end

    local fullType = invItem.getFullType and invItem:getFullType() or nil
    if Config.IsMedicalProvisionFullType and Config.IsMedicalProvisionFullType(fullType) then
        return false
    end

    local totalCalories = tonumber(calories)
    local totalHydration = tonumber(hydration)
    if totalCalories == nil and totalHydration == nil then
        totalCalories, totalHydration = Nutrition.GetItemNutrition(invItem)
    end

    if math.max(0, tonumber(totalCalories) or 0) > 0 or math.max(0, tonumber(totalHydration) or 0) > 0 then
        return true
    end

    return Config.IsFoodOrDrinkItem and Config.IsFoodOrDrinkItem(invItem) or false
end

function Internal.ApplyConsumedOutputMetadata(entry, invItem, fullType, displayName)
    return applyConsumedOutputMetadata(entry, invItem, fullType, displayName)
end

function Nutrition.GetItemNutrition(invItem)
    if not invItem then
        return 0, 0
    end

    local scriptItem = Internal.GetScriptItem(invItem)
    local instanceCalories = Internal.ClampAmount(Internal.ReadNumericValue(invItem, "getCalories"))
    local scriptCalories = Internal.ClampAmount(Internal.ReadNumericValue(scriptItem, "getCalories"))
    local instanceHungerCalories = Internal.NormalizeCaloriesFromHunger(Internal.ReadNumericValue(invItem, "getHungerChange"))
    local scriptHungerCalories = 0
    if scriptItem and DynamicTrading and DynamicTrading.Economy and DynamicTrading.Economy.Common then
        scriptHungerCalories = Internal.NormalizeCaloriesFromHunger(DynamicTrading.Economy.Common.GetNormalizedHunger(scriptItem))
    end

    local calories = Internal.ChooseStaticNutrition(instanceCalories, scriptCalories)
    if calories <= 0 then
        calories = Internal.ChooseStaticNutrition(instanceHungerCalories, scriptHungerCalories)
    end

    local dynamicFluidItem = Internal.IsWaterHydrationSource(invItem, scriptItem)
        and invItem.getFluidContainer
        and invItem:getFluidContainer()
    local instanceHydration = Internal.NormalizeHydrationPoints(Internal.ReadNumericValue(invItem, "getThirstChange"))
    local scriptHydration = Internal.NormalizeHydrationPoints(Internal.ReadNumericValue(scriptItem, "getThirstChange"))
    local hydration = 0

    if dynamicFluidItem then
        local fluidContainer = invItem:getFluidContainer()
        if fluidContainer and fluidContainer.getAmount then
            local amount = tonumber(fluidContainer:getAmount()) or 0
            if amount > 0 then
                hydration = amount > 10 and amount or (amount * 100)
            end
        end
    end

    if hydration <= 0 then
        hydration = Internal.ChooseStaticNutrition(instanceHydration, scriptHydration)
    end

    return calories, hydration
end

function Nutrition.BuildEntryFromItem(invItem)
    if not invItem then
        return nil, "Missing item."
    end

    local fullType = invItem:getFullType()
    if DC_Colony
        and DC_Colony.Config
        and DC_Colony.Config.IsMedicalProvisionFullType
        and DC_Colony.Config.IsMedicalProvisionFullType(fullType) then
        return {
            fullType = fullType,
            displayName = invItem.getDisplayName and invItem:getDisplayName() or fullType,
            itemID = invItem.getID and invItem:getID() or nil,
            provisionType = "medical",
            medicalUse = "bandage",
            treatmentUnitsRemaining = DC_Colony.Config.GetMedicalProvisionUnits(fullType)
        }
    end

    local calories, hydration = Nutrition.GetItemNutrition(invItem)
    if Nutrition.IsRottenProvisionItem(invItem, calories, hydration) then
        return nil, Internal.ROTTEN_PROVISION_MESSAGE
    end
    if calories <= 0 and hydration <= 0 then
        return nil, "Item does not provide calories or hydration."
    end

    return applyConsumedOutputMetadata({
        fullType = fullType,
        displayName = invItem.getDisplayName and invItem:getDisplayName() or fullType,
        itemID = invItem.getID and invItem:getID() or nil,
        provisionType = "nutrition",
        caloriesRemaining = calories,
        hydrationRemaining = hydration
    }, invItem, fullType, invItem.getDisplayName and invItem:getDisplayName() or fullType)
end

function Nutrition.BuildStarterReserveEntry(calories, hydration)
    return {
        fullType = "DT.ColonyStarterReserve",
        displayName = "Starter Reserve",
        provisionType = "nutrition",
        caloriesRemaining = math.max(0, tonumber(calories) or 0),
        hydrationRemaining = math.max(0, tonumber(hydration) or 0)
    }
end

return Nutrition
