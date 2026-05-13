DC_ColonyJobModal = DC_ColonyJobModal or {}
DC_ColonyJobModal.Internal = DC_ColonyJobModal.Internal or {}

local JobOptionList = ISScrollingListBox:derive("ColonyJobModalList")

local function drawOptionLabel(self, y, item, alt)
    local option = item and item.item or nil
    if not option then
        return y + self.itemheight
    end

    local width = self:getWidth()
    local isSelected = self.selected == item.index
    if isSelected then
        self:drawRect(0, y, width, self.itemheight, 0.24, 0.18, 0.38, 0.62)
    elseif alt then
        self:drawRect(0, y, width, self.itemheight, 0.04, 1, 1, 1)
    end

    self:drawRectBorder(0, y, width, self.itemheight, 0.08, 1, 1, 1)

    local boxX = 6
    local boxY = y + 6
    local boxSize = 14
    local textX = boxX + boxSize + 8
    local palette = option.enabled == false and option.disabledColor or option.color or { r = 0.9, g = 0.9, b = 0.9, a = 1 }

    self:drawRectBorder(boxX, boxY, boxSize, boxSize, 0.7, 1, 1, 1)
    if isSelected and option.enabled ~= false then
        self:drawRect(boxX + 3, boxY + 3, boxSize - 6, boxSize - 6, 1, 0.18, 0.92, 0.28)
    end

    self:drawText(tostring(option.label or option.jobType or "Unknown"), textX, y + 5, palette.r or 1, palette.g or 1, palette.b or 1, palette.a or 1, UIFont.Small)

    if option.enabled == false and tostring(option.disabledReason or "") ~= "" then
        self:drawTextRight(tostring(option.disabledReason), width - 8, y + 5, 0.78, 0.46, 0.46, 0.9, UIFont.Small)
    end

    return y + self.itemheight
end

function JobOptionList:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = 28
    o.font = UIFont.Small
    o.doDrawItem = drawOptionLabel
    return o
end

function JobOptionList:onMouseDown(x, y)
    local result = ISScrollingListBox.onMouseDown(self, x, y)
    local item = self.items and self.items[self.selected] or nil
    local option = item and item.item or nil
    if option and self.target and self.target.selectJobIndex then
        if option.enabled == false then
            self.selected = self.target.selectedOptionIndex or -1
            return true
        end
        self.target:selectJobIndex(item.index)
    end
    return result
end

DC_ColonyJobModal.Internal.JobOptionList = JobOptionList

return JobOptionList