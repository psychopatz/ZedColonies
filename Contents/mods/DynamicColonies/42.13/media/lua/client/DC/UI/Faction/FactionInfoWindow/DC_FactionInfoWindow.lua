DC_FactionInfoWindow = DC_FactionInfoWindow or {}

local Window = DC_FactionInfoWindow

local function syncInstance()
    Window.instance = DT_FactionInfoWindow and DT_FactionInfoWindow.instance or nil
    return Window.instance
end

local function loadDynamicTradingFactionWindow()
    if DT_FactionInfoWindow and DT_FactionInfoWindow.Open then
        return true
    end

    local ok = pcall(require, "DT/UI/Faction/FactionInfoWindow/DT_FactionInfoWindow")
    if not ok then
        return false
    end

    return DT_FactionInfoWindow and DT_FactionInfoWindow.Open ~= nil
end

function Window.Open()
    if not loadDynamicTradingFactionWindow() then
        return false, "Faction Intelligence is unavailable because DynamicTrading is not active."
    end

    DT_FactionInfoWindow.Open()
    syncInstance()
    return true, nil
end

function Window.ToggleWindow()
    if not loadDynamicTradingFactionWindow() then
        return false, "Faction Intelligence is unavailable because DynamicTrading is not active."
    end

    if DT_FactionInfoWindow.ToggleWindow then
        DT_FactionInfoWindow.ToggleWindow()
    else
        DT_FactionInfoWindow.Open()
    end

    syncInstance()
    return true, nil
end

function Window.Refresh()
    if not loadDynamicTradingFactionWindow() then
        Window.instance = nil
        return false
    end

    syncInstance()
    if Window.instance and Window.instance.refreshList then
        Window.instance:refreshList()
        return true
    end

    return false
end

return Window
