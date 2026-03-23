require "ISUI/ISCollapsableWindow"
require "ISUI/ISRichTextPanel"
require "ISUI/ISComboBox"
require "ISUI/ISButton"
require "DT/UI/ZedColonies/Buildings/Models/DT_BuildingsClientSelectors"
require "DT/UI/ZedColonies/Buildings/Utils/DT_BuildingsUIUtils"

DT_BuildingProjectModal = ISCollapsableWindow:derive("DT_BuildingProjectModal")
DT_BuildingProjectModal.instance = DT_BuildingProjectModal.instance or nil

function DT_BuildingProjectModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DT_BuildingProjectModal:refreshBuilderOptions()
    self.builderOptions = DT_BuildingsClientSelectors.GetBuilderOptions()
    self.builderCombo:clear()
    for _, worker in ipairs(self.builderOptions or {}) do
        self.builderCombo:addOption(DT_BuildingsClientSelectors.BuildBuilderLabel(worker), worker)
    end
    self.builderCombo.selected = #(self.builderOptions or {}) > 0 and 1 or 0
end

function DT_BuildingProjectModal:getSelectedBuilder()
    local index = self.builderCombo and self.builderCombo.selected or 0
    if not index or index <= 0 then
        return nil
    end
    return self.builderOptions[index]
end

function DT_BuildingProjectModal:updateText()
    local preview = self.preview or {}
    local builder = self:getSelectedBuilder()
    local builderState = DT_BuildingsClientSelectors.GetBuilderRequirementState(builder)
    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> " .. tostring(preview.displayName or preview.buildingType or "Project") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Mode: <RGB:1,1,1> " .. tostring(preview.mode or "build") .. " <LINE> "
    if preview.mode == "install" then
        text = text .. " <RGB:0.72,0.72,0.72> Building Level: <RGB:1,1,1> " .. tostring(preview.targetLevel or 0) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Installed: <RGB:1,1,1> "
            .. tostring(preview.currentInstallCount or 0)
            .. " / "
            .. tostring(preview.maxInstallCount or 0)
            .. " <LINE> "
        if tonumber(preview.capacityPerInstall) and tonumber(preview.capacityPerInstall) > 0 then
            text = text .. " <RGB:0.72,0.72,0.72> Capacity Gain: <RGB:1,1,1> +" .. tostring(preview.capacityPerInstall or 0) .. " <LINE> "
        end
    else
        text = text .. " <RGB:0.72,0.72,0.72> Target Level: <RGB:1,1,1> " .. tostring(preview.targetLevel or 0) .. " <LINE> "
    end
    text = text .. " <RGB:0.72,0.72,0.72> Work Points: <RGB:1,1,1> " .. tostring(preview.workPoints or 0) .. " <LINE> "
    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Materials <LINE> "
    for _, line in ipairs(DT_BuildingsUIUtils.BuildRecipeLines(preview.recipeAvailability and preview.recipeAvailability.entries or {})) do
        text = text .. " " .. line .. " <LINE> "
    end
    if preview.canStart == true then
        text = text .. " <RGB:0.72,0.9,0.72> Materials ready. Construction can begin immediately. <LINE> "
    else
        text = text .. " <RGB:0.92,0.84,0.45> Missing materials will stall the project until supplies are added. <LINE> "
    end
    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Builder <LINE> "
    if builder then
        text = text .. " <RGB:0.72,0.72,0.72> Name: <RGB:1,1,1> " .. tostring(builder.name or builder.workerID or "Builder") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Construction: <RGB:1,1,1> Lv "
            .. tostring(DT_BuildingsClientSelectors.GetBuilderConstructionLevel(builder))
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Tools: <RGB:1,1,1> " .. tostring(builder.toolState or "Missing") .. " <LINE> "
    end
    if builderState.ready == true then
        text = text .. " <RGB:0.72,0.9,0.72> Builder Ready <LINE> "
    else
        text = text .. " <RGB:0.9,0.65,0.65> " .. tostring(builderState.reason or "Builder is not ready.") .. " <LINE> "
    end

    self.textPanel:setText(text)
    self.textPanel:paginate()
    self.btnConfirm:setTitle(preview.canStart == true and "Start" or "Queue")
    self.btnConfirm:setEnable(preview.available == true and builderState.ready == true)
end

function DT_BuildingProjectModal:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()

    self.textPanel = ISRichTextPanel:new(10, th + 10, self.width - 20, self.height - th - 78)
    self.textPanel:initialise()
    self.textPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.clip = true
    self.textPanel.autosetheight = false
    self.textPanel:addScrollBars()
    self:addChild(self.textPanel)

    self.builderCombo = ISComboBox:new(10, self.height - 58, self.width - 220, 24, self, self.onBuilderChanged)
    self.builderCombo:initialise()
    self:addChild(self.builderCombo)

    self.btnConfirm = ISButton:new(self.width - 200, self.height - 58, 90, 24, "Confirm", self, self.onConfirmClicked)
    self.btnConfirm:initialise()
    self:addChild(self.btnConfirm)

    self.btnCancel = ISButton:new(self.width - 100, self.height - 58, 90, 24, "Cancel", self, self.onCancelClicked)
    self.btnCancel:initialise()
    self:addChild(self.btnCancel)

    self:refreshBuilderOptions()
    self:updateText()
end

function DT_BuildingProjectModal:onBuilderChanged()
    self:updateText()
end

function DT_BuildingProjectModal:onConfirmClicked()
    local builder = self:getSelectedBuilder()
    if not builder or not self.onConfirmCallback then
        return
    end

    self.onConfirmCallback({
        workerID = builder.workerID,
        buildingType = self.preview.buildingType,
        mode = self.preview.mode,
        plotX = self.preview.plotX,
        plotY = self.preview.plotY,
        buildingID = self.preview.buildingID,
        installKey = self.preview.installKey
    })
    self:close()
end

function DT_BuildingProjectModal:onCancelClicked()
    self:close()
end

function DT_BuildingProjectModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DT_BuildingProjectModal.instance == self then
        DT_BuildingProjectModal.instance = nil
    end
end

function DT_BuildingProjectModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function DT_BuildingProjectModal.Open(args)
    args = args or {}
    if DT_BuildingProjectModal.instance then
        DT_BuildingProjectModal.instance:close()
    end

    local width = 480
    local height = 430
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local modal = DT_BuildingProjectModal:new(x, y, width, height)
    modal.title = tostring(args.title or "Project")
    modal.preview = args.preview or {}
    modal.onConfirmCallback = args.onConfirm
    modal.builderOptions = {}
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:bringToTop()
    DT_BuildingProjectModal.instance = modal
    return modal
end

return DT_BuildingProjectModal
