DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local function T(key, fallback, params)
    if DC and DC.Text and DC.Text.Get then
        return DC.Text.Get(key, params, fallback)
    end
    return fallback or key
end

function DC_MainWindow:updateFactionButton()
    if not self.btnFaction then
        return
    end

    local status = (DC_System and DC_System.GetOwnedFactionStatus and DC_System.GetOwnedFactionStatus()) or DC_MainWindow.cachedOwnedFactionStatus
    if status and status.faction then
        if status.needsNamingPrompt == true then
            self.btnFaction:setTitle(T("DCCommon_UI_MainWindow_FinalizeFaction", "Finalize Faction"))
        else
            self.btnFaction:setTitle(T("DCCommon_UI_MainWindow_OpenFaction", "Open Faction"))
        end
        self.btnFaction:setEnable(true)
        return
    end

    if status and (status.canCreate == true or status.createBlockedReason == "syncing") then
        self.btnFaction:setTitle(T("DCCommon_UI_MainWindow_ClaimSyncing", "Claim Syncing"))
        self.btnFaction:setEnable(true)
        return
    end

    if status and status.createBlockedReason == "headquarters_required" then
        self.btnFaction:setTitle(T("DCCommon_UI_MainWindow_HQRequired", "HQ Required"))
        self.btnFaction:setEnable(false)
        return
    end

    self.btnFaction:setTitle(T("DCCommon_UI_MainWindow_FactionLocked", "Faction Locked"))
    self.btnFaction:setEnable(false)
end

function DC_MainWindow:onOpenFaction()
    if not DC_System or not DC_System.OpenOwnedFactionManagement then
        self:updateStatus(T("DCCommon_UI_MainWindow_FactionManagementUnavailable", "Faction management is unavailable."))
        return
    end

    local ok, msg = DC_System.OpenOwnedFactionManagement()
    if msg and msg ~= "" then
        self:updateStatus(msg)
    elseif ok then
        self:updateStatus(T("DCCommon_UI_MainWindow_OpeningFactionManagement", "Opening faction management..."))
    end
end
