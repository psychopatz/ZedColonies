DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal

function DT_MainWindow:onRefresh()
    self:updateStatus("Refreshing labour roster...")

    if isClient() and not isServer() then
        if not self:sendLabourCommand("RequestPlayerWorkers", {}) then
            self:updateStatus("Unable to request worker data.")
        end
        if DT_System and DT_System.RequestOwnedFactionStatus then
            DT_System.RequestOwnedFactionStatus()
        end
        return
    end

    self:populateWorkerList(Internal.resolveWorkerSummaries())
    if DynamicTrading_Factions and DynamicTrading_Factions.GetOwnedFactionStatus then
        DT_MainWindow.cachedOwnedFactionStatus = DynamicTrading_Factions.GetOwnedFactionStatus(Internal.getOwnerUsername())
        if DT_System then
            DT_System.ownedFactionStatusCache = DT_MainWindow.cachedOwnedFactionStatus
        end
    end
    if self.updateFactionButton then
        self:updateFactionButton()
    end
    self:updateStatus("Loaded local worker data.")
end
