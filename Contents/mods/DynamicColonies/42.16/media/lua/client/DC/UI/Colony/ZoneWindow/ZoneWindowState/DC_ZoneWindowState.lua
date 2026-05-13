require "DC/Common/Zone/DC_ZoneDataStore"

DC_ZoneWindowState = DC_ZoneWindowState or {}

local State = DC_ZoneWindowState

local function resolveSelectedZone(window)
    if not window then
        return nil
    end

    local zones = State.GetZones(window)
    local selectedZone = window.selectedZone
    local selectedZoneId = window.selectedZoneId or (selectedZone and selectedZone.id) or nil

    if selectedZone and selectedZone.id == selectedZoneId then
        for _, zoneEntry in ipairs(zones) do
            if zoneEntry and zoneEntry.id == selectedZone.id then
                window.selectedZone = zoneEntry
                window.selectedZoneId = zoneEntry.id
                return zoneEntry
            end
        end
    end

    if selectedZoneId then
        for _, zoneEntry in ipairs(zones) do
            if zoneEntry and zoneEntry.id == selectedZoneId then
                window.selectedZone = zoneEntry
                window.selectedZoneId = zoneEntry.id
                return zoneEntry
            end
        end
    end

    return nil
end

function State.GetZones(window)
    if not window then
        return {}
    end

    window.zones = DC_ZoneDataStore.GetZones(window.colonyId)
    return window.zones
end

function State.GetSelectedZone(window)
    return resolveSelectedZone(window)
end

function State.GetSelectedRect(window)
    local selectedZone = resolveSelectedZone(window)
    local selectedRect = window and window.selectedRect or nil
    if not selectedZone or type(selectedRect) ~= "number" then
        return nil
    end

    if selectedZone.rects and selectedZone.rects[selectedRect] then
        return selectedRect
    end

    return nil
end

function State.SyncZones(window, zones)
    if not window then
        return
    end

    window.zones = DC_ZoneDataStore.ReplaceZones(window.colonyId, zones)
    State.RefreshWindow(window)
end

function State.RefreshWindow(window)
    if not window then
        return
    end

    window.zones = DC_ZoneDataStore.GetZones(window.colonyId)

    local selectedZone = resolveSelectedZone(window)
    if not selectedZone then
        window.selectedZone = nil
        window.selectedZoneId = nil
        window.selectedRect = nil
    elseif window.selectedRect and not (selectedZone.rects and selectedZone.rects[window.selectedRect]) then
        window.selectedRect = nil
    end

    if window.populateZoneList then
        window:populateZoneList()
    end
    if window.refreshDetailPanel then
        window:refreshDetailPanel()
    end
    if window.mapPanel and window.mapPanel.refreshZones then
        window.mapPanel:refreshZones(window.zones, selectedZone, window.selectedRect)
    end
end

function State.SelectZone(window, zone)
    if not window or not zone then
        return
    end

    window.selectedZone = zone
    window.selectedZoneId = zone.id
    window.selectedRect = nil
    if window.zoneList then
        for index, zoneEntry in ipairs(State.GetZones(window)) do
            if zoneEntry and zoneEntry.id == zone.id then
                window.zoneList.selected = index
                break
            end
        end
    end
    State.RefreshWindow(window)
end

function State.SetSelectedRect(window, rectIndex)
    if not window then
        return
    end

    window.selectedRect = rectIndex
    if window.refreshDetailPanel then
        window:refreshDetailPanel()
    end
    if window.mapPanel and window.mapPanel.refreshZones then
        window.mapPanel:refreshZones(State.GetZones(window), State.GetSelectedZone(window), window.selectedRect)
    end
end

function State.AddZone(window, zone)
    if not window or not zone then
        return
    end

    local zones = State.GetZones(window)
    zones[#zones + 1] = zone
    window.selectedZone = zone
    window.selectedZoneId = zone.id
    window.selectedRect = nil
    if window.zoneList then
        window.zoneList.selected = #zones
    end
    State.RefreshWindow(window)
    State.MarkDirty(window)
end

function State.RemoveZone(window, zone)
    if not window or not zone then
        return false
    end

    local zones = State.GetZones(window)
    for index, zoneEntry in ipairs(zones) do
        if zoneEntry and zoneEntry.id == zone.id then
            table.remove(zones, index)
            break
        end
    end

    if window.selectedZone and window.selectedZone.id == zone.id then
        window.selectedZone = nil
        window.selectedZoneId = nil
        window.selectedRect = nil
    end

    State.RefreshWindow(window)
    State.MarkDirty(window)
    return true
end

function State.MarkDirty(window)
    if not window then
        return
    end

    DC_ZoneDataStore.Commit(window.colonyId)
end

return State