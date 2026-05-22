DC_MainWindow = DC_MainWindow or {}

local function buildResetConfirmationText()
    return "Reset all living colony NPCs to your current base?\n\n"
        .. "This will force-home companions and residents, clear active travel, "
        .. "and snap any live projected body back to your base anchor."
end

function DC_MainWindow:onResetNPCs()
    local function onConfirm(_, button)
        if not button or button.internal ~= "YES" then
            self:updateStatus("NPC reset cancelled.")
            return
        end

        self:updateStatus("Resetting colony NPCs to your current base...")
        if not self:sendColonyCommand("ResetAllOwnedNPCsToBase", {}) then
            self:updateStatus("Unable to request colony NPC reset.")
        end
    end

    local modal = ISModalDialog:new(0, 0, 420, 220, buildResetConfirmationText(), true, nil, onConfirm, nil)
    modal:initialise()
    modal:addToUIManager()
end

return DC_MainWindow
