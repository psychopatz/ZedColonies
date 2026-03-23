require "ISUI/ISCollapsableWindow"
require "DT/UI/ZedColonies/DT_LabourSkillPanel"
require "DT/UI/ZedColonies/DT_LabourNeedsPanel"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"

DT_LabourCharacterWindow = ISCollapsableWindow:derive("DT_LabourCharacterWindow")
DT_LabourCharacterWindow.instance = nil

local AUTO_REFRESH_FRAMES = 120

local function getLabourConfig()
    return (DT_Labour and DT_Labour.Config) or {}
end

local function resolveLiveWorker(workerID)
    if not workerID then
        return nil
    end

    local cache = DT_MainWindow and DT_MainWindow.cachedDetails or nil
    if type(cache) == "table" and type(cache[workerID]) == "table" then
        return cache[workerID]
    end

    local internal = DT_MainWindow and DT_MainWindow.Internal or nil
    if internal and type(internal.resolveWorkerDetail) == "function" then
        return internal.resolveWorkerDetail(workerID)
    end

    return nil
end

local function sendLabourCommand(command, args)
    local config = getLabourConfig()
    local player = type(config.GetPlayerObject) == "function" and config.GetPlayerObject() or nil
    if not player then
        return false
    end

    if isClient() and not isServer() then
        sendClientCommand(player, "DynamicTrading_V2", command, args or {})
        return true
    end

    if DT_Labour and DT_Labour.Network and DT_Labour.Network.HandleCommand then
        DT_Labour.Network.HandleCommand(player, command, args or {})
        return true
    end

    return false
end

function DT_LabourCharacterWindow.OpenWorker(worker)
    if not worker or not worker.workerID then
        return
    end

    local window = DT_LabourCharacterWindow.instance
    if not window then
        local width = 760
        local height = 700
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2
        window = DT_LabourCharacterWindow:new(x, y, width, height)
        window:initialise()
        window:instantiate()
        DT_LabourCharacterWindow.instance = window
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

function DT_LabourCharacterWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.resizable = true
    o.workerID = nil
    o.activeTab = "skills"
    o.autoRefreshFrames = 0
    return o
end

function DT_LabourCharacterWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(true)
end

function DT_LabourCharacterWindow:createChildren()
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

    self.skillPanel = DT_LabourSkillPanel:new(10, contentY, self.width - 20, contentHeight)
    self.skillPanel:initialise()
    self.skillPanel:setAnchorRight(true)
    self.skillPanel:setAnchorBottom(true)
    self:addChild(self.skillPanel)

    self.needsPanel = DT_LabourNeedsPanel:new(10, contentY, self.width - 20, contentHeight)
    self.needsPanel:initialise()
    self.needsPanel:setAnchorRight(true)
    self.needsPanel:setAnchorBottom(true)
    self:addChild(self.needsPanel)

    self:setActiveTab(self.activeTab or "skills")
end

function DT_LabourCharacterWindow:setWorkerData(worker)
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

function DT_LabourCharacterWindow:refreshLiveData(forceRequest)
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

function DT_LabourCharacterWindow:refreshTabButtons()
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

function DT_LabourCharacterWindow:setActiveTab(tabID)
    self.activeTab = (tabID == "needs") and "needs" or "skills"
    self:refreshTabButtons()
    self:refreshLiveData(true)
end

function DT_LabourCharacterWindow:onSelectSkillsTab()
    self:setActiveTab("skills")
end

function DT_LabourCharacterWindow:onSelectNeedsTab()
    self:setActiveTab("needs")
end

function DT_LabourCharacterWindow:requestWorkerDetails()
    if not self.workerID then
        return
    end

    sendLabourCommand("RequestWorkerDetails", {
        workerID = self.workerID,
        includeWarehouseLedgers = false
    })
end

function DT_LabourCharacterWindow:prerender()
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

function DT_LabourCharacterWindow:close()
    self.autoRefreshFrames = 0
    self:setVisible(false)
    self:removeFromUIManager()
end
