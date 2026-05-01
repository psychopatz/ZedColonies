require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "DC/Common/Colony/Job/Gatherer/DC_Job_Gatherer_Config"

DC_GathererConfigModal = ISCollapsableWindow:derive("DC_GathererConfigModal")
DC_GathererConfigModal.instance = nil

local ROW_HEIGHT = 42

local function copySelected(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value == true
    end
    return copy
end

local function countSelected(selected)
    local count = 0
    for _, enabled in pairs(selected or {}) do
        if enabled == true then
            count = count + 1
        end
    end
    return count
end

function DC_GathererConfigModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_GathererConfigModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 10
    local th = self:titleBarHeight()
    local y = th + pad

    self.promptLabel = ISLabel:new(pad, y, 20, tostring(self.promptText or "Choose resources to gather."), 1, 1, 1, 1, UIFont.Small, true)
    self.promptLabel:initialise()
    self.promptLabel:instantiate()
    self:addChild(self.promptLabel)
    y = y + 28

    self.resourceButtons = {}
    for _, resource in ipairs(self.resources or {}) do
        local rowY = y
        local selected = self.selectedResources[resource.id] == true
        local title = (selected and "[x] " or "[ ] ") .. tostring(resource.label or resource.id)
        local button = ISButton:new(pad, rowY, 150, 26, title, self, self.onToggleResource)
        button:initialise()
        button:instantiate()
        button.resourceID = resource.id
        self:addChild(button)

        local description = tostring(resource.description or "")
        local descLabel = ISLabel:new(pad + 162, rowY + 3, 20, description, 0.75, 0.75, 0.75, 1, UIFont.Small, true)
        descLabel:initialise()
        descLabel:instantiate()
        self:addChild(descLabel)

        self.resourceButtons[resource.id] = button
        y = y + ROW_HEIGHT
    end

    self.statusLabel = ISLabel:new(pad, y, 20, "", 0.9, 0.72, 0.38, 1, UIFont.Small, true)
    self.statusLabel:initialise()
    self.statusLabel:instantiate()
    self:addChild(self.statusLabel)

    local buttonY = self.height - 36
    self.btnSave = ISButton:new(pad, buttonY, 90, 24, "Save", self, self.onSave)
    self.btnSave:initialise()
    self.btnSave:instantiate()
    self:addChild(self.btnSave)

    self.btnCancel = ISButton:new(self.width - 100, buttonY, 90, 24, "Cancel", self, self.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self:addChild(self.btnCancel)

    self:updateResourceButtons()
end

function DC_GathererConfigModal:updateResourceButtons()
    for _, resource in ipairs(self.resources or {}) do
        local button = self.resourceButtons and self.resourceButtons[resource.id] or nil
        if button then
            local selected = self.selectedResources[resource.id] == true
            button:setTitle((selected and "[x] " or "[ ] ") .. tostring(resource.label or resource.id))
        end
    end

    local selectedCount = countSelected(self.selectedResources)
    if self.btnSave then
        self.btnSave:setEnable(selectedCount > 0)
    end
    if self.statusLabel then
        self.statusLabel:setName(selectedCount > 0 and ("Selected resources: " .. tostring(selectedCount)) or "Select at least one resource.")
    end
end

function DC_GathererConfigModal:onToggleResource(button)
    if not button or not button.resourceID then
        return
    end
    local id = tostring(button.resourceID)
    self.selectedResources[id] = self.selectedResources[id] ~= true
    self:updateResourceButtons()
end

function DC_GathererConfigModal:onSave()
    if countSelected(self.selectedResources) <= 0 then
        self:updateResourceButtons()
        return
    end

    local config = {
        selectedResources = copySelected(self.selectedResources)
    }
    if self.onSaveCallback then
        self.onSaveCallback(config)
    end
    self:close()
end

function DC_GathererConfigModal:onCancel()
    self:close()
end

function DC_GathererConfigModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_GathererConfigModal.instance == self then
        DC_GathererConfigModal.instance = nil
    end
end

function DC_GathererConfigModal.Open(args)
    args = args or {}
    local gatherer = DC_Colony and DC_Colony.Gatherer or nil
    if not gatherer or not gatherer.GetResourceList or not gatherer.NormalizeConfig then
        return nil
    end

    if DC_GathererConfigModal.instance then
        DC_GathererConfigModal.instance:close()
    end

    local resources = gatherer.GetResourceList()
    if #resources <= 0 then
        return nil
    end

    local width = 620
    local height = math.max(190, 112 + (#resources * ROW_HEIGHT))
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local normalized = gatherer.NormalizeConfig(args.config or args.worker or {})

    local modal = DC_GathererConfigModal:new(x, y, width, height)
    modal.title = tostring(args.title or "Gatherer Setup")
    modal.promptText = tostring(args.promptText or "Choose what this worker should gather.")
    modal.worker = args.worker
    modal.resources = resources
    modal.selectedResources = copySelected(normalized.selectedResources)
    modal.onSaveCallback = args.onSave
    modal:initialise()
    modal:instantiate()
    modal:setVisible(true)
    modal:addToUIManager()
    modal:bringToTop()

    DC_GathererConfigModal.instance = modal
    return modal
end

function DC_GathererConfigModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Gatherer Setup"
    o.resizable = false
    o.promptText = "Choose what this worker should gather."
    o.resources = {}
    o.selectedResources = {}
    o.onSaveCallback = nil
    return o
end

return DC_GathererConfigModal
