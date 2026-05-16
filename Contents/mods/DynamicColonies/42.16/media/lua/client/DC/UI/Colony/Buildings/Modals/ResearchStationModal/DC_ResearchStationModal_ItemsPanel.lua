local Internal = DC_ResearchStationModalInternal

local ItemsPanel = ISPanel:derive("DC_ResearchStationModalItemsPanel")

function ItemsPanel:initialise()
    ISPanel.initialise(self)
end

function ItemsPanel:createChildren()
    ISPanel.createChildren(self)

    self.candidateList = ISScrollingListBox:new(0, 0, 100, 100)
    self.candidateList:initialise()
    self.candidateList.itemheight = 24
    self.candidateList.font = UIFont.Small
    self.candidateList.onmousedown = function(list)
        local item = list.items[list.selected]
        self.modal.selectedCandidate = item and item.item or nil
        self.modal.selectedQueue = nil
        self.modal:updateDetailText()
    end
    self:addChild(self.candidateList)

    self.queueList = Internal.QueueListClass and Internal.QueueListClass:new(0, 0, 100, 100) or ISScrollingListBox:new(0, 0, 100, 100)
    self.queueList:initialise()
    self.queueList.onmousedown = function(list)
        local item = list.items[list.selected]
        self.modal.selectedQueue = item and item.item or nil
        self.modal.selectedCandidate = nil
        self.modal:updateDetailText()
    end
    self:addChild(self.queueList)

    self.modal.candidateList = self.candidateList
    self.modal.queueList = self.queueList
    self:layoutChildren()
end

function ItemsPanel:layoutChildren()
    local margin = 8
    local headerHeight = 22
    local gutter = 8
    local listY = margin + headerHeight
    local listHeight = math.max(120, self.height - listY - margin)
    local availableWidth = math.max(220, self.width - (margin * 2) - gutter)
    local columnWidth = math.floor(availableWidth / 2)
    local rightX = margin + columnWidth + gutter
    local rightWidth = math.max(100, self.width - rightX - margin)

    if self.candidateList then
        self.candidateList:setX(margin)
        self.candidateList:setY(listY)
        self.candidateList:setWidth(columnWidth)
        self.candidateList:setHeight(listHeight)
    end

    if self.queueList then
        self.queueList:setX(rightX)
        self.queueList:setY(listY)
        self.queueList:setWidth(rightWidth)
        self.queueList:setHeight(listHeight)
    end
end

function ItemsPanel:prerender()
    ISPanel.prerender(self)
    self:drawRect(0, 0, self.width, self.height, 0.08, 0, 0, 0)
    self:drawRectBorder(0, 0, self.width, self.height, 0.2, 1, 1, 1)
    self:drawText("Researchable Items", 8, 6, 1, 1, 1, 1, UIFont.Small)
    self:drawText("Queue", math.floor(self.width / 2) + 4, 6, 1, 1, 1, 1, UIFont.Small)
end

function ItemsPanel:onResize()
    ISPanel.onResize(self)
    self:layoutChildren()
end

function ItemsPanel:new(modal, x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.modal = modal
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

Internal.ItemsPanelClass = ItemsPanel
