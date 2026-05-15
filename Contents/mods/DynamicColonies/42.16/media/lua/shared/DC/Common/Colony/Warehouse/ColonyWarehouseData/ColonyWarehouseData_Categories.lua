DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Config = DC_Colony.Config
local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal
local Data = Internal.Data or {}

Internal.Data = Data

local function getAbstractInventory()
    return DC_Colony and DC_Colony.AbstractInventory or nil
end

function Data.ShouldStoreAsLiteralSpecial(entry)
    if type(entry) ~= "table" then
        return false
    end

    if entry.literalSpecial == true then
        return true
    end

    local fullType = tostring(entry.fullType or "")
    if fullType == "" then
        return false
    end

    local converted = Config.GetItemCategoryData and Config.GetItemCategoryData(fullType) or nil
    local category = tostring(converted and converted.category or "")
    return category == "QuestGoods"
        or category == "ContaminatedMaterial"
end

function Warehouse.GetCategoryCount(ownerUsername, categoryId)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.GetCategoryCount and abstractInventory.GetCategoryCount(ownerUsername, categoryId) or 0
end

function Warehouse.GetCategoryStock(ownerUsername, categoryId)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.GetCategoryStock and abstractInventory.GetCategoryStock(ownerUsername, categoryId) or { count = 0, totalWeight = 0 }
end

function Warehouse.GetCategoryCounts(ownerUsername)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.GetCategoryCounts and abstractInventory.GetCategoryCounts(ownerUsername) or {}
end

function Warehouse.GetCategoryStockSnapshot(ownerUsername)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.GetCategoryStockSnapshot and abstractInventory.GetCategoryStockSnapshot(ownerUsername) or {}
end

function Warehouse.AddCategory(ownerUsername, categoryId, amount, sourceMeta)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.AddCategory and abstractInventory.AddCategory(ownerUsername, categoryId, amount, sourceMeta) or 0
end

function Warehouse.GetLiteralSpecialCount(ownerUsername, fullType)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.GetLiteralSpecialCount and abstractInventory.GetLiteralSpecialCount(ownerUsername, fullType) or 0
end

function Warehouse.GetLiteralSpecialStockSnapshot(ownerUsername)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.GetLiteralSpecialStockSnapshot and abstractInventory.GetLiteralSpecialStockSnapshot(ownerUsername) or {}
end

function Warehouse.AddLiteralSpecial(ownerUsername, entry)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.AddLiteralSpecial and abstractInventory.AddLiteralSpecial(ownerUsername, entry) or 0
end

function Warehouse.TakeLiteralSpecial(ownerUsername, requestedQty, filterFn, _reasonMeta)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.TakeLiteralSpecial and abstractInventory.TakeLiteralSpecial(ownerUsername, requestedQty, filterFn, _reasonMeta) or {}, 0
end

function Warehouse.CanConsumeCategories(ownerUsername, requirements)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.CanConsumeCategories and abstractInventory.CanConsumeCategories(ownerUsername, requirements) or false
end

function Warehouse.ConsumeCategories(ownerUsername, requirements, _reasonMeta)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.ConsumeCategories and abstractInventory.ConsumeCategories(ownerUsername, requirements, _reasonMeta) or false
end

function Warehouse.TakeCategoryUnits(ownerUsername, categoryId, amount, _reasonMeta)
    local abstractInventory = getAbstractInventory()
    return abstractInventory and abstractInventory.TakeCategoryUnits and abstractInventory.TakeCategoryUnits(ownerUsername, categoryId, amount, _reasonMeta) or 0
end

return Warehouse
