DC_MainWindow = DC_MainWindow or {}

local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return fallback or key
end

function DC_MainWindow:onOpenHelp()
    -- Redirected to the Manual system if Dynamic Trading is installed.
    self:updateStatus(T("DCCommon_UI_MainWindow_OpeningScavengingManual", "Opening scavenging manual..."))
end
