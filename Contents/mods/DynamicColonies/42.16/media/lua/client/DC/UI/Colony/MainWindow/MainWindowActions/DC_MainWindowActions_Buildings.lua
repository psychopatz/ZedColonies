local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return fallback or key
end

function DC_MainWindow:onOpenBuildings()
    if DC_BuildingsWindow and DC_BuildingsWindow.Open then
        DC_BuildingsWindow.Open(self)
        self:updateStatus(T("DCCommon_UI_MainWindow_OpeningColonyMap", "Opening Colony Map..."))
    end
end
