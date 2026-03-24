require "ISUI/ISCollapsableWindow"
require "ISUI/ISRichTextPanel"
require "ISUI/ISComboBox"
require "ISUI/ISButton"
require "DC/UI/Colony/Buildings/Models/DC_BuildingsClientSelectors"
require "DC/UI/Colony/Buildings/Utils/DC_BuildingsUIUtils"

DC_BuildingProjectModal = ISCollapsableWindow:derive("DC_BuildingProjectModal")
DC_BuildingProjectModal.instance = DC_BuildingProjectModal.instance or nil

local function canUseDebug()
    if DynamicTrading and DynamicTrading.Debug then
        return true
    end

    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    local player = nil
    if getSpecificPlayer then
        player = getSpecificPlayer(0)
    elseif getPlayer then
        player = getPlayer()
    end

    if player and player.getAccessLevel then
        local accessLevel = player:getAccessLevel()
        if accessLevel and accessLevel ~= "" and accessLevel ~= "None" then
            return true
        end
    end

    return false
end

function DC_BuildingProjectModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_BuildingProjectModal:refreshBuilderOptions()
    self.builderOptions = DC_BuildingsClientSelectors.GetBuilderOptions()
    self.builderCombo:clear()
    for _, worker in ipairs(self.builderOptions or {}) do
        self.builderCombo:addOption(DC_BuildingsClientSelectors.BuildBuilderLabel(worker, {
            allowedProjectID = self.preview and self.preview.projectID or nil
        }), worker)
    end
    local selectedIndex = self.requireBuilder == true and (#(self.builderOptions or {}) > 0 and 1 or 0) or 0
    local previewProjectID = tostring(self.preview and self.preview.projectID or "")
    local assignedBuilderID = tostring(self.preview and self.preview.assignedBuilderID or "")
    if previewProjectID ~= "" and assignedBuilderID ~= "" then
        for index, worker in ipairs(self.builderOptions or {}) do
            if tostring(worker and worker.workerID or "") == assignedBuilderID then
                selectedIndex = index
                break
            end
        end
    end
    self.builderCombo.selected = selectedIndex
end

function DC_BuildingProjectModal:getSelectedBuilder()
    local index = self.builderCombo and self.builderCombo.selected or 0
    if not index or index <= 0 then
        return nil
    end
    return self.builderOptions[index]
end

function DC_BuildingProjectModal:updateText()
    local preview = self.preview or {}
    local builder = self:getSelectedBuilder()
    local builderState = DC_BuildingsClientSelectors.GetBuilderRequirementState(builder, {
        allowedProjectID = preview.projectID
    })
    local requireBuilder = self.requireBuilder == true
    local willStartImmediately = preview.canStart == true and builderState.ready == true
    local willQueue = requireBuilder ~= true and willStartImmediately ~= true
    local recipeEntries = preview.recipeAvailability and preview.recipeAvailability.entries or preview.materialEntries or {}
    local hasAvailableUnsuppliedMaterials = false
    local hasMissingMaterials = false
    for _, entry in ipairs(recipeEntries) do
        local remaining = math.max(0, tonumber(entry and entry.remaining) or 0)
        local available = math.max(0, tonumber(entry and entry.available) or 0)
        if remaining > 0 then
            if available > 0 then
                hasAvailableUnsuppliedMaterials = true
            else
                hasMissingMaterials = true
            end
        end
    end
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
    text = text .. " <RGB:0.72,0.72,0.72> Work Points: <RGB:1,1,1> " .. tostring(preview.workPoints or preview.requiredWorkPoints or 0) .. " <LINE> "
    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Materials <LINE> "
    for _, line in ipairs(DC_BuildingsUIUtils.BuildRecipeLines(recipeEntries)) do
        text = text .. " " .. line .. " <LINE> "
    end
    if preview.canStart == true then
        text = text .. " <RGB:0.72,0.9,0.72> Materials ready. Construction can begin immediately. <LINE> "
    elseif hasMissingMaterials then
        text = text .. " <RGB:0.92,0.84,0.45> Missing materials will stall the project until supplies are added. <LINE> "
    elseif hasAvailableUnsuppliedMaterials then
        text = text .. " <RGB:0.92,0.84,0.45> Required materials are available to supply, but this project is not fully supplied yet. Use Supply for player inventory items or wait for warehouse stock to be pulled in. <LINE> "
    else
        text = text .. " <RGB:0.92,0.84,0.45> Materials still need to be supplied before work can continue. <LINE> "
    end
    if preview.projectID then
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Current Builder <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Assigned: <RGB:1,1,1> "
            .. tostring(preview.assignedBuilderName or preview.assignedBuilderID or "Unassigned")
            .. " <LINE> "
        text = text .. " <RGB:0.82,0.82,0.82> Select another Builder below and press Save to apply changes without resetting progress. <LINE> "
    end
    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Builder <LINE> "
    if builder then
        text = text .. " <RGB:0.72,0.72,0.72> Name: <RGB:1,1,1> " .. tostring(builder.name or builder.workerID or "Builder") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Construction: <RGB:1,1,1> Lv "
            .. tostring(DC_BuildingsClientSelectors.GetBuilderConstructionLevel(builder))
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Tools: <RGB:1,1,1> " .. tostring(builder.toolState or "Missing") .. " <LINE> "
    end
    if builderState.ready == true then
        text = text .. " <RGB:0.72,0.9,0.72> Builder Ready <LINE> "
    elseif requireBuilder ~= true and builder == nil then
        text = text .. " <RGB:0.82,0.82,0.82> No builder assigned yet. Confirming will queue this project until you assign one. <LINE> "
    elseif requireBuilder ~= true then
        text = text .. " <RGB:0.92,0.84,0.45> "
            .. tostring(builderState.reason or "Selected builder is not ready.")
            .. " The project can still be queued without assigning them yet. <LINE> "
    else
        text = text .. " <RGB:0.9,0.65,0.65> " .. tostring(builderState.reason or "Builder is not ready.") .. " <LINE> "
    end
    if willStartImmediately then
        text = text .. " <RGB:0.72,0.9,0.72> Confirming will start work immediately. <LINE> "
    elseif willQueue then
        text = text .. " <RGB:0.82,0.82,0.82> Confirming will queue this project. It will wait for materials and/or a builder before work begins. <LINE> "
    end

    self.textPanel:setText(text)
    self.textPanel:paginate()
    if self.confirmLabelOverride and self.confirmLabelOverride ~= "" then
        self.btnConfirm:setTitle(self.confirmLabelOverride)
    else
        self.btnConfirm:setTitle(willStartImmediately and "Start" or "Queue")
    end
    self.btnConfirm.backgroundColor = { r = 0.12, g = 0.42, b = 0.16, a = 1 }
    self.btnConfirm.backgroundColorMouseOver = { r = 0.16, g = 0.56, b = 0.22, a = 1 }
    self.btnConfirm.borderColor = { r = 0.28, g = 0.72, b = 0.34, a = 0.9 }
    self.btnConfirm:setEnable(preview.available == true and (builderState.ready == true or requireBuilder ~= true))
    if self.btnSupplyProject then
        self.btnSupplyProject:setEnable(preview.projectID ~= nil and preview.canStart ~= true)
    end
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

function DC_BuildingProjectModal:onBuilderChanged()
    self:updateText()
end

function DC_BuildingProjectModal:onConfirmClicked()
    local builder = self:getSelectedBuilder()
    local builderState = DC_BuildingsClientSelectors.GetBuilderRequirementState(builder, {
        allowedProjectID = self.preview and self.preview.projectID or nil
    })
    local requireBuilder = self.requireBuilder == true
    if not self.onConfirmCallback then
        return
    end
    if requireBuilder == true and builderState.ready ~= true then
        return
    end

    self.onConfirmCallback({
        workerID = builderState.ready == true and builder and builder.workerID or nil,
        projectID = self.preview.projectID,
        buildingType = self.preview.buildingType,
        mode = self.preview.mode,
        plotX = self.preview.plotX,
        plotY = self.preview.plotY,
        buildingID = self.preview.buildingID,
        installKey = self.preview.installKey
    })
    self:close()
end

function DC_BuildingProjectModal:onDebugMaterialsClicked()
    if not self.onDebugMaterialsCallback then
        return
    end

    self.onDebugMaterialsCallback({
        projectID = self.preview.projectID,
        buildingType = self.preview.buildingType,
        mode = self.preview.mode,
        plotX = self.preview.plotX,
        plotY = self.preview.plotY,
        buildingID = self.preview.buildingID,
        installKey = self.preview.installKey
    })
end

function DC_BuildingProjectModal:onSupplyClicked()
    if not self.onSupplyCallback or not self.preview or not self.preview.projectID then
        return
    end

    self.onSupplyCallback({
        projectID = self.preview.projectID,
        buildingType = self.preview.buildingType,
        mode = self.preview.mode,
        plotX = self.preview.plotX,
        plotY = self.preview.plotY,
        buildingID = self.preview.buildingID,
        installKey = self.preview.installKey
    })
end

function DC_BuildingProjectModal:onCancelClicked()
    self:close()
end

function DC_BuildingProjectModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_BuildingProjectModal.instance == self then
        DC_BuildingProjectModal.instance = nil
    end
end

function DC_BuildingProjectModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function DC_BuildingProjectModal.Open(args)
    args = args or {}
    if DC_BuildingProjectModal.instance then
        DC_BuildingProjectModal.instance:close()
    end

    local width = 760
    local height = 470
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local modal = DC_BuildingProjectModal:new(x, y, width, height)
    modal.title = tostring(args.title or "Project")
    modal.preview = args.preview or {}
    modal.onConfirmCallback = args.onConfirm
    modal.onSupplyCallback = args.onSupply
    modal.onDebugMaterialsCallback = args.onDebugMaterials
    modal.confirmLabelOverride = args.confirmLabel
    modal.requireBuilder = args.requireBuilder == true
    modal.debugEnabled = canUseDebug()
    modal.builderOptions = {}
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:bringToTop()
    DC_BuildingProjectModal.instance = modal
    return modal
end

return DC_BuildingProjectModal
