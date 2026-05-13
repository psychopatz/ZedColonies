DC_EquipmentPickerModal = DC_EquipmentPickerModal or {}
DC_EquipmentPickerModal.Internal = DC_EquipmentPickerModal.Internal or {}

local FlavorText = DC_EquipmentPickerModal.Internal.FlavorText or {}

function DC_EquipmentPickerModal.Preload()
    local modal = DC_EquipmentPickerModal.instance
    if modal then
        return modal
    end

    local width = 640
    local height = 520
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    modal = DC_EquipmentPickerModal:new(x, y, width, height)
    modal:initialise()
    modal:instantiate()
    modal:setVisible(false)
    DC_EquipmentPickerModal.instance = modal
    return modal
end

function DC_EquipmentPickerModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = tostring(FlavorText.windowTitle or "Choose Equipment")
    o.resizable = false
    o.promptText = tostring(FlavorText.promptText or "Choose an equipment source.")
    o.confirmLabel = tostring(FlavorText.confirmTitle or "Confirm")
    o.candidates = {}
    o.sourceFilter = "all"
    o.onConfirmCallback = nil
    return o
end

function DC_EquipmentPickerModal.Open(args)
    local modal = DC_EquipmentPickerModal.Preload()
    modal:applyArgs(args)
    modal:setVisible(true)
    modal:addToUIManager()
    modal:bringToTop()
    return modal
end

return DC_EquipmentPickerModal