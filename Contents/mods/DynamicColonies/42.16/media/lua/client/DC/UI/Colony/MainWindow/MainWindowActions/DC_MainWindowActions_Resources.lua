local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return fallback or key
end

function DC_MainWindow:onOpenResources()
    if DC_ResourcesWindow and DC_ResourcesWindow.Open then
        DC_ResourcesWindow.Open(self)
        self:updateStatus(T("DCCommon_UI_MainWindow_OpeningResources", "Opening Resources..."))
    end
end
