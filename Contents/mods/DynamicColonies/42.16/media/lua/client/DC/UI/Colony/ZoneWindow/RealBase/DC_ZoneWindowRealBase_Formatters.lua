DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}
DC_ZoneWindow.Internal.RealBase = DC_ZoneWindow.Internal.RealBase or {}

require "DC/Common/Colony/Woodcut/DC_Colony_Woodcut"

local RealBaseUI = DC_ZoneWindow.Internal.RealBase

function RealBaseUI.FormatZoneLabel(zone)
    if not zone then
        return "???"
    end

    local slots = DC_ZoneRealBase and DC_ZoneRealBase.GetAreaSlots and DC_ZoneRealBase.GetAreaSlots(zone) or {}
    local count = #slots
    local suffix = count == 1 and "1 area" or (tostring(count) .. " areas")
    return tostring(zone.name or "Zone") .. "  (" .. suffix .. ")"
end

function RealBaseUI.FormatAreaLabel(slot, index)
    if not slot then
        return "Area #" .. tostring(index or 1)
    end

    local label = tostring(slot.label or ("Area #" .. tostring(index or 1)))
    local rect = slot.rect
    if not rect then
        return label .. ": Unassigned"
    end

    local w = math.abs(rect[3] - rect[1]) + 1
    local h = math.abs(rect[4] - rect[2]) + 1
    return label .. ": " .. tostring(w) .. "x" .. tostring(h)
        .. " @ (" .. tostring(math.floor(rect[1])) .. ", " .. tostring(math.floor(rect[2])) .. ")"
end

function RealBaseUI.BuildInfoText(window, zone)
    local slots = DC_ZoneRealBase and DC_ZoneRealBase.GetAreaSlots and DC_ZoneRealBase.GetAreaSlots(zone) or {}
    local assigned = 0
    local assignedTiles = 0

    for _, slot in ipairs(slots) do
        if slot.rect then
            assigned = assigned + 1
            assignedTiles = assignedTiles + (DC_ZoneRealBase and DC_ZoneRealBase.GetRectTileCount and DC_ZoneRealBase.GetRectTileCount(slot.rect) or 0)
        end
    end

    local text = tostring(#slots) .. " area slots, " .. tostring(assignedTiles) .. " assigned tiles"
    if tostring(zone and zone.zoneKind or "") == "base" then
        local allowed = RealBaseUI.GetValidationOptions(window).allowedBaseTiles or 0
        text = text .. " | Budget " .. tostring(assignedTiles) .. " / " .. tostring(allowed)
    else
        local areaTileCap = RealBaseUI.GetValidationOptions(window).areaTileCap
        if tonumber(areaTileCap) and tonumber(areaTileCap) > 0 then
            text = text .. " | Slot cap " .. tostring(math.floor(tonumber(areaTileCap) or 0))
        end
    end

    if DC_Colony and DC_Colony.Woodcut and tostring(zone and zone.zoneType or "") == "woodcut" then
        local state = DC_Colony.Woodcut.GetOrCreateZoneState(zone.ownerUsername, zone)
        text = text .. " | " .. tostring(DC_Colony.Woodcut.GetCoverageText(state))
    end
    return text
end

function RealBaseUI.GetWoodcutCoverageText(zone)
    if not zone or tostring(zone.zoneType or "") ~= "woodcut" then
        return nil
    end
    if not DC_Colony or not DC_Colony.Woodcut then
        return "Trees ?"
    end
    local state = DC_Colony.Woodcut.GetOrCreateZoneState(zone.ownerUsername, zone)
    return DC_Colony.Woodcut.GetCoverageText(state)
end

return RealBaseUI
