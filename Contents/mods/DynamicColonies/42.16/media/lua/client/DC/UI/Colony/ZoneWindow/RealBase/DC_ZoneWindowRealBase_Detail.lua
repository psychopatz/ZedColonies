DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}
DC_ZoneWindow.Internal.RealBase = DC_ZoneWindow.Internal.RealBase or {}

require "DC/UI/Colony/ZoneWindow/ZoneWindowState/DC_ZoneWindowState"

local RealBaseUI = DC_ZoneWindow.Internal.RealBase

function RealBaseUI.RefreshDetailPanel(window)
    local zone = DC_ZoneWindowState.GetSelectedZone(window)
    if zone and window and window.selectedRect == nil then
        local slots = DC_ZoneRealBase and DC_ZoneRealBase.GetAreaSlots and DC_ZoneRealBase.GetAreaSlots(zone) or {}
        if #slots > 0 then
            window.selectedRect = 1
        end
    end
    local slot, _ = RealBaseUI.GetSelectedSlot(window)
    local hasZone = zone ~= nil
    local hasSlot = slot ~= nil
    local hasRect = hasSlot and slot.rect ~= nil

    if window.btnDeleteZone then window.btnDeleteZone:setEnable(false) end
    if window.btnAddArea then window.btnAddArea:setEnable(false) end
    if window.btnDeleteArea then window.btnDeleteArea:setEnable(false) end
    if window.btnShowArea then window.btnShowArea:setEnable(hasRect) end
    if window.btnEditArea then
        window.btnEditArea:setEnable(hasSlot)
        window.btnEditArea:setTitle(hasRect and "Edit Area" or "Set Area")
    end

    if window.detailNameEntry then
        window._suppressZoneNameChange = true
        window.detailNameEntry:setText(hasZone and tostring(zone.name or "") or "")
        window._suppressZoneNameChange = false
    end
    if window.detailTypeCombo and hasZone then
        local types = DC_ZoneData.getTypeList()
        for i, entry in ipairs(types) do
            if tostring(entry.id or "") == tostring(zone.zoneType or "") then
                window.detailTypeCombo.selected = i
                break
            end
        end
    end
    if window.detailInfoLabel then
        window.detailInfoLabel:setName(hasZone and RealBaseUI.BuildInfoText(window, zone) or "No zone selected")
    end

    RealBaseUI.PopulateAreaList(window)
end

return RealBaseUI
