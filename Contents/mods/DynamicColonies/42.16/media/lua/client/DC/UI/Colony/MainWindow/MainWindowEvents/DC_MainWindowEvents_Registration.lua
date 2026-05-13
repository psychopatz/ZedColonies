DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}
DC_Colony = DC_Colony or {}
DC_Colony.UI = DC_Colony.UI or {}

local Internal = DC_MainWindow.Internal
local EventSync = Internal.Events or {}
local FlavorText = DC_Colony.UI.MainWindowEventsFlavorText or {}

function EventSync.registerEvents()
    if DC_MainWindow.EventsAdded then
        return
    end

    Events.OnServerCommand.Add(EventSync.onServerCommand)
    Events.OnReceiveGlobalModData.Add(function(key, data)
        if not DC_MainWindow.instance or not DC_MainWindow.instance:getIsVisible() then
            return
        end

        if key == (Internal.Config.MOD_DATA_INDEX_KEY or Internal.Config.MOD_DATA_KEY or "DColony_Index") then
            DC_MainWindow.instance:populateWorkerList(Internal.resolveWorkerSummaries())
            if (tonumber(DC_MainWindow.instance.syncStatusMutedFrames) or 0) <= 0 then
                DC_MainWindow.instance:updateStatus(tostring(FlavorText.colonyDataRefreshedFromModData or "Colony data refreshed from ModData."))
            end
        end
    end)
    DC_MainWindow.EventsAdded = true
end

EventSync.registerEvents()

return EventSync