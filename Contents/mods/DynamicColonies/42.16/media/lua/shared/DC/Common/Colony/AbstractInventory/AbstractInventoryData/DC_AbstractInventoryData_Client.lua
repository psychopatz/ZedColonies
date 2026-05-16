DC_Colony = DC_Colony or {}
DC_Colony.AbstractInventory = DC_Colony.AbstractInventory or {}
DC_Colony.AbstractInventory.Internal = DC_Colony.AbstractInventory.Internal or {}

local AbstractInventory = DC_Colony.AbstractInventory
local Internal = AbstractInventory.Internal
local Data = Internal.Data or {}

Internal.Data = Data

function AbstractInventory.GetSnapshot(ownerUsername)
    local ownerData = Data.EnsureOwnerData(ownerUsername)
    if not ownerData then
        return nil
    end

    return {
        ownerUsername = tostring(ownerData.ownerUsername or ""),
        colonyID = tostring(ownerData.colonyID or ""),
        version = math.max(1, math.floor(tonumber(ownerData.version) or 1)),
        itemStock = Data.BuildItemStockSnapshot(ownerData.itemStock),
        itemCounts = Data.BuildItemCountSnapshot(ownerData.itemStock),
        categoryStock = Data.BuildCategoryStockSnapshot(ownerData.categoryStock),
        categoryCounts = Data.BuildCategoryCountSnapshot(ownerData.categoryStock),
        foodNutritionPools = Data.BuildFoodNutritionSnapshot(ownerData.foodNutritionPools),
        literalSpecialStock = Data.BuildLiteralSpecialSnapshot(ownerData.literalSpecialStock),
    }
end

return AbstractInventory
