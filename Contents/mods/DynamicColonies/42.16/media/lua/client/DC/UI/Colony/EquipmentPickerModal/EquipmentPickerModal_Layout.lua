DC_EquipmentPickerModal = DC_EquipmentPickerModal or {}
DC_EquipmentPickerModal.Internal = DC_EquipmentPickerModal.Internal or {}

local Internal = DC_EquipmentPickerModal.Internal
local FlavorText = Internal.FlavorText or {}

function DC_EquipmentPickerModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_EquipmentPickerModal:createChildren()
    ISCollapsableWindow.createChildren(self)
    if self.promptLabel then
        return
    end

    local th = self:titleBarHeight()
    local listClass = Internal.EquipmentPickerModalList or ISScrollingListBox

    self.promptLabel = ISLabel:new(10, th + 14, 20, tostring(self.promptText or FlavorText.promptText or "Choose an equipment source."), 0.82, 0.82, 0.82, 1, UIFont.Small, true)
    self.promptLabel:initialise()
    self.promptLabel:instantiate()
    self:addChild(self.promptLabel)

    local filterY = th + 42
    self.sourceCombo = ISComboBox:new(10, filterY, 196, 24, self, self.onSourceFilterChanged)
    self.sourceCombo:initialise()
    self.sourceCombo:instantiate()
    for _, option in ipairs(Internal.SourceOptions or {}) do
        self.sourceCombo:addOption(option.label)
    end
    self:addChild(self.sourceCombo)

    self.list = listClass:new(10, th + 76, self.width - 20, self.height - th - 120)
    self.list:initialise()
    self.list:instantiate()
    self.list.target = self
    self:addChild(self.list)

    self.btnConfirm = ISButton:new(10, self.height - 34, 92, 24, tostring(self.confirmLabel or FlavorText.confirmTitle or "Confirm"), self, self.onConfirmClicked)
    self.btnConfirm:initialise()
    self:addChild(self.btnConfirm)

    self.btnCancel = ISButton:new(self.width - 102, self.height - 34, 92, 24, tostring(FlavorText.cancelTitle or "Cancel"), self, self.onCancelClicked)
    self.btnCancel:initialise()
    self:addChild(self.btnCancel)

    self:applyArgs({
        title = self.title,
        promptText = self.promptText,
        confirmLabel = self.confirmLabel,
        candidates = self.candidates,
        sourceFilter = self.sourceFilter,
        onConfirm = self.onConfirmCallback
    })
end

return DC_EquipmentPickerModal