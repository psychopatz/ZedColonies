function DC_BuildingProjectModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

local function getRichTextContentHeight(panel)
    if not panel then
        return 0
    end

    local directHeight = tonumber(panel.textHeight) or tonumber(panel.contentHeight)
    if directHeight and directHeight > 0 then
        return directHeight
    end

    local getter = panel.getScrollHeight or panel.getTextHeight
    if getter then
        local ok, value = pcall(getter, panel)
        if ok and tonumber(value) and tonumber(value) > 0 then
            return tonumber(value)
        end
    end

    return 0
end

function DC_BuildingProjectModal:relayout()
    if not self.textPanel then
        return
    end

    local th = self:titleBarHeight()
    local hasSupplyAction = self.preview and self.preview.projectID ~= nil
    local isBlueprintCraft = self.preview and self.preview.actionType == "CraftBlueprint"
    local actionButtonCount = 2
    if hasSupplyAction then
        actionButtonCount = actionButtonCount + 1
    end
    if self.debugEnabled == true then
        actionButtonCount = actionButtonCount + 1
    end
    local actionAreaWidth = (actionButtonCount * 90) + ((actionButtonCount - 1) * 10)
    local footerOffset = isBlueprintCraft and 48 or 78
    local screenWidth = getCore and getCore():getScreenWidth() or self.width
    local screenHeight = getCore and getCore():getScreenHeight() or self.height

    local minWidth = math.max(520, actionAreaWidth + 140)
    local maxWidth = math.max(minWidth, screenWidth - 40)
    local currentWidth = self.width
    local desiredWidth = math.min(math.max(currentWidth, minWidth), maxWidth)
    local widthChanged = desiredWidth ~= currentWidth
    if widthChanged then
        self:setWidth(desiredWidth)
    end

    if widthChanged then
        self.textPanel:setWidth(self.width - 20)
        self.textPanel:paginate()
    end

    local contentHeight = math.max(180, getRichTextContentHeight(self.textPanel))
    local minHeight = th + 10 + 180 + footerOffset
    local desiredHeight = th + 10 + contentHeight + footerOffset
    local maxHeight = math.max(minHeight, screenHeight - 40)
    local desiredWindowHeight = math.min(math.max(desiredHeight, minHeight), maxHeight)
    if desiredWindowHeight ~= self.height then
        self:setHeight(desiredWindowHeight)
    end

    local textHeight = math.max(0, self.height - th - footerOffset)
    self.textPanel:setX(10)
    self.textPanel:setY(th + 10)
    self.textPanel:setWidth(self.width - 20)
    self.textPanel:setHeight(textHeight)

    local footerY = self.height - 58
    local buttonX = self.width - actionAreaWidth - 10

    if self.builderCombo then
        self.builderCombo:setX(10)
        self.builderCombo:setY(footerY)
        self.builderCombo:setWidth(self.width - actionAreaWidth - 20)
        self.builderCombo:setHeight(24)
    end

    if self.btnDebugMaterials then
        self.btnDebugMaterials:setX(buttonX)
        self.btnDebugMaterials:setY(footerY)
        buttonX = buttonX + 100
    end

    if self.btnSupplyProject then
        self.btnSupplyProject:setX(buttonX)
        self.btnSupplyProject:setY(footerY)
        buttonX = buttonX + 100
    end

    if self.btnConfirm then
        self.btnConfirm:setX(buttonX)
        self.btnConfirm:setY(footerY)
        buttonX = buttonX + 100
    end

    if self.btnCancel then
        self.btnCancel:setX(buttonX)
        self.btnCancel:setY(footerY)
    end
end

function DC_BuildingProjectModal:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()
    local hasSupplyAction = self.preview and self.preview.projectID ~= nil
    local isBlueprintCraft = self.preview and self.preview.actionType == "CraftBlueprint"
    local actionButtonCount = 2
    if hasSupplyAction then
        actionButtonCount = actionButtonCount + 1
    end
    if self.debugEnabled == true then
        actionButtonCount = actionButtonCount + 1
    end
    local actionAreaWidth = (actionButtonCount * 90) + ((actionButtonCount - 1) * 10)

    local textBottomOffset = isBlueprintCraft and 48 or 78
    self.textPanel = ISRichTextPanel:new(10, th + 10, self.width - 20, self.height - th - textBottomOffset)
    self.textPanel:initialise()
    self.textPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.clip = true
    self.textPanel.autosetheight = false
    self.textPanel:addScrollBars()
    self:addChild(self.textPanel)

    if isBlueprintCraft ~= true then
        self.builderCombo = ISComboBox:new(10, self.height - 58, self.width - actionAreaWidth - 20, 24, self, self.onBuilderChanged)
        self.builderCombo:initialise()
        self:addChild(self.builderCombo)
    end

    local buttonX = self.width - actionAreaWidth - 10
    if self.debugEnabled == true then
        self.btnDebugMaterials = ISButton:new(buttonX, self.height - 58, 90, 24, "Debug Mats", self, self.onDebugMaterialsClicked)
        self.btnDebugMaterials:initialise()
        self:addChild(self.btnDebugMaterials)
        buttonX = buttonX + 100
    end

    if hasSupplyAction then
        self.btnSupplyProject = ISButton:new(buttonX, self.height - 58, 90, 24, "Supply", self, self.onSupplyClicked)
        self.btnSupplyProject:initialise()
        self:addChild(self.btnSupplyProject)
        buttonX = buttonX + 100
    end

    self.btnConfirm = ISButton:new(buttonX, self.height - 58, 90, 24, "Confirm", self, self.onConfirmClicked)
    self.btnConfirm:initialise()
    self:addChild(self.btnConfirm)

    self.btnCancel = ISButton:new(buttonX + 100, self.height - 58, 90, 24, "Cancel", self, self.onCancelClicked)
    self.btnCancel:initialise()
    self:addChild(self.btnCancel)

    self:refreshBuilderOptions()
    self:updateText()
    self:relayout()
end

function DC_BuildingProjectModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_BuildingProjectModal.instance == self then
        DC_BuildingProjectModal.instance = nil
    end
end
