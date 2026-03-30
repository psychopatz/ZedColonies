require "ISUI/ISPanel"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "DC/UI/Colony/Buildings/Details/DC_BuildingsDetailsFormatter"

DC_BuildingsDetailsPanel = ISPanel:derive("DC_BuildingsDetailsPanel")

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

function DC_BuildingsDetailsPanel:initialise()
    ISPanel.initialise(self)
end

function DC_BuildingsDetailsPanel:relayout()
    local textPanelHeight = self.height - (self.debugEnabled == true and 78 or 50)
    if self.textPanel then
        self.textPanel:setX(8)
        self.textPanel:setY(8)
        self.textPanel:setWidth(math.max(0, self.width - 16))
        self.textPanel:setHeight(math.max(0, textPanelHeight))
        if self.textPanel.vscroll then
            self.textPanel.vscroll:setHeight(self.textPanel:getHeight())
        end
    end
    if self.btnDebugComplete then
        self.btnDebugComplete:setX(8)
        self.btnDebugComplete:setY(self.height - 62)
        self.btnDebugComplete:setWidth(96)
        self.btnDebugComplete:setHeight(24)
    end
    if self.btnUpgrade then
        self.btnUpgrade:setX(8)
        self.btnUpgrade:setY(self.height - 34)
        self.btnUpgrade:setWidth(78)
        self.btnUpgrade:setHeight(24)
    end
    if self.btnInstall then
        self.btnInstall:setX(94)
        self.btnInstall:setY(self.height - 34)
        self.btnInstall:setWidth(78)
        self.btnInstall:setHeight(24)
    end
    if self.btnSwap then
        self.btnSwap:setX(180)
        self.btnSwap:setY(self.height - 34)
        self.btnSwap:setWidth(78)
        self.btnSwap:setHeight(24)
    end
    if self.btnDestroy then
        self.btnDestroy:setX(266)
        self.btnDestroy:setY(self.height - 34)
        self.btnDestroy:setWidth(62)
        self.btnDestroy:setHeight(24)
    end
end

function DC_BuildingsDetailsPanel:onResize()
    ISPanel.onResize(self)
    self:relayout()
end

function DC_BuildingsDetailsPanel:createChildren()
    ISPanel.createChildren(self)

    local textPanelHeight = self.height - (self.debugEnabled == true and 78 or 50)
    self.textPanel = ISRichTextPanel:new(8, 8, self.width - 16, textPanelHeight)
    self.textPanel:initialise()
    self.textPanel:setAnchorLeft(true)
    self.textPanel:setAnchorRight(false)
    self.textPanel:setAnchorTop(true)
    self.textPanel:setAnchorBottom(false)
    self.textPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.clip = true
    self.textPanel.autosetheight = false
    self.textPanel:addScrollBars()
    self:addChild(self.textPanel)

    if self.debugEnabled == true then
        self.btnDebugComplete = ISButton:new(8, self.height - 62, 96, 24, "Debug Finish", self, self.onDebugCompleteClicked)
        self.btnDebugComplete:initialise()
        self.btnDebugComplete:setAnchorLeft(true)
        self.btnDebugComplete:setAnchorRight(false)
        self.btnDebugComplete:setAnchorTop(false)
        self.btnDebugComplete:setAnchorBottom(true)
        self:addChild(self.btnDebugComplete)
    end

    self.btnUpgrade = ISButton:new(8, self.height - 34, 78, 24, "Upgrade", self, self.onUpgradeClicked)
    self.btnUpgrade:initialise()
    self.btnUpgrade:setAnchorLeft(true)
    self.btnUpgrade:setAnchorRight(false)
    self.btnUpgrade:setAnchorTop(false)
    self.btnUpgrade:setAnchorBottom(true)
    self:addChild(self.btnUpgrade)

    self.btnInstall = ISButton:new(94, self.height - 34, 78, 24, "Install", self, self.onInstallClicked)
    self.btnInstall:initialise()
    self.btnInstall:setAnchorLeft(true)
    self.btnInstall:setAnchorRight(false)
    self.btnInstall:setAnchorTop(false)
    self.btnInstall:setAnchorBottom(true)
    self:addChild(self.btnInstall)

    self.btnSwap = ISButton:new(180, self.height - 34, 78, 24, "Manage", self, self.onSwapClicked)
    self.btnSwap:initialise()
    self.btnSwap:setAnchorLeft(true)
    self.btnSwap:setAnchorRight(false)
    self.btnSwap:setAnchorTop(false)
    self.btnSwap:setAnchorBottom(true)
    self:addChild(self.btnSwap)

    self.btnDestroy = ISButton:new(266, self.height - 34, 62, 24, "Destroy", self, self.onDestroyClicked)
    self.btnDestroy:initialise()
    self.btnDestroy:setAnchorLeft(true)
    self.btnDestroy:setAnchorRight(false)
    self.btnDestroy:setAnchorTop(false)
    self.btnDestroy:setAnchorBottom(true)
    self:addChild(self.btnDestroy)

    self:relayout()
end

function DC_BuildingsDetailsPanel:setPlot(plot)
    self.plot = plot
    if self.textPanel then
        self.textPanel:setText(DC_BuildingsDetailsFormatter.BuildPlotText(plot))
        self.textPanel:paginate()
    end
    if self.btnUpgrade then
        local canUpgrade = plot and plot.building and plot.building.upgradePreview and plot.building.upgradePreview.available == true
        self.btnUpgrade:setEnable(canUpgrade == true)
    end
    if self.btnInstall then
        local canInstall = plot and plot.building and plot.building.installOptions and #plot.building.installOptions > 0
        self.btnInstall:setEnable(canInstall == true)
    end
    if self.btnSwap then
        local isGreenhouse = plot and plot.building and tostring(plot.building.buildingType or "") == "Greenhouse"
        local canSwap = plot and plot.project and tostring(plot.project.status or "") == "Active"
        self.btnSwap:setTitle(canSwap and "Manage" or (isGreenhouse and "Garden" or "Manage"))
        self.btnSwap:setEnable(canSwap == true or isGreenhouse == true)
    end
    if self.btnDestroy then
        local canDestroy = plot and plot.building and plot.building.canDestroy == true
        self.btnDestroy:setEnable(canDestroy == true)
    end
    if self.btnDebugComplete then
        local canDebugComplete = plot and plot.project and tostring(plot.project.status or "") == "Active"
        self.btnDebugComplete:setEnable(canDebugComplete == true)
    end
end

function DC_BuildingsDetailsPanel:onUpgradeClicked()
    if self.onUpgradeCallback and self.plot and self.plot.building then
        self.onUpgradeCallback(self.plot)
    end
end

function DC_BuildingsDetailsPanel:onInstallClicked()
    if self.onInstallCallback and self.plot and self.plot.building then
        self.onInstallCallback(self.plot)
    end
end

function DC_BuildingsDetailsPanel:onSwapClicked()
    if self.plot and self.plot.project and self.onSwapCallback then
        self.onSwapCallback(self.plot)
    elseif self.plot and self.plot.building and tostring(self.plot.building.buildingType or "") == "Greenhouse" and self.onGreenhouseCallback then
        self.onGreenhouseCallback(self.plot)
    end
end

function DC_BuildingsDetailsPanel:onDestroyClicked()
    if self.onDestroyCallback and self.plot and self.plot.building then
        self.onDestroyCallback(self.plot)
    end
end

function DC_BuildingsDetailsPanel:onDebugCompleteClicked()
    if self.onDebugCompleteCallback and self.plot and self.plot.project then
        self.onDebugCompleteCallback(self.plot)
    end
end

function DC_BuildingsDetailsPanel:new(x, y, width, height, onUpgradeCallback, onInstallCallback, onSwapCallback, onGreenhouseCallback, onDestroyCallback, onDebugCompleteCallback)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    o.debugEnabled = canUseDebug()
    o.onUpgradeCallback = onUpgradeCallback
    o.onInstallCallback = onInstallCallback
    o.onSwapCallback = onSwapCallback
    o.onGreenhouseCallback = onGreenhouseCallback
    o.onDestroyCallback = onDestroyCallback
    o.onDebugCompleteCallback = onDebugCompleteCallback
    return o
end

return DC_BuildingsDetailsPanel
