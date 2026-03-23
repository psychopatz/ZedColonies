require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "DT/Common/Buildings/DT_Buildings"
require "DT/UI/ZedColonies/Buildings/Models/DT_BuildingsClientState"
require "DT/UI/ZedColonies/Buildings/Models/DT_BuildingsClientSelectors"
require "DT/UI/ZedColonies/Buildings/Map/DT_BuildingsMapPanel"
require "DT/UI/ZedColonies/Buildings/Details/DT_BuildingsDetailsPanel"
require "DT/UI/ZedColonies/Buildings/Modals/DT_BuildingActionModal"
require "DT/UI/ZedColonies/Buildings/Modals/DT_BuildingDestroyModal"
require "DT/UI/ZedColonies/Buildings/Modals/DT_BuildingPickerModal"
require "DT/UI/ZedColonies/Buildings/Modals/DT_BuildingProjectModal"

DT_BuildingsWindow = ISCollapsableWindow:derive("DT_BuildingsWindow")
DT_BuildingsWindow.instance = DT_BuildingsWindow.instance or nil
DT_BuildingsWindow.cachedSnapshot = DT_BuildingsWindow.cachedSnapshot or nil
DT_BuildingsWindow.EventsAdded = DT_BuildingsWindow.EventsAdded or false

function DT_BuildingsWindow:getOwnerWindow()
    if self.ownerWindow and self.ownerWindow.sendLabourCommand then
        return self.ownerWindow
    end
    return DT_MainWindow and DT_MainWindow.instance or nil
end

function DT_BuildingsWindow:requestSnapshot()
    if isClient() and not isServer() then
        local ownerWindow = self:getOwnerWindow()
        if ownerWindow and ownerWindow.sendLabourCommand then
            ownerWindow:sendLabourCommand("RequestOwnerBuildings", {})
        end
        if DT_System and DT_System.RequestOwnedFactionStatus then
            DT_System.RequestOwnedFactionStatus()
        end
        return
    end

    DT_BuildingsWindow.cachedSnapshot = DT_Buildings and DT_Buildings.BuildOwnerSnapshot
        and DT_Buildings.BuildOwnerSnapshot((DT_Labour and DT_Labour.Config and DT_Labour.Config.GetPlayerObject and DT_Labour.Config.GetPlayerObject()) or "local")
        or nil
    self:refreshFromSnapshot()
end

function DT_BuildingsWindow:getSelectedPlot()
    return DT_BuildingsClientSelectors.FindPlot(self.snapshot, self.selectedPlotKey)
end

function DT_BuildingsWindow:selectPlot(plot)
    if not plot then
        return
    end
    self.selectedPlotKey = plot.key
    self:updatePanels()
end

function DT_BuildingsWindow:updatePanels()
    local selectedPlot = self:getSelectedPlot()
    if self.mapPanel then
        self.mapPanel:setSnapshot(self.snapshot, self.selectedPlotKey)
    end
    if self.detailsPanel then
        self.detailsPanel:setPlot(selectedPlot)
    end
end

function DT_BuildingsWindow:refreshFromSnapshot()
    self.snapshot = DT_BuildingsClientState.Normalize(DT_BuildingsWindow.cachedSnapshot or self.snapshot or {})
    if not self.selectedPlotKey or not DT_BuildingsClientSelectors.FindPlot(self.snapshot, self.selectedPlotKey) then
        self.selectedPlotKey = DT_BuildingsClientSelectors.GetDefaultPlotKey(self.snapshot)
    end
    self:updatePanels()
end

function DT_BuildingsWindow:openProjectModal(preview, title)
    if not preview then
        return
    end

    DT_BuildingProjectModal.Open({
        title = title,
        preview = preview,
        onConfirm = function(payload)
            local ownerWindow = self:getOwnerWindow()
            if ownerWindow and ownerWindow.sendLabourCommand then
                ownerWindow:sendLabourCommand("StartBuildingProject", payload)
            end
        end
    })
end

function DT_BuildingsWindow:openBuildPicker(plot)
    DT_BuildingPickerModal.Open({
        title = "Choose Building",
        carouselHeaderText = "Browse Buildings",
        confirmLabel = "Build",
        options = plot and plot.buildOptions or {},
        onConfirm = function(option)
            self:openProjectModal(option.preview, "Build " .. tostring(option.displayName or option.buildingType or "Building"))
        end
    })
end

function DT_BuildingsWindow:openInstallPicker(plot)
    DT_BuildingPickerModal.Open({
        title = "Choose Installation",
        carouselHeaderText = "Browse Installations",
        confirmLabel = "Install",
        options = plot and plot.building and plot.building.installOptions or {},
        onConfirm = function(option)
            self:openProjectModal(option.preview, "Install " .. tostring(option.displayName or option.installKey or "Upgrade"))
        end
    })
end

function DT_BuildingsWindow:onPlotSelected(plot)
    self:selectPlot(plot)
    if plot and plot.state == "Empty" and plot.availableActions and plot.availableActions.canBuild == true then
        DT_BuildingActionModal.Open({
            plot = plot,
            onBuild = function(selectedPlot)
                self:openBuildPicker(selectedPlot)
            end
        })
    end
end

function DT_BuildingsWindow:onUpgradePlot(plot)
    if not plot or not plot.building then
        return
    end
    self:openProjectModal(
        plot.building.upgradePreview,
        "Upgrade " .. tostring(plot.building.displayName or plot.building.buildingType or "Building")
    )
end

function DT_BuildingsWindow:onInstallPlot(plot)
    if not plot or not plot.building then
        return
    end
    self:openInstallPicker(plot)
end

function DT_BuildingsWindow:onSupplyProject(plot)
    if not plot or not plot.project then
        return
    end

    local ownerWindow = self:getOwnerWindow()
    if ownerWindow and ownerWindow.sendLabourCommand then
        ownerWindow:sendLabourCommand("SupplyBuildingProjectFromInventory", {
            projectID = plot.project.projectID
        })
    end
end

function DT_BuildingsWindow:onDestroyPlot(plot)
    if not plot or not plot.building then
        return
    end

    DT_BuildingDestroyModal.Open({
        plot = plot,
        onConfirm = function(selectedPlot)
            local ownerWindow = self:getOwnerWindow()
            if not ownerWindow or not ownerWindow.sendLabourCommand or not selectedPlot or not selectedPlot.building then
                return
            end

            ownerWindow:sendLabourCommand("DestroyBuilding", {
                plotX = selectedPlot.x,
                plotY = selectedPlot.y,
                buildingID = selectedPlot.building.buildingID
            })
        end
    })
end

function DT_BuildingsWindow:onRefresh()
    self:requestSnapshot()
end

function DT_BuildingsWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    local pad = 10
    local contentY = th + pad
    local contentH = self.height - th - (pad * 2) - 40
    local mapW = math.floor(self.width * 0.62)
    local detailsW = self.width - mapW - (pad * 3)

    self.mapPanel = DT_BuildingsMapPanel:new(pad, contentY, mapW, contentH, function(plot)
        self:onPlotSelected(plot)
    end)
    self.mapPanel:initialise()
    self.mapPanel:setAnchorBottom(true)
    self:addChild(self.mapPanel)

    self.detailsPanel = DT_BuildingsDetailsPanel:new(
        (pad * 2) + mapW,
        contentY,
        detailsW,
        contentH,
        function(plot)
            self:onUpgradePlot(plot)
        end,
        function(plot)
            self:onInstallPlot(plot)
        end,
        function(plot)
            self:onSupplyProject(plot)
        end,
        function(plot)
            self:onDestroyPlot(plot)
        end
    )
    self.detailsPanel:initialise()
    self.detailsPanel:createChildren()
    self.detailsPanel:setAnchorRight(true)
    self.detailsPanel:setAnchorBottom(true)
    self:addChild(self.detailsPanel)

    self.btnRefresh = ISButton:new(self.width - 100, self.height - 30, 90, 24, "Refresh", self, self.onRefresh)
    self.btnRefresh:initialise()
    self.btnRefresh:setAnchorBottom(true)
    self.btnRefresh:setAnchorRight(true)
    self:addChild(self.btnRefresh)

    self:requestSnapshot()
end

function DT_BuildingsWindow:prerender()
    ISCollapsableWindow.prerender(self)
    self.autoRefreshFrames = (tonumber(self.autoRefreshFrames) or 0) + 1
    if self.autoRefreshFrames >= 180 then
        self.autoRefreshFrames = 0
        self:requestSnapshot()
    end
end

function DT_BuildingsWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DT_BuildingsWindow:new(x, y, width, height, ownerWindow)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Buildings"
    o.resizable = true
    o.ownerWindow = ownerWindow
    o.autoRefreshFrames = 0
    o.snapshot = { map = { plots = {} } }
    o.selectedPlotKey = nil
    return o
end

function DT_BuildingsWindow.Open(ownerWindow)
    if DT_BuildingsWindow.instance then
        DT_BuildingsWindow.instance.ownerWindow = ownerWindow or DT_BuildingsWindow.instance.ownerWindow
        DT_BuildingsWindow.instance:setVisible(true)
        DT_BuildingsWindow.instance:addToUIManager()
        DT_BuildingsWindow.instance:bringToTop()
        DT_BuildingsWindow.instance:requestSnapshot()
        return DT_BuildingsWindow.instance
    end

    local width = 1080
    local height = 680
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local window = DT_BuildingsWindow:new(x, y, width, height, ownerWindow)
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:bringToTop()
    DT_BuildingsWindow.instance = window
    return window
end

if not DT_BuildingsWindow.EventsAdded then
    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= "DynamicTrading_V2" then
            return
        end
        if command ~= "SyncBuildingsSnapshot" then
            return
        end
        DT_BuildingsWindow.cachedSnapshot = args and args.snapshot or nil
        if DT_BuildingsWindow.instance and DT_BuildingsWindow.instance:getIsVisible() then
            DT_BuildingsWindow.instance:refreshFromSnapshot()
        end
    end)
    DT_BuildingsWindow.EventsAdded = true
end

return DT_BuildingsWindow
