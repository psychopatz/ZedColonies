-- ============================================================================
-- DC_ZoneWindow_Lifecycle.lua — Open / Close logic for DC_ZoneWindow
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}


--- Static factory method to open the Zone Management window.
--- @param player IsoPlayer
--- @param colonyId string
--- @return DC_ZoneWindow
function DC_ZoneWindow.OpenWithOptions(player, colonyId, options)
    -- Close existing instance if open
    if DC_ZoneWindow.instance then
        DC_ZoneWindow.instance:close()
        DC_ZoneWindow.instance = nil
    end

    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local w = math.min(900, sw - 40)
    local h = math.min(600, sh - 40)
    local x = math.floor((sw - w) / 2)
    local y = math.floor((sh - h) / 2)

    local instance = DC_ZoneWindow:new(x, y, w, h, player, colonyId, options)
    instance:initialise()
    instance:instantiate()
    instance:addToUIManager()
    instance:setVisible(true)

    DC_ZoneWindow.instance = instance

    print("[DC_ZoneWindow] Opened zone management for colony: " .. tostring(colonyId))
    return instance
end

function DC_ZoneWindow.Open(player, colonyId)
    return DC_ZoneWindow.OpenWithOptions(player, colonyId, nil)
end

function DC_ZoneWindow.OpenRealBase(player, colonyId, context)
    if DC_ZoneWindow.Internal and DC_ZoneWindow.Internal.RealBase and DC_ZoneWindow.Internal.RealBase.Open then
        return DC_ZoneWindow.Internal.RealBase.Open(player, colonyId, context or {})
    end
    return DC_ZoneWindow.OpenWithOptions(player, colonyId, {
        mode = "realbase",
        realBaseContext = context or {}
    })
end


--- Close the window.
function DC_ZoneWindow:close()
    if DC_ZoneWindowState and DC_ZoneWindowState.FlushDirty then
        DC_ZoneWindowState.FlushDirty(self)
    end

    self:setVisible(false)
    self:removeFromUIManager()

    if DC_ZoneWindow.instance == self then
        DC_ZoneWindow.instance = nil
    end

    print("[DC_ZoneWindow] Closed.")
end
