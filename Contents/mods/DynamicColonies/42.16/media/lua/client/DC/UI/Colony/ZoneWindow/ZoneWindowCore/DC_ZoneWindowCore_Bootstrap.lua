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

