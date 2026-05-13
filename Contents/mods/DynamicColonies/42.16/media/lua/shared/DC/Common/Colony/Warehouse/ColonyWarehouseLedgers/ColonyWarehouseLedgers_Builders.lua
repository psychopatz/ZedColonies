DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Nutrition = DC_Colony.Nutrition
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Ledgers = Internal.Ledgers or {}

Internal.Ledgers = Ledgers

function Ledgers.BuildProvisionEntryFromFullType(fullType)
    if Nutrition and Nutrition.BuildEntryFromItem and Nutrition.Internal and Nutrition.Internal.CreateItemByFullType then
        local createdItem = Nutrition.Internal.CreateItemByFullType(fullType)
        local entry = createdItem and Nutrition.BuildEntryFromItem(createdItem) or nil
        if entry then
            return entry
        end
    end

    if Config.IsMedicalProvisionFullType and Config.IsMedicalProvisionFullType(fullType) then
        return {
            fullType = fullType,
            displayName = Registry.Internal.GetDisplayNameForFullType(fullType),
            provisionType = "medical",
            medicalUse = "bandage",
            treatmentUnitsRemaining = Config.GetMedicalProvisionUnits and Config.GetMedicalProvisionUnits(fullType) or 0
        }
    end

    local calories, hydration = 0, 0
    local nutritionInternal = Nutrition and Nutrition.Internal or nil
    if nutritionInternal and nutritionInternal.GetExpectedStaticNutritionForFullType then
        calories, hydration = nutritionInternal.GetExpectedStaticNutritionForFullType(fullType)
    end

    calories = math.max(0, tonumber(calories) or 0)
    hydration = math.max(0, tonumber(hydration) or 0)
    if calories <= 0 and hydration <= 0 then
        return nil
    end

    return {
        fullType = fullType,
        displayName = Registry.Internal.GetDisplayNameForFullType(fullType),
        provisionType = "nutrition",
        caloriesRemaining = calories,
        hydrationRemaining = hydration
    }
end

function Ledgers.BuildEquipmentEntryFromFullType(fullType)
    if not fullType then
        return nil
    end

    return Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry({
        fullType = fullType,
        displayName = Registry.Internal.GetDisplayNameForFullType(fullType),
        tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(fullType)) or {}
    }) or nil
end

return Warehouse