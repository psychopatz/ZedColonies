require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"
require "RadioCom/ISUIRadio/ISSliderPanel"

DC_ColonyQuantityModal = ISCollapsableWindow:derive("DC_ColonyQuantityModal")
DC_ColonyQuantityModal.instance = nil

local function clampQuantity(value, maxValue)
    local quantity = math.floor(tonumber(value) or 0)
    if quantity < 1 then
        quantity = 1
    end
    if maxValue and quantity > maxValue then
        quantity = maxValue
    end
    return quantity
end

function DC_ColonyQuantityModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_ColonyQuantityModal:syncQuantityUI(quantity, syncSlider)
    local clamped = clampQuantity(quantity, self.maxValue or 1)

    if self.quantityEntry then
        local textValue = tostring(clamped)
        if self.quantityEntry:getText() ~= textValue then
            self.quantityEntry:setText(textValue)
        end
        self.lastQuantityText = textValue
    end

    if self.selectedLabel then
        self.selectedLabel:setName("Selected: " .. tostring(clamped))
    end

    if syncSlider and self.quantitySlider then
        self.quantitySlider:setCurrentValue(clamped, true)
    end
end

function DC_ColonyQuantityModal:onSliderChange(value, slider)
    self:syncQuantityUI(value, false)
end

function DC_ColonyQuantityModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 10
    local th = self:titleBarHeight()
    local contentY = th + pad
    local contentWidth = self.width - (pad * 2)

    self.promptLabel = ISLabel:new(pad, contentY, 20, tostring(self.promptText or "Enter a quantity."), 1, 1, 1, 1, UIFont.Small, true)
    self.promptLabel:initialise()
    self.promptLabel:instantiate()
    self:addChild(self.promptLabel)

    self.quantitySlider = ISSliderPanel:new(pad, contentY + 28, contentWidth, 18, self, self.onSliderChange)
    self.quantitySlider:initialise()
    self.quantitySlider:instantiate()
    self.quantitySlider:setValues(1, math.max(2, self.maxValue or 1), 1, math.max(1, math.floor((self.maxValue or 1) / 10)), true)
    self.quantitySlider:setCurrentValue(self.defaultValue or 1, true)
    self.quantitySlider.disabled = (self.maxValue or 1) <= 1
    self:addChild(self.quantitySlider)

    self.quantityEntry = ISTextEntryBox:new(tostring(self.defaultValue or 1), pad, contentY + 54, contentWidth, 24)
    self.quantityEntry:initialise()
    self.quantityEntry:instantiate()
    self.quantityEntry:setOnlyNumbers(true)
    self:addChild(self.quantityEntry)

    self.selectedLabel = ISLabel:new(
        pad,
        contentY + 84,
        20,
        "Selected: " .. tostring(self.defaultValue or 1),
        1,
        1,
        1,
        1,
        UIFont.Small,
        true
    )
    self.selectedLabel:initialise()
    self.selectedLabel:instantiate()
    self:addChild(self.selectedLabel)

    self.maxLabel = ISLabel:new(
        pad,
        contentY + 104,
        20,
        "Available: " .. tostring(self.maxValue or 1),
        0.75,
        0.75,
        0.75,
        1,
        UIFont.Small,
        true
    )
    self.maxLabel:initialise()
    self.maxLabel:instantiate()
    self:addChild(self.maxLabel)

    self.btnConfirm = ISButton:new(pad, self.height - 38, 100, 24, "Confirm", self, self.onConfirm)
    self.btnConfirm:initialise()
    self.btnConfirm:instantiate()
    self:addChild(self.btnConfirm)

    self.btnCancel = ISButton:new(self.width - 110, self.height - 38, 100, 24, "Cancel", self, self.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self:addChild(self.btnCancel)
end

function DC_ColonyQuantityModal:update()
    ISCollapsableWindow.update(self)

    local currentText = self.quantityEntry and self.quantityEntry:getText() or ""
    if currentText ~= (self.lastQuantityText or "") then
        self:syncQuantityUI(currentText, true)
    end
end

function DC_ColonyQuantityModal:onConfirm()
    local quantity = clampQuantity(self.quantityEntry and self.quantityEntry:getText() or 1, self.maxValue or 1)
    if self.onConfirmCallback then
        self.onConfirmCallback(quantity)
    end
    self:close()
end

function DC_ColonyQuantityModal:onCancel()
    self:close()
end

function DC_ColonyQuantityModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DC_ColonyQuantityModal.Open(args)
    args = args or {}

    local modal = DC_ColonyQuantityModal.instance
    if not modal then
        local width = 340
        local height = 190
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2
        modal = DC_ColonyQuantityModal:new(x, y, width, height)
        modal:initialise()
        modal:instantiate()
        DC_ColonyQuantityModal.instance = modal
    end

    modal.title = tostring(args.title or "Choose Quantity")
    modal.promptText = tostring(args.promptText or "Enter quantity.")
    modal.maxValue = math.max(1, math.floor(tonumber(args.maxValue) or 1))
    modal.defaultValue = clampQuantity(args.defaultValue or modal.maxValue, modal.maxValue)
    modal.onConfirmCallback = args.onConfirm

    if modal.promptLabel then
        modal.promptLabel:setName(modal.promptText)
    end
    if modal.quantitySlider then
        modal.quantitySlider:setValues(1, math.max(2, modal.maxValue), 1, math.max(1, math.floor(modal.maxValue / 10)), true)
        modal.quantitySlider.disabled = modal.maxValue <= 1
    end
    if modal.maxLabel then
        modal.maxLabel:setName("Available: " .. tostring(modal.maxValue))
    end
    modal:syncQuantityUI(modal.defaultValue, true)

    modal:setVisible(true)
    modal:addToUIManager()
    modal:bringToTop()
    if modal.quantityEntry and modal.quantityEntry.focus then
        modal.quantityEntry:focus()
    end

    return modal
end

function DC_ColonyQuantityModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Choose Quantity"
    o.resizable = false
    o.promptText = "Enter quantity."
    o.defaultValue = 1
    o.maxValue = 1
    o.onConfirmCallback = nil
    o.lastQuantityText = "1"
    return o
end

return DC_ColonyQuantityModal
