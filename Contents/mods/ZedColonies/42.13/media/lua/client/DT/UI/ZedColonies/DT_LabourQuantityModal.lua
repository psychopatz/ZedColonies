require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"

DT_LabourQuantityModal = ISCollapsableWindow:derive("DT_LabourQuantityModal")
DT_LabourQuantityModal.instance = nil

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

function DT_LabourQuantityModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DT_LabourQuantityModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 10
    local th = self:titleBarHeight()
    local contentY = th + pad
    local contentWidth = self.width - (pad * 2)

    self.promptLabel = ISLabel:new(pad, contentY, 20, tostring(self.promptText or "Enter a quantity."), 1, 1, 1, 1, UIFont.Small, true)
    self.promptLabel:initialise()
    self.promptLabel:instantiate()
    self:addChild(self.promptLabel)

    self.quantityEntry = ISTextEntryBox:new(tostring(self.defaultValue or 1), pad, contentY + 28, contentWidth, 24)
    self.quantityEntry:initialise()
    self.quantityEntry:instantiate()
    self.quantityEntry:setOnlyNumbers(true)
    self:addChild(self.quantityEntry)

    self.maxLabel = ISLabel:new(
        pad,
        contentY + 60,
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

function DT_LabourQuantityModal:onConfirm()
    local quantity = clampQuantity(self.quantityEntry and self.quantityEntry:getText() or 1, self.maxValue or 1)
    if self.onConfirmCallback then
        self.onConfirmCallback(quantity)
    end
    self:close()
end

function DT_LabourQuantityModal:onCancel()
    self:close()
end

function DT_LabourQuantityModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DT_LabourQuantityModal.Open(args)
    args = args or {}

    local modal = DT_LabourQuantityModal.instance
    if not modal then
        local width = 320
        local height = 150
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2
        modal = DT_LabourQuantityModal:new(x, y, width, height)
        modal:initialise()
        modal:instantiate()
        DT_LabourQuantityModal.instance = modal
    end

    modal.title = tostring(args.title or "Choose Quantity")
    modal.promptText = tostring(args.promptText or "Enter quantity.")
    modal.maxValue = math.max(1, math.floor(tonumber(args.maxValue) or 1))
    modal.defaultValue = clampQuantity(args.defaultValue or modal.maxValue, modal.maxValue)
    modal.onConfirmCallback = args.onConfirm

    if modal.promptLabel then
        modal.promptLabel:setName(modal.promptText)
    end
    if modal.maxLabel then
        modal.maxLabel:setName("Available: " .. tostring(modal.maxValue))
    end
    if modal.quantityEntry then
        modal.quantityEntry:setText(tostring(modal.defaultValue))
    end

    modal:setVisible(true)
    modal:addToUIManager()
    modal:bringToTop()
    if modal.quantityEntry and modal.quantityEntry.focus then
        modal.quantityEntry:focus()
    end

    return modal
end

function DT_LabourQuantityModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Choose Quantity"
    o.resizable = false
    o.promptText = "Enter quantity."
    o.defaultValue = 1
    o.maxValue = 1
    o.onConfirmCallback = nil
    return o
end

return DT_LabourQuantityModal
