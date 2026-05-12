-- ============================================================================
-- DC_ZoneWindowCore_Bootstrap.lua — Constructor for DC_ZoneWindow
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}

function DC_ZoneWindow:new(x, y, width, height, player, colonyId)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player    = player
    o.colonyId  = colonyId or ""
    o.title     = "Zone Management"
    o.resizable = true
    o.moveWithMouse = true
    o.anchorRight   = true
    o.anchorBottom  = true

    -- State
    o.zones         = {}     -- ordered array of zone tables
    o.selectedZone  = nil    -- currently selected zone table
    o.selectedRect  = nil    -- 1-based index into selectedZone.rects
    o.baseSnapshot = {}
    o.baseSnapshotVersion = nil
    o.baseState = {}
    o.baseValidation = {}
    o.suppressZoneSave = false

    -- Minimum window size
    o.minimumWidth  = 600
    o.minimumHeight = 400

    return o
end


--- Render tick
function DC_ZoneWindow:prerender()
    ISCollapsableWindow.prerender(self)

    -- Handle 3D area highlight "flashing"
    if self.tickShowArea then
        self:tickShowArea()
    end
end

function DC_ZoneWindow:sendColonyCommand(command, args)
    if DC_System and DC_System.SendCommand then
        return DC_System.SendCommand(command, args or {})
    end

    local player = self.player or (getPlayer and getPlayer()) or nil
    if not player then
        return false
    end

    local module = (DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony"
    if isClient() and not isServer() then
        sendClientCommand(player, module, command, args or {})
        return true
    end

    if DC_Colony and DC_Colony.Network and DC_Colony.Network.HandleCommand then
        DC_Colony.Network.HandleCommand(player, command, args or {})
        return true
    end

    return false
end

function DC_ZoneWindow:requestBaseSnapshot()
    return self:sendColonyCommand("RequestBaseSnapshot", {
        knownVersion = self.baseSnapshotVersion
    })
end

function DC_ZoneWindow:commitZonesSnapshot()
    if self.suppressZoneSave then
        return false
    end

    local zones = {}
    for _, zone in ipairs(self.zones or {}) do
        zones[#zones + 1] = DC_ZoneData.cloneZone(zone)
    end
    return self:sendColonyCommand("SaveBaseZonesSnapshot", {
        zones = zones
    })
end

function DC_ZoneWindow:applyBaseSnapshot(snapshot, version)
    snapshot = type(snapshot) == "table" and snapshot or {}
    self.baseSnapshot = snapshot
    self.baseSnapshotVersion = version or self.baseSnapshotVersion
    self.baseState = type(snapshot.base) == "table" and snapshot.base or {}
    self.baseValidation = type(snapshot.validation) == "table" and snapshot.validation or {}

    local selectedZoneID = self.selectedZone and self.selectedZone.id or nil
    local selectedRect = self.selectedRect

    self.suppressZoneSave = true
    self.zones = {}
    for _, zone in ipairs(snapshot.zones or {}) do
        self.zones[#self.zones + 1] = DC_ZoneData.cloneZone(zone)
    end

    self.selectedZone = nil
    self.selectedRect = nil
    if selectedZoneID then
        for _, zone in ipairs(self.zones) do
            if tostring(zone.id or "") == tostring(selectedZoneID) then
                self.selectedZone = zone
                self.selectedRect = selectedRect
                break
            end
        end
    end

    self:populateZoneList()
    self:refreshDetailPanel()
    if self.mapPanel and self.mapPanel.refreshZones then
        self.mapPanel:refreshZones(self.zones, self.selectedZone)
    end
    self.suppressZoneSave = false
end
