function DC_BuildingProjectModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_BuildingProjectModal:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()
    local hasSupplyAction = self.preview and self.preview.projectID ~= nil
    local actionButtonCount = 2
    if hasSupplyAction then
        actionButtonCount = actionButtonCount + 1
    end
    if self.debugEnabled == true then
        actionButtonCount = actionButtonCount + 1
    end
    local actionAreaWidth = (actionButtonCount * 90) + ((actionButtonCount - 1) * 10)

    self.textPanel = ISRichTextPanel:new(10, th + 10, self.width - 20, self.height - th - 78)
    self.textPanel:initialise()
    self.textPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.clip = true
    self.textPanel.autosetheight = false
    self.textPanel:addScrollBars()
    self:addChild(self.textPanel)

    self.builderCombo = ISComboBox:new(10, self.height - 58, self.width - actionAreaWidth - 20, 24, self, self.onBuilderChanged)
    self.builderCombo:initialise()
    self:addChild(self.builderCombo)

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
end

function DC_BuildingProjectModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_BuildingProjectModal.instance == self then
        DC_BuildingProjectModal.instance = nil
    end
end
