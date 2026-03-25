DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

Internal.Config = DC_Colony and DC_Colony.Config or Internal.Config or {}
Internal.Nutrition = DC_Colony and DC_Colony.Nutrition or Internal.Nutrition or {}
Internal.ENTRY_SCAN_BATCH_SIZE = 160
Internal.RAW_SCAN_STEP_LIMIT = 2400
Internal.LIST_BUILD_BATCH_SIZE = 180
Internal.NutritionPreviewCache = Internal.NutritionPreviewCache or {}
Internal.InventoryEntryStaticCache = Internal.InventoryEntryStaticCache or {}
Internal.TextureCache = Internal.TextureCache or {}
Internal.DETAIL_SUPPORT_PANEL_HEIGHT = 56
Internal.DETAIL_SUPPORT_ICON_SIZE = 24
Internal.GROUP_TOGGLE_HIT_WIDTH = 18
Internal.GROUP_CHILD_INDENT = 14
Internal.ViewModes = {
    Inventory = "inventory",
    Warehouse = "warehouse",
}
Internal.Tabs = {
    Provisions = "provisions",
    Output = "output",
    Equipment = "equipment",
}

function Internal.isWarehouseView(window)
    return window and window.viewMode == Internal.ViewModes.Warehouse
end

function Internal.isInventoryView(window)
    return not Internal.isWarehouseView(window)
end
