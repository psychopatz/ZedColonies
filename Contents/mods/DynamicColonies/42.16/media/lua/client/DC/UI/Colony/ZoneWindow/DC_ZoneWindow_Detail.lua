-- ============================================================================
-- DC_ZoneWindow_Detail.lua — Detail panel logic for selected zone
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}
require "DC/UI/Colony/ZoneWindow/ZoneWindowState/DC_ZoneWindowState"

local Formatters = DC_ZoneWindow.Internal.Formatters


--- Refresh the detail panel to reflect the currently selected zone.
function DC_ZoneWindow:refreshDetailPanel()
    local zone = DC_ZoneWindowState.GetSelectedZone(self)

    -- Enable/disable controls based on selection
    local hasZone = zone ~= nil
    local hasRect = hasZone and DC_ZoneWindowState.GetSelectedRect(self) ~= nil
    if self.btnDeleteZone then self.btnDeleteZone:setEnable(hasZone) end
    if self.btnAddArea then self.btnAddArea:setEnable(hasZone) end
    if self.btnDeleteArea then self.btnDeleteArea:setEnable(hasRect) end
    if self.btnShowArea then self.btnShowArea:setEnable(hasRect) end
    if self.btnEditArea then self.btnEditArea:setEnable(hasRect) end

    -- Nudge/Scale buttons
    if self.btnNudgeW_Main then self.btnNudgeW_Main:setEnable(hasRect) end
    if self.btnNudgeE_Main then self.btnNudgeE_Main:setEnable(hasRect) end
    if self.btnNudgeN_Main then self.btnNudgeN_Main:setEnable(hasRect) end
    if self.btnNudgeS_Main then self.btnNudgeS_Main:setEnable(hasRect) end

    if self.btnScaleW_Main then self.btnScaleW_Main:setEnable(hasRect) end
    if self.btnScaleE_Main then self.btnScaleE_Main:setEnable(hasRect) end
    if self.btnScaleN_Main then self.btnScaleN_Main:setEnable(hasRect) end
    if self.btnScaleS_Main then self.btnScaleS_Main:setEnable(hasRect) end

    if self.btnScaleW_Inn_Main then self.btnScaleW_Inn_Main:setEnable(hasRect) end
    if self.btnScaleE_Inn_Main then self.btnScaleE_Inn_Main:setEnable(hasRect) end
    if self.btnScaleN_Inn_Main then self.btnScaleN_Inn_Main:setEnable(hasRect) end
    if self.btnScaleS_Inn_Main then self.btnScaleS_Inn_Main:setEnable(hasRect) end


    -- Name entry
    if self.detailNameEntry then
        if hasZone then
            self.detailNameEntry:setText(zone.name or "")
            self.detailNameEntry:setEditable(true)
        else
            self.detailNameEntry:setText("")
            self.detailNameEntry:setEditable(false)
        end
    end

    -- Type combo
    if self.detailTypeCombo and hasZone then
        local types = DC_ZoneData.getTypeList()
        for i, t in ipairs(types) do
            if t.id == zone.zoneType then
                self.detailTypeCombo.selected = i
                break
            end
        end
    end

    -- Info label
    if self.detailInfoLabel then
        if hasZone then
            local count = zone.rects and #zone.rects or 0
            local totalTiles = 0
            for _, r in ipairs(zone.rects or {}) do
                totalTiles = totalTiles + ((math.abs(r[3] - r[1]) + 1) * (math.abs(r[4] - r[2]) + 1))
            end
            self.detailInfoLabel.name = tostring(count) .. " areas, " .. tostring(totalTiles) .. " total tiles"
        else
            self.detailInfoLabel.name = "No zone selected"
        end
    end

    -- Rect list
    self:populateRectList()
end


--- Rebuild the rect list for the selected zone.
function DC_ZoneWindow:populateRectList()
    if not self.rectList then return end

    self.rectList:clear()

    local zone = DC_ZoneWindowState.GetSelectedZone(self)
    if not zone or not zone.rects then return end

    for i, rect in ipairs(zone.rects) do
        local label = Formatters and Formatters.formatRectLabel
            and Formatters.formatRectLabel(rect, i)
            or ("Area #" .. tostring(i))

        self.rectList:addItem(label, { index = i, rect = rect })
    end
end


--- Handle mouse-down on the rect list.
function DC_ZoneWindow:onRectListMouseDown(item)
    if not item then return end

    local data = item
    if type(item) == "table" and item.item then
        data = item.item
    end

    if data and data.index then
        DC_ZoneWindowState.SetSelectedRect(self, data.index)
    end

end
