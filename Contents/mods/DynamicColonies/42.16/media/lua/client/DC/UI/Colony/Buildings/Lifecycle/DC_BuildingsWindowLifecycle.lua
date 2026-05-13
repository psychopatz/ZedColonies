require "ISUI/ISCollapsableWindow"

DC_BuildingsWindowLifecycle = DC_BuildingsWindowLifecycle or {}

local Lifecycle = DC_BuildingsWindowLifecycle

function Lifecycle.New(windowClass, x, y, width, height, ownerWindow)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, windowClass)
    windowClass.__index = windowClass
    o.title = "Colony Map"
    o.resizable = true
    o.ownerWindow = ownerWindow
    o.autoRefreshFrames = 0
    o.snapshot = { map = { plots = {} } }
    o.selectedPlotKey = nil
    return o
end

function Lifecycle.Open(windowClass, ownerWindow)
    if windowClass.instance then
        windowClass.instance.ownerWindow = ownerWindow or windowClass.instance.ownerWindow
        windowClass.instance:setVisible(true)
        windowClass.instance:addToUIManager()
        windowClass.instance:bringToTop()
        windowClass.instance:requestSnapshot()
        return windowClass.instance
    end

    local width = 1080
    local height = 680
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local window = windowClass:new(x, y, width, height, ownerWindow)
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:bringToTop()
    windowClass.instance = window
    window:requestSnapshot()
    return window
end

function Lifecycle.OnResize(window)
    ISCollapsableWindow.onResize(window)
    if window.layoutChildren then
        window:layoutChildren()
    end
end

function Lifecycle.Prerender(window)
    ISCollapsableWindow.prerender(window)
    window.autoRefreshFrames = (tonumber(window.autoRefreshFrames) or 0) + 1
    if window.autoRefreshFrames >= (tonumber(window.AUTO_REFRESH_FRAMES) or 600) then
        window.autoRefreshFrames = 0
        window:requestSnapshot()
    end
end

function Lifecycle.Close(window)
    window:setVisible(false)
    window:removeFromUIManager()
end

return Lifecycle
