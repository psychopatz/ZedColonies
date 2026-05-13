DC_EquipmentPickerModal = DC_EquipmentPickerModal or {}
DC_EquipmentPickerModal.Internal = DC_EquipmentPickerModal.Internal or {}

local EquipmentPickerModalList = ISScrollingListBox:derive("EquipmentPickerModalList")

local function drawItem(self, y, item, alt)
    local candidate = item and item.item or nil
    if not candidate then
        return y + self.itemheight
    end

    local width = self:getWidth()
    local isSelected = self.selected == item.index
    if isSelected then
        self:drawRect(0, y, width, self.itemheight, 0.25, 0.18, 0.38, 0.62)
    elseif alt then
        self:drawRect(0, y, width, self.itemheight, 0.06, 1, 1, 1)
    end

    self:drawRectBorder(0, y, width, self.itemheight, 0.08, 1, 1, 1)

    if candidate.texture then
        self:drawTextureScaled(candidate.texture, 8, y + 9, 28, 28, 1, 1, 1, 1)
    end

    local textX = 44
    local sourceLabel = tostring(candidate.sourceLabel or candidate.source or "")
    local badgeR, badgeG, badgeB = 0.72, 0.72, 0.72
    if sourceLabel == "Player" then
        badgeR, badgeG, badgeB = 0.54, 0.88, 0.72
    elseif sourceLabel == "Warehouse" then
        badgeR, badgeG, badgeB = 0.56, 0.8, 0.98
    end

    self:drawText(tostring(candidate.displayName or candidate.fullType or "Item"), textX, y + 6, 0.92, 0.92, 0.92, 1, UIFont.Small)
    self:drawTextRight(sourceLabel, width - 12, y + 6, badgeR, badgeG, badgeB, 1, UIFont.Small)

    local statText = tostring(candidate.statText or "")
    if statText ~= "" then
        self:drawText(statText, textX, y + 24, 0.66, 0.8, 0.95, 1, UIFont.Small)
    end

    return y + self.itemheight
end

function EquipmentPickerModalList:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = 48
    o.font = UIFont.Small
    o.doDrawItem = drawItem
    return o
end

function EquipmentPickerModalList:onMouseDown(x, y)
    local result = ISScrollingListBox.onMouseDown(self, x, y)
    if self.target and self.target.updateConfirmState then
        self.target:updateConfirmState()
    end
    return result
end

DC_EquipmentPickerModal.Internal.EquipmentPickerModalList = EquipmentPickerModalList

return EquipmentPickerModalList