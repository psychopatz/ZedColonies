DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal

function DC_MainWindow:onRefresh()
    self:updateStatus("Refreshing colony state...")

    if isClient() and not isServer() then
        if not self:sendColonyCommand("RequestColonyBootstrap", {
            knownVersions = {
                building = DC_BuildingsWindow and DC_BuildingsWindow.cachedVersion or nil,
                workerList = DC_MainWindow.cachedWorkersVersion,
                warehouseSummary = DC_MainWindow.cachedWarehouseSummaryVersion,
                resources = DC_MainWindow.cachedResourcesSummaryVersion,
                factionStatus = DC_MainWindow.cachedFactionStatusVersion,
            }
        }) then
            self:updateStatus("Unable to request colony data.")
        end
        return
    end

    self:populateWorkerList(Internal.resolveWorkerSummaries())
    if DynamicTrading_Factions and DynamicTrading_Factions.GetOwnedFactionStatus then
        DC_MainWindow.cachedOwnedFactionStatus = DynamicTrading_Factions.GetOwnedFactionStatus(Internal.getOwnerUsername())
        if DC_System then
            DC_System.ownedFactionStatusCache = DC_MainWindow.cachedOwnedFactionStatus
        end
    end
    if self.updateFactionButton then
        self:updateFactionButton()
    end
    self:updateStatus("Loaded local worker data.")
end
