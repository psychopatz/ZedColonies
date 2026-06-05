DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return fallback or key
end

function DC_MainWindow.ToggleWindow(device)
    if DC_MainWindow.instance then
        if DC_MainWindow.instance:getIsVisible() then
            DC_MainWindow.instance:close()
        else
            DC_MainWindow.instance:setVisible(true)
            DC_MainWindow.instance:addToUIManager()
            DC_MainWindow.instance:bringToTop()
            DC_MainWindow.instance.device = device
            DC_MainWindow.instance:populateWorkerList(DC_MainWindow.cachedWorkers or {})
            if DC_MainWindow.instance.onRefresh then
                DC_MainWindow.instance:onRefresh()
            end
            DC_MainWindow.instance:updateStatus(T("DCCommon_UI_MainWindow_Open", "Colony Management opened."))
        end
        return
    end

    DC_MainWindow.Open(device)
end

function DC_MainWindow.Open(device)
    if DC_MainWindow.instance then
        DC_MainWindow.instance:setVisible(true)
        DC_MainWindow.instance:addToUIManager()
        DC_MainWindow.instance:bringToTop()
        DC_MainWindow.instance.device = device
        DC_MainWindow.instance:populateWorkerList(DC_MainWindow.cachedWorkers or {})
        if DC_MainWindow.instance.onRefresh then
            DC_MainWindow.instance:onRefresh()
        end
        DC_MainWindow.instance:updateStatus(T("DCCommon_UI_MainWindow_Open", "Colony Management opened."))
        return
    end

    local width = 1080
    local height = 680
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    local window = DC_MainWindow:new(x, y, width, height)
    window:initialise()
    window:instantiate()
    window.device = device
    window:setVisible(true)
    window:addToUIManager()
    window:bringToTop()
    DC_MainWindow.instance = window
    if window.onRefresh then
        window:onRefresh()
    end
end

function DC_MainWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DC_MainWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = T("DCCommon_UI_MainWindow_Title", "Colony Management")
    o.resizable = true
    return o
end
