DC_EquipmentPickerModal = DC_EquipmentPickerModal or {}
DC_EquipmentPickerModal.Internal = DC_EquipmentPickerModal.Internal or {}

local Internal = DC_EquipmentPickerModal.Internal
local FlavorText = Internal.FlavorText or {}

Internal.SourceOptions = {
    { label = tostring(FlavorText.allSourcesLabel or "All Sources"), filterID = "all" },
    { label = tostring(FlavorText.playerInventoryLabel or "Player Inventory"), filterID = "player" },
    { label = tostring(FlavorText.warehouseStorageLabel or "Warehouse Storage"), filterID = "warehouse" }
}

function Internal.FindSourceOptionIndex(filterID)
    local target = tostring(filterID or "all")
    for index, option in ipairs(Internal.SourceOptions) do
        if tostring(option.filterID or "") == target then
            return index
        end
    end
    return 1
end

function Internal.GetSourceFilterIDByIndex(index)
    local option = Internal.SourceOptions[math.max(1, math.floor(tonumber(index) or 1))] or Internal.SourceOptions[1]
    return tostring(option and option.filterID or "all")
end

return Internal.SourceOptions