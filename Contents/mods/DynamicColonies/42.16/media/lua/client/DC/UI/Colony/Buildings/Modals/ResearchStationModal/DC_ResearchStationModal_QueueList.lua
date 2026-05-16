local Internal = DC_ResearchStationModalInternal

local QueueList = ISScrollingListBox:derive("DC_ResearchStationModalQueueList")

function QueueList:doDrawItem(y, item, alt)
    local entry = item and item.item or nil
    local selected = self.selected == item.index
    local backgroundA = selected and 0.18 or (alt and 0.06 or 0.03)
    self:drawRect(0, y, self:getWidth(), self.itemheight - 1, backgroundA, 0, 0, 0)

    local label = tostring(entry and entry.displayName or entry and entry.fullType or "Research")
    local progressRatio = math.max(0, math.min(1, tonumber(entry and entry.progressRatio) or 0))
    local workText = tostring(math.floor((tonumber(entry and entry.progressWork) or 0) + 0.5))
        .. "/"
        .. tostring(math.floor((tonumber(entry and entry.requiredWork) or 0) + 0.5))
        .. " WP"

    self:drawText(label, 8, y + 2, 1, 1, 1, 1, UIFont.Small)
    self:drawTextRight(workText, self:getWidth() - 8, y + 2, 0.82, 0.82, 0.82, 1, UIFont.Small)

    local barX = 8
    local barY = y + 18
    local barWidth = math.max(20, self:getWidth() - 16)
    local barHeight = 6
    self:drawRect(barX, barY, barWidth, barHeight, 0.32, 0, 0, 0)
    self:drawRect(barX, barY, math.floor(barWidth * progressRatio), barHeight, 0.92, 0.76, 0.26, 0.20)

    local detail = "Samples x" .. tostring(math.max(1, math.floor(tonumber(entry and entry.sampleCount) or 1)))
    if tostring(entry and entry.leadResearcherName or "") ~= "" then
        detail = detail
            .. " | "
            .. tostring(entry.leadResearcherName)
            .. " Int "
            .. tostring(math.max(0, math.floor(tonumber(entry and entry.leadResearcherLevel) or 0)))
    end
    self:drawText(detail, 8, y + 26, 0.68, 0.68, 0.68, 1, UIFont.Small)

    return y + self.itemheight
end

function QueueList:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = 42
    o.font = UIFont.Small
    return o
end

Internal.QueueListClass = QueueList
