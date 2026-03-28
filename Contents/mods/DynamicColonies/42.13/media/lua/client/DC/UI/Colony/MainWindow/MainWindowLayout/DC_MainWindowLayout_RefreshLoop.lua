DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
local MainWindowLayout = Internal.MainWindowLayout or {}

local function buildWorkerRequestArgs()
    local config = Internal.Config or (DC_Colony and DC_Colony.Config) or nil
    return {
        knownVersion = DC_MainWindow.cachedWorkersVersion,
        starterCount = config and config.GetStarterColonistCount and config.GetStarterColonistCount() or nil
    }
end

local function autoRefreshWindow(window)
    if not window or not window:getIsVisible() then
        return
    end

    if isClient() and not isServer() then
        window.syncStatusMutedFrames = 120
        window:sendColonyCommand("RequestPlayerWorkers", buildWorkerRequestArgs())
        if window.selectedWorkerSummary and window.selectedWorkerSummary.workerID then
            local supplyWindow = DC_SupplyWindow and DC_SupplyWindow.instance or nil
            local supplyOwnsDetailSync = supplyWindow
                and supplyWindow.getIsVisible
                and supplyWindow:getIsVisible()
                and supplyWindow.workerID == window.selectedWorkerSummary.workerID

            if not supplyOwnsDetailSync then
                window:sendColonyCommand("RequestWorkerDetails", {
                    workerID = window.selectedWorkerSummary.workerID,
                    knownVersion = DC_MainWindow.cachedDetailVersions and DC_MainWindow.cachedDetailVersions[window.selectedWorkerSummary.workerID] or nil,
                    includeWorkerLedgers = false
                })
            end
        end
        return
    end

    window:sendColonyCommand("RequestPlayerWorkers", buildWorkerRequestArgs())
    window:populateWorkerList(Internal.resolveWorkerSummaries())
    if window.selectedWorkerSummary and window.selectedWorkerSummary.workerID then
        local detail = Internal.resolveWorkerDetail(window.selectedWorkerSummary.workerID)
        if detail then
            window:updateWorkerDetail(detail)
        end
    end
end

function DC_MainWindow:prerender()
    ISCollapsableWindow.prerender(self)
    self.syncStatusMutedFrames = math.max(0, tonumber(self.syncStatusMutedFrames) or 0)
    if self.syncStatusMutedFrames > 0 then
        self.syncStatusMutedFrames = self.syncStatusMutedFrames - 1
    end
    self.autoRefreshFrames = (tonumber(self.autoRefreshFrames) or 0) + 1
    if self.autoRefreshFrames >= MainWindowLayout.AUTO_REFRESH_FRAMES then
        self.autoRefreshFrames = 0
        autoRefreshWindow(self)
    end

    if isClient() and not isServer() then
        self.ownedFactionRefreshFrames = (tonumber(self.ownedFactionRefreshFrames) or 0) + 1
        if self.ownedFactionRefreshFrames >= (MainWindowLayout.OWNED_FACTION_REFRESH_FRAMES or 300) then
            self.ownedFactionRefreshFrames = 0
            if DC_System and DC_System.RequestOwnedFactionStatus then
                DC_System.RequestOwnedFactionStatus()
            end
        end
    end

    local th = self:titleBarHeight()
    local pad = 10
    local listY = th + pad + 38
    local contentHeight = self.height - listY - 38 - pad
    self:drawRectBorder(10, listY, 280, contentHeight, 0.4, 1, 1, 1)
    self:drawTextCentre("LABOUR MANAGEMENT", self.width / 2, th + 6, 1, 1, 1, 1, UIFont.Large)
end
