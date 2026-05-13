DC_EquipmentPickerModal = DC_EquipmentPickerModal or {}
DC_EquipmentPickerModal.Internal = DC_EquipmentPickerModal.Internal or {}

local Internal = DC_EquipmentPickerModal.Internal
local FlavorText = Internal.FlavorText or {}

function DC_EquipmentPickerModal:getSelectedCandidate()
    local row = self.list and self.list.selected or -1
    local item = row and row > 0 and self.list.items[row] or nil
    return item and item.item or nil
end

function DC_EquipmentPickerModal:refreshVisibleCandidates()
    if not self.list then
        return
    end

    local selectedCandidate = self:getSelectedCandidate()
    local selectedKey = selectedCandidate
        and tostring(selectedCandidate.source or "") .. "|" .. tostring(selectedCandidate.itemID or selectedCandidate.ledgerIndex or selectedCandidate.fullType or "")
        or nil

    self.list:clear()
    for _, candidate in ipairs(self.candidates or {}) do
        local source = tostring(candidate.source or "")
        if self.sourceFilter == "all" or self.sourceFilter == source then
            self.list:addItem(candidate.displayName or candidate.fullType or "Item", candidate)
        end
    end

    self.list.selected = -1
    if selectedKey then
        for index, row in ipairs(self.list.items) do
            local candidate = row and row.item or nil
            local rowKey = tostring(candidate and candidate.source or "") .. "|" .. tostring(candidate and (candidate.itemID or candidate.ledgerIndex or candidate.fullType) or "")
            if rowKey == selectedKey then
                self.list.selected = index
                break
            end
        end
    end

    if self.list.selected == -1 and #self.list.items > 0 then
        self.list.selected = 1
    end

    self:updateConfirmState()
end

function DC_EquipmentPickerModal:updateConfirmState()
    if self.btnConfirm then
        self.btnConfirm:setEnable(self:getSelectedCandidate() ~= nil)
    end
end

function DC_EquipmentPickerModal:setSourceFilter(filterID)
    self.sourceFilter = filterID or "all"
    if self.sourceCombo then
        local selectedIndex = Internal.FindSourceOptionIndex and Internal.FindSourceOptionIndex(self.sourceFilter) or 1
        if self.sourceCombo.selected ~= selectedIndex then
            self.sourceCombo.selected = selectedIndex
        end
    end
    self:refreshVisibleCandidates()
end

function DC_EquipmentPickerModal:applyArgs(args)
    args = args or {}
    self.title = tostring(args.title or FlavorText.windowTitle or "Choose Equipment")
    self.promptText = tostring(args.promptText or FlavorText.promptText or "Choose an equipment source.")
    self.confirmLabel = tostring(args.confirmLabel or FlavorText.confirmTitle or "Confirm")
    self.candidates = args.candidates or {}
    self.sourceFilter = tostring(args.sourceFilter or "all")
    self.onConfirmCallback = args.onConfirm

    if self.promptLabel then
        self.promptLabel:setName(self.promptText)
    end
    if self.btnConfirm then
        self.btnConfirm:setTitle(self.confirmLabel)
    end

    self:setSourceFilter(self.sourceFilter)
end

return DC_EquipmentPickerModal