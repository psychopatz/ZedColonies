require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISComboBox"
require "ISUI/ISLabel"
require "ISUI/ISButton"

local EquipmentPickerList = ISScrollingListBox:derive("DC_EquipmentPickerList")

function EquipmentPickerList:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = 44
    o.font = UIFont.Small
    return o
end

function EquipmentPickerList:onMouseDown(x, y)
    local result = ISScrollingListBox.onMouseDown(self, x, y)
    if self.target and self.target.updateConfirmState then
        self.target:updateConfirmState()
    end
    return result
end

function EquipmentPickerList:doDrawItem(y, item, alt)
    local option = item.item
    if not option then
        return y + self.itemheight
    end

    local width = self:getWidth()
    local selected = self.selected == item.index
    if selected then
        self:drawRect(0, y, width, self.itemheight, 0.25, 0.18, 0.38, 0.62)
    elseif alt then
        self:drawRect(0, y, width, self.itemheight, 0.08, 1, 1, 1)
    end
    self:drawRectBorder(0, y, width, self.itemheight, 0.08, 1, 1, 1)

    if option.texture then
        self:drawTextureScaled(option.texture, 8, y + 8, 26, 26, option.dimmed and 0.45 or 1, 1, 1, 1)
    end

    local titleR, titleG, titleB = 0.92, 0.92, 0.92
    local detailR, detailG, detailB = 0.68, 0.78, 0.9
    if option.dimmed then
        titleR, titleG, titleB = 0.5, 0.5, 0.5
        detailR, detailG, detailB = 0.42, 0.42, 0.42
    end

    self:drawText(tostring(option.displayName or option.fullType or "Equipment"), 42, y + 6, titleR, titleG, titleB, 1, UIFont.Small)
    self:drawText(tostring(option.statText or ""), 42, y + 22, detailR, detailG, detailB, 1, UIFont.Small)

    local badgeText = tostring(option.sourceLabel or option.source or "")
    if badgeText ~= "" then
        local badgeR, badgeG, badgeB = 0.72, 0.72, 0.72
        if option.source == "player" then
            badgeR, badgeG, badgeB = 0.56, 0.84, 0.58
        elseif option.source == "warehouse" then
            badgeR, badgeG, badgeB = 0.56, 0.78, 0.98
        end
        self:drawTextRight(badgeText, width - 12, y + 6, badgeR, badgeG, badgeB, 1, UIFont.Small)
    end

    return y + self.itemheight
end

DC_EquipmentPickerModal = ISCollapsableWindow:derive("DC_EquipmentPickerModal")
DC_EquipmentPickerModal.instance = nil

function DC_EquipmentPickerModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_EquipmentPickerModal:getSourceFilter()
    local selected = self.sourceFilterCombo and math.max(1, tonumber(self.sourceFilterCombo.selected) or 1) or 1
    return tostring((self.filterValues or {})[selected] or "all")
end

function DC_EquipmentPickerModal:refreshVisibleOptions()
    self.visibleOptions = {}
    local filter = self:getSourceFilter()

    if self.optionList then
        self.optionList:clear()
    end

    for _, option in ipairs(self.options or {}) do
        if filter == "all" or tostring(option.source or "") == filter then
            self.visibleOptions[#self.visibleOptions + 1] = option
            if self.optionList then
                self.optionList:addItem(option.displayName or option.fullType or "Equipment", option)
            end
        end
    end

    if self.optionList then
        self.optionList.selected = #self.visibleOptions > 0 and 1 or -1
    end
    if self.emptyLabel then
        self.emptyLabel:setVisible(#self.visibleOptions <= 0)
    end
    self:updateConfirmState()
end

function DC_EquipmentPickerModal:getSelectedOption()
    local selected = self.optionList and self.optionList.selected or -1
    if selected and selected > 0 then
        local row = self.optionList.items and self.optionList.items[selected] or nil
        return row and row.item or nil
    end
    return nil
end

function DC_EquipmentPickerModal:updateConfirmState()
    if self.btnConfirm then
        self.btnConfirm:setEnable(self:getSelectedOption() ~= nil)
    end
end

function DC_EquipmentPickerModal:onSourceFilterChanged()
    self:refreshVisibleOptions()
end

function DC_EquipmentPickerModal:onConfirmClicked()
    local option = self:getSelectedOption()
    if option and self.onConfirmCallback then
        self.onConfirmCallback(option)
    end
    self:close()
end

function DC_EquipmentPickerModal:onCancelClicked()
    self:close()
end

function DC_EquipmentPickerModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_EquipmentPickerModal.instance == self then
        DC_EquipmentPickerModal.instance = nil
    end
end

function DC_EquipmentPickerModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 10
    local th = self:titleBarHeight()

    self.promptLabel = ISLabel:new(pad, th + pad, 20, tostring(self.promptText or "Choose equipment."), 1, 1, 1, 1, UIFont.Small, true)
    self.promptLabel:initialise()
    self.promptLabel:instantiate()
    self:addChild(self.promptLabel)

    self.sourceFilterCombo = ISComboBox:new(pad, th + 32, self.width - (pad * 2), 24, self, self.onSourceFilterChanged)
    self.sourceFilterCombo:initialise()
    self.sourceFilterCombo:addOption("All Sources")
    self.sourceFilterCombo:addOption("Player Inventory")
    self.sourceFilterCombo:addOption("Warehouse")
    self.sourceFilterCombo.selected = 1
    self:addChild(self.sourceFilterCombo)

    self.optionList = EquipmentPickerList:new(pad, th + 62, self.width - (pad * 2), self.height - th - 106)
    self.optionList:initialise()
    self.optionList:instantiate()
    self.optionList.itemheight = 44
    self.optionList.target = self
    self:addChild(self.optionList)

    self.emptyLabel = ISLabel:new(pad, th + 92, 20, "No matching equipment is currently available.", 0.76, 0.76, 0.76, 1, UIFont.Small, true)
    self.emptyLabel:initialise()
    self.emptyLabel:instantiate()
    self.emptyLabel:setVisible(false)
    self:addChild(self.emptyLabel)

    self.btnConfirm = ISButton:new(pad, self.height - 34, 90, 24, tostring(self.confirmLabel or "Choose"), self, self.onConfirmClicked)
    self.btnConfirm:initialise()
    self:addChild(self.btnConfirm)

    self.btnCancel = ISButton:new(self.width - 100, self.height - 34, 90, 24, "Cancel", self, self.onCancelClicked)
    self.btnCancel:initialise()
    self:addChild(self.btnCancel)

    self:refreshVisibleOptions()
end

function DC_EquipmentPickerModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Choose Equipment"
    o.resizable = false
    o.promptText = "Choose equipment."
    o.confirmLabel = "Choose"
    o.options = {}
    o.visibleOptions = {}
    o.filterValues = { "all", "player", "warehouse" }
    o.onConfirmCallback = nil
    return o
end

function DC_EquipmentPickerModal.Open(args)
    args = args or {}
    if DC_EquipmentPickerModal.instance then
        DC_EquipmentPickerModal.instance:close()
    end

    local width = 560
    local height = 430
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local modal = DC_EquipmentPickerModal:new(x, y, width, height)
    modal.title = tostring(args.title or "Choose Equipment")
    modal.promptText = tostring(args.promptText or "Choose equipment.")
    modal.confirmLabel = tostring(args.confirmLabel or "Choose")
    modal.options = args.options or {}
    modal.onConfirmCallback = args.onConfirm
    modal:initialise()
    modal:instantiate()
    modal:setVisible(true)
    modal:addToUIManager()
    modal:bringToTop()
    DC_EquipmentPickerModal.instance = modal
    return modal
end

return DC_EquipmentPickerModal
