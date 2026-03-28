DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal

local function buildWorkerRequestArgs()
    local config = Internal.Config or (DC_Colony and DC_Colony.Config) or nil
    return {
        starterCount = config and config.GetStarterColonistCount and config.GetStarterColonistCount() or nil
    }
end

function DC_MainWindow:onRefresh()
    self:updateStatus("Refreshing labour roster...")

    if isClient() and not isServer() then
        if not self:sendColonyCommand("RequestPlayerWorkers", buildWorkerRequestArgs()) then
            self:updateStatus("Unable to request worker data.")
        end
        if DC_System and DC_System.RequestOwnedFactionStatus then
            DC_System.RequestOwnedFactionStatus()
        end
        return
    end

    self:sendColonyCommand("RequestPlayerWorkers", buildWorkerRequestArgs())
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
