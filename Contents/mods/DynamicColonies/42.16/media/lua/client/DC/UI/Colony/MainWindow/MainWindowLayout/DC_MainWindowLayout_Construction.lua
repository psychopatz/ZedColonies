DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
local MainWindowLayout = Internal.MainWindowLayout or {}

local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return fallback or key
end

local function canUseDebug()
    if DC_System and DC_System.CanUseDebug then
        return DC_System.CanUseDebug()
    end

    local player = nil
    if getSpecificPlayer then
        player = getSpecificPlayer(0)
    elseif getPlayer then
        player = getPlayer()
    end

    local accessLevel = nil
    if player and player.getAccessLevel then
        accessLevel = player:getAccessLevel()
    end
    local hasElevatedAccess = accessLevel and accessLevel ~= "" and accessLevel ~= "None"
    local isSinglePlayer = (not isClient or not isClient()) and not hasElevatedAccess

    if isSinglePlayer then
        return isDebugEnabled and isDebugEnabled() == true
    end

    if DynamicTrading and DynamicTrading.Debug then
        return true
    end
    if isDebugEnabled and isDebugEnabled() then
        return true
    end
    if hasElevatedAccess then
        return true
    end
    return false
end

local DEFAULT_ACTION_BUTTON_COLOR = { r = 0, g = 0, b = 0, a = 1 }
local DEFAULT_ACTION_BUTTON_HOVER_COLOR = { r = 0.18, g = 0.18, b = 0.18, a = 1 }
local DEFAULT_ACTION_BUTTON_BORDER = { r = 1, g = 1, b = 1, a = 0.1 }

function MainWindowLayout.applyToggleButtonStyle(button, isDanger)
    if not button then
        return
    end

    if isDanger then
        button.backgroundColor = { r = 0.45, g = 0.08, b = 0.08, a = 1 }
        button.backgroundColorMouseOver = { r = 0.62, g = 0.12, b = 0.12, a = 1 }
        button.borderColor = { r = 1, g = 0.35, b = 0.35, a = 0.35 }
        return
    end

    button.backgroundColor = {
        r = DEFAULT_ACTION_BUTTON_COLOR.r,
        g = DEFAULT_ACTION_BUTTON_COLOR.g,
        b = DEFAULT_ACTION_BUTTON_COLOR.b,
        a = DEFAULT_ACTION_BUTTON_COLOR.a
    }
    button.backgroundColorMouseOver = {
        r = DEFAULT_ACTION_BUTTON_HOVER_COLOR.r,
        g = DEFAULT_ACTION_BUTTON_HOVER_COLOR.g,
        b = DEFAULT_ACTION_BUTTON_HOVER_COLOR.b,
        a = DEFAULT_ACTION_BUTTON_HOVER_COLOR.a
    }
    button.borderColor = {
        r = DEFAULT_ACTION_BUTTON_BORDER.r,
        g = DEFAULT_ACTION_BUTTON_BORDER.g,
        b = DEFAULT_ACTION_BUTTON_BORDER.b,
        a = DEFAULT_ACTION_BUTTON_BORDER.a
    }
end

-- Header Panel Class
DC_MainWindowHeaderPanel = ISPanel:derive("DC_MainWindowHeaderPanel")

function DC_MainWindowHeaderPanel:createChildren()
    ISPanel.createChildren(self)

    local btnSize = 18
    self.btnOptions = ISButton:new(self.width - btnSize - 10, 5, btnSize, btnSize, "", self, function()
        if DT_V2_OptionsManager and DT_V2_OptionsManager.ToggleWindow then
            DT_V2_OptionsManager.ToggleWindow()
        end
    end)
    self.btnOptions:initialise()
    self.btnOptions.borderColor = { r = 1, g = 1, b = 1, a = 0.2 }
    self.btnOptions.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.btnOptions:setImage(getTexture("media/ui/inventoryPanes/Button_Settings.png"))
    self.btnOptions.displayBackground = false
    self:addChild(self.btnOptions)

    self.btnHelpIcon = ISButton:new(self.width - (btnSize * 2) - 15, 5, btnSize, btnSize, "", self, function()
        if self.parent and self.parent.onOpenHelp then
            self.parent:onOpenHelp()
        end
    end)
    self.btnHelpIcon:initialise()
    self.btnHelpIcon.borderColor = { r = 1, g = 1, b = 1, a = 0.2 }
    self.btnHelpIcon.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.btnHelpIcon:setImage(getTexture("media/ui/Entity/BTN_Missing_Icon_48x48.png"))
    self.btnHelpIcon.displayBackground = false
    self:addChild(self.btnHelpIcon)
end

function DC_MainWindowHeaderPanel:prerender()
    ISPanel.prerender(self)
    local th = 0 -- Relative to panel
    self:drawTextCentre(T("DCCommon_UI_MainWindow_Header", "LABOUR MANAGEMENT"), self.width / 2, 6, 1, 1, 1, 1, UIFont.Large)

    if self.btnOptions then
        self.btnOptions:setX(self.width - self.btnOptions:getWidth() - 10)
    end
    if self.btnHelpIcon then
        local offset = self.btnOptions and (self.btnOptions:getWidth() + 5) or 0
        self.btnHelpIcon:setX(self.width - self.btnHelpIcon:getWidth() - 10 - offset)
    end
end

function DC_MainWindowHeaderPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function DC_MainWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    local pad = 10
    local headerH = 34
    
    self.headerPanel = DC_MainWindowHeaderPanel:new(0, th, self.width, headerH)
    self.headerPanel:initialise()
    self.headerPanel:setAnchorRight(true)
    self:addChild(self.headerPanel)

    local headerY = th + headerH + pad
    local buttonY = headerY
    local listY = headerY + 38
    local footerH = 38
    local listWidth = 280
    local reserveH = 250
    local contentHeight = self.height - listY - footerH - pad
    local rightX = listWidth + (pad * 2)
    local rightWidth = self.width - rightX - pad
    local detailY = listY + reserveH + pad
    local detailHeight = math.max(
        MainWindowLayout.DETAIL_PANEL_MIN_HEIGHT,
        math.floor((self.height - detailY - footerH - pad - 8) * 0.38)
    )
    local activityY = detailY + detailHeight + 8
    local activityHeight = math.max(MainWindowLayout.ACTIVITY_PANEL_MIN_HEIGHT, self.height - activityY - footerH - pad)

    self.btnRefresh = ISButton:new(10, buttonY, 90, 28, T("DCCommon_UI_MainWindow_Refresh", "Refresh"), self, self.onRefresh)
    self.btnRefresh:initialise()
    self:addChild(self.btnRefresh)

    self.btnToggleJob = ISButton:new(110, buttonY, 120, 28, T("DCCommon_UI_MainWindow_StartDuty", "Start Duty"), self, self.onToggleJob)
    self.btnToggleJob:initialise()
    MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, false)
    self:addChild(self.btnToggleJob)

    self.btnWarehouse = ISButton:new(240, buttonY, 110, 28, T("DCCommon_UI_MainWindow_Warehouse", "Warehouse"), self, self.onOpenWarehouse)
    self.btnWarehouse:initialise()
    self.btnWarehouse:setEnable(false)
    self:addChild(self.btnWarehouse)

    self.btnResources = ISButton:new(360, buttonY, 110, 28, T("DCCommon_UI_MainWindow_Resources", "Resources"), self, self.onOpenResources)
    self.btnResources:initialise()
    self:addChild(self.btnResources)

    self.btnBuildings = ISButton:new(480, buttonY, 110, 28, T("DCCommon_UI_MainWindow_ColonyMap", "Colony Map"), self, self.onOpenBuildings)
    self.btnBuildings:initialise()
    self:addChild(self.btnBuildings)

    self.btnResetNPCs = ISButton:new(600, buttonY, 100, 28, T("DCCommon_UI_MainWindow_ResetNPCs", "Reset NPCs"), self, self.onResetNPCs)
    self.btnResetNPCs:initialise()
    MainWindowLayout.applyToggleButtonStyle(self.btnResetNPCs, true)
    self:addChild(self.btnResetNPCs)

    if canUseDebug() then
        self.btnDebugArchive = ISButton:new(710, buttonY, 70, 28, T("DCCommon_UI_MainWindow_Debug", "Debug"), self, self.onOpenDebugArchive)
        self.btnDebugArchive:initialise()
        self:addChild(self.btnDebugArchive)
    end

    self.btnFaction = ISButton:new(790, buttonY, 150, 28, T("DCCommon_UI_MainWindow_Faction", "Faction"), self, self.onOpenFaction)
    self.btnFaction:initialise()
    self:addChild(self.btnFaction)

    self.btnCompanionCommand = ISButton:new(950, buttonY, 110, 28, T("DCCommon_UI_MainWindow_Command", "Command"), self, self.onCompanionCommand)
    self.btnCompanionCommand:initialise()
    self.btnCompanionCommand:setEnable(false)
    self:addChild(self.btnCompanionCommand)

    self.workerList = Internal.ColonyWorkerList:new(10, listY, listWidth, contentHeight)
    self.workerList:initialise()
    self.workerList:instantiate()
    self.workerList.target = self
    self.workerList.onmousedown = DC_MainWindow.onWorkerListMouseDown
    self.workerList:setAnchorLeft(true)
    self.workerList:setAnchorTop(true)
    self.workerList:setAnchorBottom(true)
    self:addChild(self.workerList)

    self.reservePanel = Internal.ColonyReservePanel:new(rightX, listY, rightWidth, reserveH)
    self.reservePanel:initialise()
    if self.reservePanel.setOwnerWindow then
        self.reservePanel:setOwnerWindow(self)
    end
    self.reservePanel:setAnchorRight(true)
    self:addChild(self.reservePanel)

    self.btnCycleJob = ISButton:new(0, 0, 96, 24, T("DCCommon_UI_MainWindow_ChangeJob", "Change Job"), self, self.onCycleJob)
    self.btnCycleJob:initialise()
    self.btnCycleJob:setEnable(false)
    self.reservePanel:addChild(self.btnCycleJob)

    self.btnCompanionLootConfig = ISButton:new(0, 0, 96, 24, T("DCCommon_UI_MainWindow_LootSetup", "Loot Setup"), self, self.onOpenCompanionLootConfig)
    self.btnCompanionLootConfig:initialise()
    self.btnCompanionLootConfig:setEnable(false)
    self.reservePanel:addChild(self.btnCompanionLootConfig)

    self.detailPanel = ISPanel:new(rightX, detailY, rightWidth, detailHeight)
    self.detailPanel:initialise()
    self.detailPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    self.detailPanel.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
    self.detailPanel:setAnchorRight(true)
    self.detailPanel.prerender = function(panel)
        ISPanel.prerender(panel)
        panel:drawText(T("DCCommon_UI_MainWindow_Details", "Details"), 8, 6, 1, 1, 1, 1, UIFont.Medium)
    end
    self:addChild(self.detailPanel)

    self.detailText = ISRichTextPanel:new(
        MainWindowLayout.PANEL_INNER_PAD,
        MainWindowLayout.PANEL_HEADER_HEIGHT,
        rightWidth - (MainWindowLayout.PANEL_INNER_PAD * 2),
        detailHeight - MainWindowLayout.PANEL_HEADER_HEIGHT - MainWindowLayout.PANEL_INNER_PAD
    )
    self.detailText:initialise()
    self.detailText.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.detailText.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.detailText.autosetheight = false
    self.detailText.clip = true
    self.detailText:setMargins(0, 0, 0, 0)
    self.detailText:addScrollBars()
    if self.detailText.vscroll then
        self.detailText.vscroll:setHeight(self.detailText:getHeight())
    end
    self.detailPanel:addChild(self.detailText)

    self.activityLogPanel = ISPanel:new(rightX, activityY, rightWidth, activityHeight)
    self.activityLogPanel:initialise()
    self.activityLogPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    self.activityLogPanel.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
    self.activityLogPanel:setAnchorRight(true)
    self.activityLogPanel:setAnchorBottom(true)
    self.activityLogPanel.prerender = function(panel)
        ISPanel.prerender(panel)
        panel:drawText(T("DCCommon_UI_MainWindow_ActivityLog", "Activity Log"), 8, 6, 1, 1, 1, 1, UIFont.Medium)
    end
    self:addChild(self.activityLogPanel)

    self.activityLogText = ISRichTextPanel:new(
        MainWindowLayout.PANEL_INNER_PAD,
        MainWindowLayout.PANEL_HEADER_HEIGHT,
        rightWidth - (MainWindowLayout.PANEL_INNER_PAD * 2),
        activityHeight - MainWindowLayout.PANEL_HEADER_HEIGHT - MainWindowLayout.PANEL_INNER_PAD
    )
    self.activityLogText:initialise()
    self.activityLogText.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.activityLogText.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.activityLogText.autosetheight = false
    self.activityLogText.clip = true
    self.activityLogText:setMargins(0, 0, 0, 0)
    self.activityLogText:addScrollBars()
    if self.activityLogText.vscroll then
        self.activityLogText.vscroll:setHeight(self.activityLogText:getHeight())
    end
    self.activityLogPanel:addChild(self.activityLogText)

    self.statusText = ISRichTextPanel:new(rightX, self.height - footerH - 4, rightWidth, 28)
    self.statusText:initialise()
    self.statusText.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.statusText.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.statusText:setAnchorRight(true)
    self.statusText:setAnchorBottom(true)
    self:addChild(self.statusText)

    MainWindowLayout.applyWindowLayout(self)
    self:updateStatus(T("DCCommon_UI_MainWindow_Ready", "Colony Management ready. Jobs are tool-gated, workplaces are deferred, and Help explains the scavenging system."))
    self:populateWorkerList(DC_MainWindow.cachedWorkers or {})
    if self.updateFactionButton then
        self:updateFactionButton()
    end
end
