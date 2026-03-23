DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal
local MainWindowLayout = Internal.MainWindowLayout or {}

local function autoRefreshWindow(window)
    if not window or not window:getIsVisible() then
        return
    end

    if isClient() and not isServer() then
        window.syncStatusMutedFrames = 120
        window:sendLabourCommand("RequestPlayerWorkers", {})
        if window.selectedWorkerSummary and window.selectedWorkerSummary.workerID then
            local supplyWindow = DT_SupplyWindow and DT_SupplyWindow.instance or nil
            local supplyOwnsDetailSync = supplyWindow
                and supplyWindow.getIsVisible
                and supplyWindow:getIsVisible()
                and supplyWindow.workerID == window.selectedWorkerSummary.workerID

            if not supplyOwnsDetailSync then
                window:sendLabourCommand("RequestWorkerDetails", {
                    workerID = window.selectedWorkerSummary.workerID,
                    includeWarehouseLedgers = false
                })
            end
        end
        return
    end

    window:populateWorkerList(Internal.resolveWorkerSummaries())
    if window.selectedWorkerSummary and window.selectedWorkerSummary.workerID then
        local detail = Internal.resolveWorkerDetail(window.selectedWorkerSummary.workerID)
        if detail then
            window:updateWorkerDetail(detail)
        end
    end
end

function DT_MainWindow:prerender()
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
            if DT_System and DT_System.RequestOwnedFactionStatus then
                DT_System.RequestOwnedFactionStatus()
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
