local Internal = DC_ResearchStationModalInternal

function DC_ResearchStationModal:initialise()
    ISCollapsableWindow.initialise(self)
end

function DC_ResearchStationModal:layoutChildren()
    local margin = 10
    local top = self:titleBarHeight() + 10
    local footerHeight = 34
    local footerGap = 12
    local footerY = self.height - footerHeight - margin
    local contentHeight = math.max(180, footerY - top - footerGap)
    local contentWidth = math.max(520, self.width - (margin * 3))
    local itemsWidth = math.max(360, math.floor(contentWidth * 0.5))
    local maxItemsWidth = math.max(360, contentWidth - 260)
    local detailWidth = math.max(220, contentWidth - itemsWidth)

    if itemsWidth > maxItemsWidth then
        itemsWidth = maxItemsWidth
        detailWidth = math.max(220, contentWidth - itemsWidth)
    end

    local detailX = margin + itemsWidth + margin
    if self.itemsPanel then
        self.itemsPanel:setX(margin)
        self.itemsPanel:setY(top)
        self.itemsPanel:setWidth(itemsWidth)
        self.itemsPanel:setHeight(contentHeight)
        if self.itemsPanel.layoutChildren then
            self.itemsPanel:layoutChildren()
        end
    end

    if self.detailPanel then
        self.detailPanel:setX(detailX)
        self.detailPanel:setY(top)
        self.detailPanel:setWidth(detailWidth)
        self.detailPanel:setHeight(contentHeight)
    end

    if self.detailText and self.detailPanel then
        self.detailText:setX(8)
        self.detailText:setY(92)
        self.detailText:setWidth(math.max(120, self.detailPanel.width - 16))
        self.detailText:setHeight(math.max(120, self.detailPanel.height - 100))
        if self.detailText.vscroll then
            self.detailText.vscroll:setHeight(self.detailText:getHeight())
        end
    end
    if self.progressPanel and self.detailPanel then
        self.progressPanel:setX(8)
        self.progressPanel:setY(28)
        self.progressPanel:setWidth(math.max(120, self.detailPanel.width - 16))
        self.progressPanel:setHeight(56)
    end

    if self.btnSubmit then
        self.btnSubmit:setX(margin)
        self.btnSubmit:setY(footerY)
    end
    if self.btnRefresh then
        self.btnRefresh:setX(margin + 118)
        self.btnRefresh:setY(footerY)
    end
    if self.statusButton then
        self.statusButton:setX(margin + 216)
        self.statusButton:setY(footerY)
        self.statusButton:setWidth(math.max(180, self.width - (margin + 216) - margin))
    end
end

function DC_ResearchStationModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    self.itemsPanel = Internal.ItemsPanelClass:new(self, 0, 0, 100, 100)
    self.itemsPanel:initialise()
    self.itemsPanel:createChildren()
    self:addChild(self.itemsPanel)

    self.detailPanel = ISPanel:new(0, 0, 100, 100)
    self.detailPanel:initialise()
    self.detailPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0.08 }
    self.detailPanel.borderColor = { r = 1, g = 1, b = 1, a = 0.2 }
    self.detailPanel.prerender = function(panel)
        ISPanel.prerender(panel)
        panel:drawRect(0, 0, panel.width, panel.height, 0.08, 0, 0, 0)
        panel:drawRectBorder(0, 0, panel.width, panel.height, 0.2, 1, 1, 1)
        panel:drawText("Details", 8, 6, 1, 1, 1, 1, UIFont.Small)
    end
    self:addChild(self.detailPanel)

    self.detailText = ISRichTextPanel:new(8, 28, 100, 100)
    self.detailText:initialise()
    self.detailText.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.detailText.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.detailText.clip = true
    self.detailText.autosetheight = false
    self.detailText:addScrollBars()
    self.detailPanel:addChild(self.detailText)

    self.progressPanel = ISPanel:new(8, 28, 100, 56)
    self.progressPanel:initialise()
    self.progressPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0.04 }
    self.progressPanel.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    self.progressPanel.prerender = function(panel)
        ISPanel.prerender(panel)
        local source = self:getProgressSource()
        local label = "No active research"
        local progressRatio = 0
        local progressWork = 0
        local requiredWork = 0

        if source then
            label = tostring(source.displayName or source.fullType or "Research")
            progressRatio = math.max(0, math.min(1, tonumber(source.progressRatio) or 0))
            progressWork = math.floor((tonumber(source.progressWork) or 0) + 0.5)
            requiredWork = math.floor((tonumber(source.requiredWork) or 0) + 0.5)
        end

        panel:drawRect(0, 0, panel.width, panel.height, 0.08, 0, 0, 0)
        panel:drawRectBorder(0, 0, panel.width, panel.height, 0.16, 1, 1, 1)
        panel:drawText(label, 8, 6, 1, 1, 1, 1, UIFont.Small)
        panel:drawTextRight(
            tostring(progressWork) .. " / " .. tostring(requiredWork) .. " WP",
            panel.width - 8,
            6,
            0.82,
            0.82,
            0.82,
            1,
            UIFont.Small
        )

        local barX = 8
        local barY = 26
        local barWidth = math.max(40, panel.width - 16)
        local barHeight = 16
        panel:drawRect(barX, barY, barWidth, barHeight, 0.28, 0, 0, 0)
        panel:drawRect(barX, barY, math.floor(barWidth * progressRatio), barHeight, 0.95, 0.80, 0.28, 0.20)
        panel:drawRectBorder(barX, barY, barWidth, barHeight, 0.20, 1, 1, 1)
        panel:drawTextCentre(
            tostring(math.floor((progressRatio * 100) + 0.5)) .. "%",
            math.floor(panel.width / 2),
            barY,
            1,
            1,
            1,
            1,
            UIFont.Small
        )
    end
    self.detailPanel:addChild(self.progressPanel)

    self.btnSubmit = ISButton:new(10, 10, 110, 26, "Submit Item", self, self.onSubmitClicked)
    self.btnSubmit:initialise()
    self:addChild(self.btnSubmit)

    self.btnRefresh = ISButton:new(10, 10, 90, 26, "Refresh", self, self.onRefreshClicked)
    self.btnRefresh:initialise()
    self:addChild(self.btnRefresh)

    self.statusButton = ISButton:new(10, 10, 260, 26, "", self, function() end)
    self.statusButton:initialise()
    self.statusButton:setEnable(false)
    self:addChild(self.statusButton)

    self:layoutChildren()
    self:rebuildCandidateList()
    self:refreshFromSnapshot()
end

function DC_ResearchStationModal:onResize()
    ISCollapsableWindow.onResize(self)
    if self.minimumWidth and self.width < self.minimumWidth then
        self:setWidth(self.minimumWidth)
    end
    if self.minimumHeight and self.height < self.minimumHeight then
        self:setHeight(self.minimumHeight)
    end
    self:layoutChildren()
    self:updateDetailText()
end

function DC_ResearchStationModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_ResearchStationModal.instance == self then
        DC_ResearchStationModal.instance = nil
    end
end
