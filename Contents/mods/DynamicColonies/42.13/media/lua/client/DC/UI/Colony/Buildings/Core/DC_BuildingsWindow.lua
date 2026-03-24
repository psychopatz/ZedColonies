require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "DC/Common/Buildings/DC_Buildings"
require "DC/UI/Colony/Buildings/Models/DC_BuildingsClientState"
require "DC/UI/Colony/Buildings/Models/DC_BuildingsClientSelectors"
require "DC/UI/Colony/Buildings/Map/DC_BuildingsMapPanel"
require "DC/UI/Colony/Buildings/Details/DC_BuildingsDetailsPanel"
require "DC/UI/Colony/Buildings/Modals/DC_BuildingActionModal"
require "DC/UI/Colony/Buildings/Modals/DC_BuildingDestroyModal"
require "DC/UI/Colony/Buildings/Modals/DC_BuildingPickerModal"
require "DC/UI/Colony/Buildings/Modals/DC_BuildingProjectModal"

DC_BuildingsWindow = ISCollapsableWindow:derive("DC_BuildingsWindow")
DC_BuildingsWindow.instance = DC_BuildingsWindow.instance or nil
DC_BuildingsWindow.cachedSnapshot = DC_BuildingsWindow.cachedSnapshot or nil
DC_BuildingsWindow.EventsAdded = DC_BuildingsWindow.EventsAdded or false
DC_BuildingsWindow.AUTO_REFRESH_FRAMES = 600

function DC_BuildingsWindow:getOwnerWindow()
    if self.ownerWindow and self.ownerWindow.sendColonyCommand then
        return self.ownerWindow
    end
    return DC_MainWindow and DC_MainWindow.instance or nil
end

function DC_BuildingsWindow:requestSnapshot()
    if isClient() and not isServer() then
        local ownerWindow = self:getOwnerWindow()
        if ownerWindow and ownerWindow.sendColonyCommand then
            ownerWindow:sendColonyCommand("RequestOwnerBuildings", {})
        end
        if DC_System and DC_System.RequestOwnedFactionStatus then
            DC_System.RequestOwnedFactionStatus()
        end
        return
    end

    if DC_Buildings and DC_Buildings.EnsureInitialHeadquartersProject then
        DC_Buildings.EnsureInitialHeadquartersProject((DC_Colony and DC_Colony.Config and DC_Colony.Config.GetPlayerObject and DC_Colony.Config.GetPlayerObject()) or "local")
    end
    DC_BuildingsWindow.cachedSnapshot = DC_Buildings and DC_Buildings.BuildOwnerSnapshot
        and DC_Buildings.BuildOwnerSnapshot((DC_Colony and DC_Colony.Config and DC_Colony.Config.GetPlayerObject and DC_Colony.Config.GetPlayerObject()) or "local")
        or nil
    self:refreshFromSnapshot()
end

function DC_BuildingsWindow:getSelectedPlot()
    return DC_BuildingsClientSelectors.FindPlot(self.snapshot, self.selectedPlotKey)
end

function DC_BuildingsWindow:selectPlot(plot)
    if not plot then
        return
    end
    self.selectedPlotKey = plot.key
    self:updatePanels()
end

function DC_BuildingsWindow:updatePanels()
    local selectedPlot = self:getSelectedPlot()
    if self.mapPanel then
        self.mapPanel:setSnapshot(self.snapshot, self.selectedPlotKey)
    end
    if self.detailsPanel then
        self.detailsPanel:setPlot(selectedPlot)
    end
end

function DC_BuildingsWindow:refreshFromSnapshot()
    self.snapshot = DC_BuildingsClientState.Normalize(DC_BuildingsWindow.cachedSnapshot or self.snapshot or {})
    if not self.selectedPlotKey or not DC_BuildingsClientSelectors.FindPlot(self.snapshot, self.selectedPlotKey) then
        self.selectedPlotKey = DC_BuildingsClientSelectors.GetDefaultPlotKey(self.snapshot)
    end
    self:updatePanels()
end

function DC_BuildingsWindow:openProjectModal(preview, title)
    if not preview then
        return
    end

    DC_BuildingProjectModal.Open({
        title = title,
        preview = preview,
        onConfirm = function(payload)
            local ownerWindow = self:getOwnerWindow()
            if ownerWindow and ownerWindow.sendColonyCommand then
                ownerWindow:sendColonyCommand("StartBuildingProject", payload)
            end
        end,
        onDebugMaterials = function(payload)
            local ownerWindow = self:getOwnerWindow()
            if ownerWindow and ownerWindow.sendColonyCommand then
                ownerWindow:sendColonyCommand("DebugGiveProjectMaterials", payload)
            end
        end
    })
end

function DC_BuildingsWindow:openReassignProjectModal(plot)
    local project = plot and plot.project or nil
    if not project then
        return
    end

    DC_BuildingProjectModal.Open({
        title = "Manage Project",
        confirmLabel = "Save",
        requireBuilder = true,
        preview = {
            projectID = project.projectID,
            buildingType = project.buildingType,
            displayName = project.displayName,
            mode = project.mode,
            plotX = project.plotX,
            plotY = project.plotY,
            buildingID = project.buildingID,
            installKey = project.installKey,
            targetLevel = project.targetLevel,
            requiredWorkPoints = project.requiredWorkPoints,
            workPoints = project.requiredWorkPoints,
            materialEntries = project.materialEntries,
            materialState = project.materialState,
            canStart = tostring(project.materialState or "") ~= "Stalled",
            available = true,
            assignedBuilderID = project.assignedBuilderID,
            assignedBuilderName = project.assignedBuilderName
        },
        onSupply = function(payload)
            local ownerWindow = self:getOwnerWindow()
            if ownerWindow and ownerWindow.sendColonyCommand then
                ownerWindow:sendColonyCommand("SupplyBuildingProjectFromInventory", {
                    projectID = payload.projectID
                })
            end
        end,
        onConfirm = function(payload)
            local ownerWindow = self:getOwnerWindow()
            if ownerWindow and ownerWindow.sendColonyCommand then
                ownerWindow:sendColonyCommand("ReassignBuildingProject", {
                    projectID = payload.projectID,
                    workerID = payload.workerID
                })
            end
        end,
        onDebugMaterials = function(payload)
            local ownerWindow = self:getOwnerWindow()
            if ownerWindow and ownerWindow.sendColonyCommand then
                ownerWindow:sendColonyCommand("DebugGiveProjectMaterials", {
                    projectID = payload.projectID,
                    buildingType = payload.buildingType,
                    mode = payload.mode,
                    plotX = payload.plotX,
                    plotY = payload.plotY,
                    buildingID = payload.buildingID,
                    installKey = payload.installKey
                })
            end
        end
    })
end

function DC_BuildingsWindow:openBuildPicker(plot)
    DC_BuildingPickerModal.Open({
        title = "Choose Building",
        carouselHeaderText = "Browse Buildings",
        confirmLabel = "Build",
        options = plot and plot.buildOptions or {},
        onConfirm = function(option)
            self:openProjectModal(option.preview, "Build " .. tostring(option.displayName or option.buildingType or "Building"))
        end
    })
end

function DC_BuildingsWindow:openInstallPicker(plot)
    DC_BuildingPickerModal.Open({
        title = "Choose Installation",
        carouselHeaderText = "Browse Installations",
        confirmLabel = "Install",
        options = plot and plot.building and plot.building.installOptions or {},
        onConfirm = function(option)
            self:openProjectModal(option.preview, "Install " .. tostring(option.displayName or option.installKey or "Upgrade"))
        end
    })
end

function DC_BuildingsWindow:onPlotSelected(plot)
    self:selectPlot(plot)
    if plot and plot.availableActions and plot.availableActions.canBuild == true then
        DC_BuildingActionModal.Open({
            plot = plot,
            onBuild = function(selectedPlot)
                self:openBuildPicker(selectedPlot)
            end
        })
    end
end

function DC_BuildingsWindow:onUpgradePlot(plot)
    if not plot or not plot.building then
        return
    end
    self:openProjectModal(
        plot.building.upgradePreview,
        "Upgrade " .. tostring(plot.building.displayName or plot.building.buildingType or "Building")
    )
end

function DC_BuildingsWindow:onInstallPlot(plot)
    if not plot or not plot.building then
        return
    end
    self:openInstallPicker(plot)
end

function DC_BuildingsWindow:onSupplyProject(plot)
    if not plot or not plot.project then
        return
    end

    local ownerWindow = self:getOwnerWindow()
    if ownerWindow and ownerWindow.sendColonyCommand then
        ownerWindow:sendColonyCommand("SupplyBuildingProjectFromInventory", {
            projectID = plot.project.projectID
        })
    end
end

function DC_BuildingsWindow:onSwapProjectBuilder(plot)
    if not plot or not plot.project then
        return
    end

    self:openReassignProjectModal(plot)
end

function DC_BuildingsWindow:onDestroyPlot(plot)
    if not plot or not plot.building then
        return
    end

    DC_BuildingDestroyModal.Open({
        plot = plot,
        onConfirm = function(selectedPlot)
            local ownerWindow = self:getOwnerWindow()
            if not ownerWindow or not ownerWindow.sendColonyCommand or not selectedPlot or not selectedPlot.building then
                return
            end

            ownerWindow:sendColonyCommand("DestroyBuilding", {
                plotX = selectedPlot.x,
                plotY = selectedPlot.y,
                buildingID = selectedPlot.building.buildingID
            })
        end
    })
end

function DC_BuildingsWindow:onDebugCompleteProject(plot)
    if not plot or not plot.project then
        return
    end

    local ownerWindow = self:getOwnerWindow()
    if ownerWindow and ownerWindow.sendColonyCommand then
        ownerWindow:sendColonyCommand("DebugCompleteBuildingProject", {
            projectID = plot.project.projectID
        })
    end
end

function DC_BuildingsWindow:onRefresh()
    self:requestSnapshot()
end

function DC_BuildingsWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    local pad = 10
    local contentY = th + pad
    local contentH = self.height - th - (pad * 2) - 40
    local mapW = math.floor(self.width * 0.62)
    local detailsW = self.width - mapW - (pad * 3)

    self.mapPanel = DC_BuildingsMapPanel:new(pad, contentY, mapW, contentH, function(plot)
        self:onPlotSelected(plot)
    end)
    self.mapPanel:initialise()
    self.mapPanel:setAnchorBottom(true)
    self:addChild(self.mapPanel)

    self.detailsPanel = DC_BuildingsDetailsPanel:new(
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
            self:onSwapProjectBuilder(plot)
        end,
        function(plot)
            self:onDestroyPlot(plot)
        end,
        function(plot)
            self:onDebugCompleteProject(plot)
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

function DC_BuildingsWindow:prerender()
    ISCollapsableWindow.prerender(self)
    self.autoRefreshFrames = (tonumber(self.autoRefreshFrames) or 0) + 1
    if self.autoRefreshFrames >= (tonumber(self.AUTO_REFRESH_FRAMES) or DC_BuildingsWindow.AUTO_REFRESH_FRAMES or 600) then
        self.autoRefreshFrames = 0
        self:requestSnapshot()
    end
end

function DC_BuildingsWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DC_BuildingsWindow:new(x, y, width, height, ownerWindow)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Colony Map"
    o.resizable = true
    o.ownerWindow = ownerWindow
    o.autoRefreshFrames = 0
    o.snapshot = { map = { plots = {} } }
    o.selectedPlotKey = nil
    return o
end

function DC_BuildingsWindow.Open(ownerWindow)
    if DC_BuildingsWindow.instance then
        DC_BuildingsWindow.instance.ownerWindow = ownerWindow or DC_BuildingsWindow.instance.ownerWindow
        DC_BuildingsWindow.instance:setVisible(true)
        DC_BuildingsWindow.instance:addToUIManager()
        DC_BuildingsWindow.instance:bringToTop()
        DC_BuildingsWindow.instance:requestSnapshot()
        return DC_BuildingsWindow.instance
    end

    local width = 1080
    local height = 680
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local window = DC_BuildingsWindow:new(x, y, width, height, ownerWindow)
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:bringToTop()
    DC_BuildingsWindow.instance = window
    return window
end

if not DC_BuildingsWindow.EventsAdded then
    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= "DynamicTrading_V2" then
            return
        end
        if command ~= "SyncBuildingsSnapshot" then
            return
        end
        DC_BuildingsWindow.cachedSnapshot = args and args.snapshot or nil
        if DC_BuildingsWindow.instance and DC_BuildingsWindow.instance:getIsVisible() then
            DC_BuildingsWindow.instance:refreshFromSnapshot()
        end
    end)
    DC_BuildingsWindow.EventsAdded = true
end

return DC_BuildingsWindow
