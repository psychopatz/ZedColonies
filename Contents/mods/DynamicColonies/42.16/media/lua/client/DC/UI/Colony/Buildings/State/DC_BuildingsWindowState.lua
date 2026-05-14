require "DC/UI/Colony/Buildings/Models/DC_BuildingsClientState"
require "DC/UI/Colony/Buildings/Models/DC_BuildingsClientSelectors"

DC_BuildingsWindowState = DC_BuildingsWindowState or {}

local State = DC_BuildingsWindowState

function State.GetSelectedPlot(window)
    return DC_BuildingsClientSelectors.FindPlot(window and window.snapshot or nil, window and window.selectedPlotKey or nil)
end

function State.SelectPlot(window, plot)
    if not plot then
        return
    end

    window.selectedPlotKey = plot.key
    State.UpdatePanels(window)
end

function State.UpdatePanels(window)
    local selectedPlot = State.GetSelectedPlot(window)
    if window and window.mapPanel then
        window.mapPanel:setSnapshot(window.snapshot, window.selectedPlotKey, window.syncInfo)
    end
    if window and window.detailsPanel then
        window.detailsPanel:setPlot(selectedPlot)
    end
    if window and window.btnBaseZone then
        local enabled = DC_BuildingsRealBaseUI and DC_BuildingsRealBaseUI.CanOpenBaseZone and DC_BuildingsRealBaseUI.CanOpenBaseZone(window.snapshot) == true
        window.btnBaseZone:setEnable(enabled == true)
    end
end

function State.RefreshFromSnapshot(window, windowClass)
    if not window then
        return
    end

    window.snapshot = DC_BuildingsClientState.Normalize((windowClass and windowClass.cachedSnapshot) or window.snapshot or {})
    window.syncInfo = window.snapshot and window.snapshot.sync or {}
    if not window.selectedPlotKey or not DC_BuildingsClientSelectors.FindPlot(window.snapshot, window.selectedPlotKey) then
        window.selectedPlotKey = DC_BuildingsClientSelectors.GetDefaultPlotKey(window.snapshot)
    end
    State.UpdatePanels(window)
end

return State
