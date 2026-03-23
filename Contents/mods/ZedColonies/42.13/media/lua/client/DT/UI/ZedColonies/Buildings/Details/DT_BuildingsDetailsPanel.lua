require "ISUI/ISPanel"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "DT/UI/ZedColonies/Buildings/Details/DT_BuildingsDetailsFormatter"

DT_BuildingsDetailsPanel = ISPanel:derive("DT_BuildingsDetailsPanel")

function DT_BuildingsDetailsPanel:initialise()
    ISPanel.initialise(self)
end

function DT_BuildingsDetailsPanel:createChildren()
    ISPanel.createChildren(self)

    self.textPanel = ISRichTextPanel:new(8, 8, self.width - 16, self.height - 50)
    self.textPanel:initialise()
    self.textPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.clip = true
    self.textPanel.autosetheight = false
    self.textPanel:addScrollBars()
    self:addChild(self.textPanel)

    self.btnUpgrade = ISButton:new(8, self.height - 34, 78, 24, "Upgrade", self, self.onUpgradeClicked)
    self.btnUpgrade:initialise()
    self.btnUpgrade:setAnchorBottom(true)
    self:addChild(self.btnUpgrade)

    self.btnInstall = ISButton:new(94, self.height - 34, 78, 24, "Install", self, self.onInstallClicked)
    self.btnInstall:initialise()
    self.btnInstall:setAnchorBottom(true)
    self:addChild(self.btnInstall)

    self.btnSupply = ISButton:new(180, self.height - 34, 78, 24, "Supply", self, self.onSupplyClicked)
    self.btnSupply:initialise()
    self.btnSupply:setAnchorBottom(true)
    self:addChild(self.btnSupply)

    self.btnDestroy = ISButton:new(266, self.height - 34, 78, 24, "Destroy", self, self.onDestroyClicked)
    self.btnDestroy:initialise()
    self.btnDestroy:setAnchorBottom(true)
    self:addChild(self.btnDestroy)
end

function DT_BuildingsDetailsPanel:setPlot(plot)
    self.plot = plot
    if self.textPanel then
        self.textPanel:setText(DT_BuildingsDetailsFormatter.BuildPlotText(plot))
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
    if self.btnSupply then
        local canSupply = plot and plot.project and tostring(plot.project.materialState or "") == "Stalled"
        self.btnSupply:setEnable(canSupply == true)
    end
    if self.btnDestroy then
        local canDestroy = plot and plot.building and plot.building.canDestroy == true
        self.btnDestroy:setEnable(canDestroy == true)
    end
end

function DT_BuildingsDetailsPanel:onUpgradeClicked()
    if self.onUpgradeCallback and self.plot and self.plot.building then
        self.onUpgradeCallback(self.plot)
    end
end

function DT_BuildingsDetailsPanel:onInstallClicked()
    if self.onInstallCallback and self.plot and self.plot.building then
        self.onInstallCallback(self.plot)
    end
end

function DT_BuildingsDetailsPanel:onSupplyClicked()
    if self.onSupplyCallback and self.plot and self.plot.project then
        self.onSupplyCallback(self.plot)
    end
end

function DT_BuildingsDetailsPanel:onDestroyClicked()
    if self.onDestroyCallback and self.plot and self.plot.building then
        self.onDestroyCallback(self.plot)
    end
end

function DT_BuildingsDetailsPanel:new(x, y, width, height, onUpgradeCallback, onInstallCallback, onSupplyCallback, onDestroyCallback)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.2 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    o.onUpgradeCallback = onUpgradeCallback
    o.onInstallCallback = onInstallCallback
    o.onSupplyCallback = onSupplyCallback
    o.onDestroyCallback = onDestroyCallback
    return o
end

return DT_BuildingsDetailsPanel
