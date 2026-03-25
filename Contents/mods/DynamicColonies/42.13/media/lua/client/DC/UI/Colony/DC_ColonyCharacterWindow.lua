require "ISUI/ISCollapsableWindow"
require "DC/UI/Colony/DC_ColonySkillPanel"
require "DC/UI/Colony/DC_ColonyNeedsPanel"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_ColonyCharacterWindow = ISCollapsableWindow:derive("DC_ColonyCharacterWindow")
DC_ColonyCharacterWindow.instance = nil

local AUTO_REFRESH_FRAMES = 120

local function getColonyConfig()
    return (DC_Colony and DC_Colony.Config) or {}
end

local function getCommandModule()
    local config = getColonyConfig()
    if type(config) == "table" and config.COMMAND_MODULE and config.COMMAND_MODULE ~= "" then
        return config.COMMAND_MODULE
    end
    return "DColony"
end

local function resolveLiveWorker(workerID)
    if not workerID then
        return nil
    end

    local cache = DC_MainWindow and DC_MainWindow.cachedDetails or nil
    if type(cache) == "table" and type(cache[workerID]) == "table" then
        return cache[workerID]
    end

    local internal = DC_MainWindow and DC_MainWindow.Internal or nil
    if internal and type(internal.resolveWorkerDetail) == "function" then
        return internal.resolveWorkerDetail(workerID, { includeWorkerLedgers = false })
    end

    return nil
end

local function sendColonyCommand(command, args)
    local config = getColonyConfig()
    local player = type(config.GetPlayerObject) == "function" and config.GetPlayerObject() or nil
    if not player then
        return false
    end

    if isClient() and not isServer() then
        sendClientCommand(player, getCommandModule(), command, args or {})
        return true
    end

    if DC_Colony and DC_Colony.Network and DC_Colony.Network.HandleCommand then
        DC_Colony.Network.HandleCommand(player, command, args or {})
        return true
    end

    return false
end

function DC_ColonyCharacterWindow.OpenWorker(worker)
    if not worker or not worker.workerID then
        return
    end

    local window = DC_ColonyCharacterWindow.instance
    if not window then
        local width = 760
        local height = 700
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2
        window = DC_ColonyCharacterWindow:new(x, y, width, height)
        window:initialise()
        window:instantiate()
        DC_ColonyCharacterWindow.instance = window
    end

    window.workerID = worker.workerID
    window.title = "Character - " .. tostring(worker.name or worker.workerID)
    window:setVisible(true)
    window:addToUIManager()
    window:bringToTop()
    window.autoRefreshFrames = 0
    window:setWorkerData(resolveLiveWorker(worker.workerID) or worker)
    window:refreshLiveData(true)
end

function DC_ColonyCharacterWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.resizable = true
    o.workerID = nil
    o.activeTab = "skills"
    o.autoRefreshFrames = 0
    return o
end

function DC_ColonyCharacterWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(true)
end

function DC_ColonyCharacterWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    local tabsY = th + 10
    local tabsH = 24
    local contentY = tabsY + tabsH + 10
    local contentHeight = self.height - contentY - 10

    self.btnTabSkills = ISButton:new(10, tabsY, 96, tabsH, "Skills", self, self.onSelectSkillsTab)
    self.btnTabSkills:initialise()
    self:addChild(self.btnTabSkills)

    self.btnTabNeeds = ISButton:new(112, tabsY, 96, tabsH, "Needs", self, self.onSelectNeedsTab)
    self.btnTabNeeds:initialise()
    self:addChild(self.btnTabNeeds)

    self.skillPanel = DC_ColonySkillPanel:new(10, contentY, self.width - 20, contentHeight)
    self.skillPanel:initialise()
    self.skillPanel:setAnchorRight(true)
    self.skillPanel:setAnchorBottom(true)
    self:addChild(self.skillPanel)

    self.needsPanel = DC_ColonyNeedsPanel:new(10, contentY, self.width - 20, contentHeight)
    self.needsPanel:initialise()
    self.needsPanel:setAnchorRight(true)
    self.needsPanel:setAnchorBottom(true)
    self:addChild(self.needsPanel)

    self:setActiveTab(self.activeTab or "skills")
end

function DC_ColonyCharacterWindow:setWorkerData(worker)
    if worker then
        self.title = "Character - " .. tostring(worker.name or worker.workerID)
    end
    if self.skillPanel then
        self.skillPanel:setWorkerData(worker)
    end
    if self.needsPanel then
        self.needsPanel:setWorkerData(worker)
    end
end

function DC_ColonyCharacterWindow:refreshLiveData(forceRequest)
    if not self.workerID then
        return
    end

    local liveWorker = resolveLiveWorker(self.workerID)
    if liveWorker then
        self:setWorkerData(liveWorker)
    end

    if forceRequest and isClient() and not isServer() then
        self:requestWorkerDetails()
    end
end

function DC_ColonyCharacterWindow:refreshTabButtons()
    local activeTab = tostring(self.activeTab or "skills")
    local skillsActive = activeTab == "skills"
    local needsActive = activeTab == "needs"

    if self.btnTabSkills then
        self.btnTabSkills:setTitle(skillsActive and "[Skills]" or "Skills")
    end
    if self.btnTabNeeds then
        self.btnTabNeeds:setTitle(needsActive and "[Needs]" or "Needs")
    end
    if self.skillPanel then
        self.skillPanel:setVisible(skillsActive)
    end
    if self.needsPanel then
        self.needsPanel:setVisible(needsActive)
    end
end

function DC_ColonyCharacterWindow:setActiveTab(tabID)
    self.activeTab = (tabID == "needs") and "needs" or "skills"
    self:refreshTabButtons()
    self:refreshLiveData(true)
end

function DC_ColonyCharacterWindow:onSelectSkillsTab()
    self:setActiveTab("skills")
end

function DC_ColonyCharacterWindow:onSelectNeedsTab()
    self:setActiveTab("needs")
end

function DC_ColonyCharacterWindow:requestWorkerDetails()
    if not self.workerID then
        return
    end

    sendColonyCommand("RequestWorkerDetails", {
        workerID = self.workerID,
        knownVersion = DC_MainWindow and DC_MainWindow.cachedDetailVersions and DC_MainWindow.cachedDetailVersions[self.workerID] or nil,
        includeWorkerLedgers = false
    })
end

function DC_ColonyCharacterWindow:prerender()
    ISCollapsableWindow.prerender(self)

    if not self:getIsVisible() or not self.workerID then
        return
    end

    self.autoRefreshFrames = (tonumber(self.autoRefreshFrames) or 0) + 1
    if self.autoRefreshFrames >= AUTO_REFRESH_FRAMES then
        self.autoRefreshFrames = 0
        self:refreshLiveData(true)
    end
end

function DC_ColonyCharacterWindow:close()
    self.autoRefreshFrames = 0
    self:setVisible(false)
    self:removeFromUIManager()
end
