DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

function DT_MainWindow.ToggleWindow()
    if DT_MainWindow.instance then
        if DT_MainWindow.instance:getIsVisible() then
            DT_MainWindow.instance:close()
        else
            DT_MainWindow.instance:setVisible(true)
            DT_MainWindow.instance:addToUIManager()
            DT_MainWindow.instance:bringToTop()
            DT_MainWindow.instance:populateWorkerList(DT_MainWindow.cachedWorkers or {})
            if DT_MainWindow.instance.onRefresh then
                DT_MainWindow.instance:onRefresh()
            end
            DT_MainWindow.instance:updateStatus("Labour Management opened.")
        end
        return
    end

    DT_MainWindow.Open()
end

function DT_MainWindow.Open()
    if DT_MainWindow.instance then
        DT_MainWindow.instance:setVisible(true)
        DT_MainWindow.instance:addToUIManager()
        DT_MainWindow.instance:bringToTop()
        DT_MainWindow.instance:populateWorkerList(DT_MainWindow.cachedWorkers or {})
        if DT_MainWindow.instance.onRefresh then
            DT_MainWindow.instance:onRefresh()
        end
        DT_MainWindow.instance:updateStatus("Labour Management opened.")
        return
    end

    local width = 1080
    local height = 680
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    local window = DT_MainWindow:new(x, y, width, height)
    window:initialise()
    window:instantiate()
    window:setVisible(true)
    window:addToUIManager()
    window:bringToTop()
    DT_MainWindow.instance = window
    if window.onRefresh then
        window:onRefresh()
    end
end

function DT_MainWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function DT_MainWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Labour Management"
    o.resizable = true
    return o
end
