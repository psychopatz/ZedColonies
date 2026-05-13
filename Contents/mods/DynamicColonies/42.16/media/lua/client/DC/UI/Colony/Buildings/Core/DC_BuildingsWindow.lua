require "ISUI/ISCollapsableWindow"
require "DC/UI/Colony/Buildings/Map/DC_BuildingsMapPanel"
require "DC/UI/Colony/Buildings/Details/DC_BuildingsDetailsPanel"
require "DC/UI/Colony/Buildings/State/DC_BuildingsWindowState"
require "DC/UI/Colony/Buildings/Actions/DC_BuildingsWindowActions"
require "DC/UI/Colony/Buildings/Sync/DC_BuildingsWindowSync"
require "DC/UI/Colony/Buildings/Layout/DC_BuildingsWindowLayout"
require "DC/UI/Colony/Buildings/Lifecycle/DC_BuildingsWindowLifecycle"

DC_BuildingsWindow = ISCollapsableWindow:derive("DC_BuildingsWindow")
DC_BuildingsWindow.instance = DC_BuildingsWindow.instance or nil
DC_BuildingsWindow.cachedSnapshot = DC_BuildingsWindow.cachedSnapshot or nil
DC_BuildingsWindow.cachedVersion = DC_BuildingsWindow.cachedVersion or nil
DC_BuildingsWindow.EventsAdded = DC_BuildingsWindow.EventsAdded or false
DC_BuildingsWindow.AUTO_REFRESH_FRAMES = 600

local BuildingsWindowActions = DC_BuildingsWindowActions
local BuildingsWindowSync = DC_BuildingsWindowSync
local BuildingsWindowState = DC_BuildingsWindowState
local BuildingsWindowLayout = DC_BuildingsWindowLayout
local BuildingsWindowLifecycle = DC_BuildingsWindowLifecycle

function DC_BuildingsWindow:getOwnerWindow()
    if self.ownerWindow and self.ownerWindow.sendColonyCommand then
        return self.ownerWindow
    end
    return DC_MainWindow and DC_MainWindow.instance or nil
end

function DC_BuildingsWindow:requestSnapshot()
    BuildingsWindowSync.RequestSnapshot(self, DC_BuildingsWindow)
end

function DC_BuildingsWindow:getSelectedPlot()
    return BuildingsWindowState.GetSelectedPlot(self)
end

function DC_BuildingsWindow:selectPlot(plot)
    BuildingsWindowState.SelectPlot(self, plot)
end

function DC_BuildingsWindow:updatePanels()
    BuildingsWindowState.UpdatePanels(self)
end

function DC_BuildingsWindow:refreshFromSnapshot()
    BuildingsWindowState.RefreshFromSnapshot(self, DC_BuildingsWindow)
end

function DC_BuildingsWindow:openProjectModal(preview, title)
    BuildingsWindowActions.OpenProjectModal(self, preview, title)
end

function DC_BuildingsWindow:openReassignProjectModal(plot)
    BuildingsWindowActions.OpenReassignProjectModal(self, plot)
end

function DC_BuildingsWindow:openBuildPicker(plot)
    BuildingsWindowActions.OpenBuildPicker(self, plot)
end

function DC_BuildingsWindow:openInstallPicker(plot)
    BuildingsWindowActions.OpenInstallPicker(self, plot)
end

function DC_BuildingsWindow:onPlotSelected(plot)
    BuildingsWindowActions.OnPlotSelected(self, plot)
end

function DC_BuildingsWindow:onUpgradePlot(plot)
    BuildingsWindowActions.OnUpgradePlot(self, plot)
end

function DC_BuildingsWindow:onInstallPlot(plot)
    BuildingsWindowActions.OnInstallPlot(self, plot)
end

function DC_BuildingsWindow:onSupplyProject(plot)
    BuildingsWindowActions.OnSupplyProject(self, plot)
end

function DC_BuildingsWindow:onSwapProjectBuilder(plot)
    BuildingsWindowActions.OnSwapProjectBuilder(self, plot)
end

function DC_BuildingsWindow:onDestroyPlot(plot)
    BuildingsWindowActions.OnDestroyPlot(self, plot)
end

function DC_BuildingsWindow:onManageGreenhousePlot(plot)
    BuildingsWindowActions.OnManageGreenhousePlot(self, plot)
end

function DC_BuildingsWindow:onDebugCompleteProject(plot)
    BuildingsWindowActions.OnDebugCompleteProject(self, plot)
end

function DC_BuildingsWindow:onRefresh()
    self:requestSnapshot()
end

function DC_BuildingsWindow:layoutChildren()
    BuildingsWindowLayout.LayoutChildren(self)
end

function DC_BuildingsWindow:onResize()
    BuildingsWindowLifecycle.OnResize(self)
end

function DC_BuildingsWindow:createChildren()
    BuildingsWindowLayout.CreateChildren(self)
end

function DC_BuildingsWindow:prerender()
    BuildingsWindowLifecycle.Prerender(self)
end

function DC_BuildingsWindow:close()
    BuildingsWindowLifecycle.Close(self)
end

function DC_BuildingsWindow:new(x, y, width, height, ownerWindow)
    return BuildingsWindowLifecycle.New(self, x, y, width, height, ownerWindow)
end

function DC_BuildingsWindow.Open(ownerWindow)
    return BuildingsWindowLifecycle.Open(DC_BuildingsWindow, ownerWindow)
end

BuildingsWindowSync.InstallEvents(DC_BuildingsWindow)

return DC_BuildingsWindow
