DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal
local LabourSupplyList = ISScrollingListBox:derive("LabourSupplyList")

local function fitTextToWidth(font, text, maxWidth)
    local value = tostring(text or "")
    if value == "" or maxWidth <= 0 then
        return ""
    end

    local textManager = getTextManager()
    if textManager:MeasureStringX(font, value) <= maxWidth then
        return value
    end

    local ellipsis = "..."
    local ellipsisWidth = textManager:MeasureStringX(font, ellipsis)
    if ellipsisWidth >= maxWidth then
        return ellipsis
    end

    local trimmedLength = #value
    while trimmedLength > 0 do
        local candidate = string.sub(value, 1, trimmedLength) .. ellipsis
        if textManager:MeasureStringX(font, candidate) <= maxWidth then
            return candidate
        end
        trimmedLength = trimmedLength - 1
    end

    return ellipsis
end

function LabourSupplyList:new(x, y, width, height, mode)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = 46
    o.selected = -1
    o.font = UIFont.Small
    o.mode = mode or "player"
    return o
end

function LabourSupplyList:doDrawItem(y, item, alt)
    local entry = item.item
    if not entry then
        return y + self.itemheight
    end

    local activeTab = self.target and self.target.activeTab or Internal.Tabs.Provisions
    local presentation = self.mode == "worker"
        and Internal.getWorkerEntryPresentation(entry, activeTab)
        or Internal.getPlayerEntryPresentation(entry, activeTab, self.target and self.target.workerData or nil, self.target)
    local width = self:getWidth()
    local isSelected = self.selected == item.index
    if isSelected then
        self:drawRect(0, y, width, self.itemheight, 0.25, 0.18, 0.38, 0.62)
    elseif presentation.dimmed then
        self:drawRect(0, y, width, self.itemheight, 0.15, 0.15, 0.08, 0.08)
    elseif alt then
        self:drawRect(0, y, width, self.itemheight, 0.08, 1, 1, 1)
    end

    self:drawRectBorder(0, y, width, self.itemheight, 0.08, 1, 1, 1)

    if entry.texture then
        local alpha = 1
        if presentation.dimmed then
            alpha = 0.35
        end
        self:drawTextureScaled(entry.texture, 6, y + 7, 28, 28, alpha, 1, 1, 1)
    end

    local textR, textG, textB = 0.9, 0.9, 0.9
    if presentation.dimmed then
        textR, textG, textB = 0.45, 0.45, 0.45
    end

    local badgeText = presentation.badgeText or "Stored"
    local badgeR, badgeG, badgeB = 0.72, 0.72, 0.72
    if badgeText == "Ready" then
        badgeR, badgeG, badgeB = 0.52, 0.9, 0.62
    elseif badgeText == "Preview" then
        badgeR, badgeG, badgeB = 0.86, 0.74, 0.52
    elseif badgeText == "Pending" then
        badgeR, badgeG, badgeB = 0.96, 0.82, 0.42
    elseif badgeText == "Tool" then
        badgeR, badgeG, badgeB = 0.64, 0.88, 0.74
    elseif badgeText == "Equipped" then
        badgeR, badgeG, badgeB = 0.56, 0.82, 0.98
    elseif badgeText == "Read Only" then
        badgeR, badgeG, badgeB = 0.78, 0.78, 0.78
    elseif badgeText == "Cash" then
        badgeR, badgeG, badgeB = 0.92, 0.82, 0.38
    elseif badgeText == "Needed" then
        badgeR, badgeG, badgeB = 0.96, 0.72, 0.38
    else
        badgeR, badgeG, badgeB = 0.55, 0.76, 0.98
    end

    local rightPadding = 20
    local badgeWidth = (badgeText ~= "") and getTextManager():MeasureStringX(UIFont.Small, badgeText) or 0
    local textMaxWidth = math.max(60, width - 42 - badgeWidth - rightPadding - 12)
    local titleText = fitTextToWidth(UIFont.Small, Internal.formatEntryLabel(entry), textMaxWidth)
    local statText = fitTextToWidth(UIFont.Small, presentation.statText or "", textMaxWidth)

    self:drawText(titleText, 42, y + 5, textR, textG, textB, 1, UIFont.Small)
    self:drawText(statText, 42, y + 23, 0.65, 0.8, 0.95, 1, UIFont.Small)
    if badgeText ~= "" then
        self:drawTextRight(badgeText, width - rightPadding, y + 5, badgeR, badgeG, badgeB, 1, UIFont.Small)
    end

    return y + self.itemheight
end

Internal.LabourSupplyList = LabourSupplyList
