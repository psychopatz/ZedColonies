DC_EquipmentPickerModal = DC_EquipmentPickerModal or {}
DC_EquipmentPickerModal.Internal = DC_EquipmentPickerModal.Internal or {}

local Internal = DC_EquipmentPickerModal.Internal

function DC_EquipmentPickerModal:onSourceFilterChanged()
    if not self.sourceCombo then
        return
    end
    self:setSourceFilter(Internal.GetSourceFilterIDByIndex and Internal.GetSourceFilterIDByIndex(self.sourceCombo.selected) or "all")
end

function DC_EquipmentPickerModal:onConfirmClicked()
    local candidate = self:getSelectedCandidate()
    if candidate and self.onConfirmCallback then
        self.onConfirmCallback(candidate)
    end
    self:close()
end

function DC_EquipmentPickerModal:onCancelClicked()
    self:close()
end

function DC_EquipmentPickerModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

return DC_EquipmentPickerModal