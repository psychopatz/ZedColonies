DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}
DC_ZoneWindow.Internal.RealBase = DC_ZoneWindow.Internal.RealBase or {}

require "DC/UI/Colony/ZoneWindow/ZoneWindowState/DC_ZoneWindowState"

local RealBaseUI = DC_ZoneWindow.Internal.RealBase

local function getSelectedZone(window)
    return DC_ZoneWindowState.GetSelectedZone(window)
end

function RealBaseUI.GetSelectedSlot(window)
    local zone = getSelectedZone(window)
    if not zone then
        return nil, nil
    end

    local index = math.floor(tonumber(window and window.selectedRect) or 0)
    if index <= 0 then
        return nil, nil
    end

    local slots = DC_ZoneRealBase and DC_ZoneRealBase.GetAreaSlots and DC_ZoneRealBase.GetAreaSlots(zone) or {}
    return slots[index], index
end

local function findZoneCopy(zones, zoneID)
    for _, zone in ipairs(zones or {}) do
        if tostring(zone and zone.id or "") == tostring(zoneID or "") then
            return zone
        end
    end
    return nil
end

local function refresh(window, statusMessage, isError)
    if statusMessage ~= nil then
        RealBaseUI.SetStatus(window, statusMessage, isError)
    end
    if window.refreshDetailPanel then
        window:refreshDetailPanel()
    end
    if window.populateZoneList then
        window:populateZoneList()
    end
end

local function getSlotTileLimit(window, zone)
    local validationOptions = RealBaseUI.GetValidationOptions(window)
    if tostring(zone and zone.zoneKind or "") == "base" then
        return validationOptions.allowedBaseTiles
    end
    return validationOptions.areaTileCap
end

local function getRectTileCount(rect)
    return DC_ZoneRealBase and DC_ZoneRealBase.GetRectTileCount and DC_ZoneRealBase.GetRectTileCount(rect) or 0
end

local function getBaseGuideRects(window, zone)
    if not window or tostring(zone and zone.zoneKind or "") == "base" then
        return {}
    end

    local currentZones = DC_ZoneWindowState.GetZones(window)
    local baseZone = DC_ZoneRealBase and DC_ZoneRealBase.FindBaseZone and DC_ZoneRealBase.FindBaseZone(currentZones) or nil
    return type(baseZone and baseZone.rects) == "table" and baseZone.rects or {}
end

function RealBaseUI.PopulateAreaList(window)
    if not window or not window.rectList then
        return
    end

    window.rectList:clear()
    local zone = getSelectedZone(window)
    if not zone then
        return
    end

    local slots = DC_ZoneRealBase and DC_ZoneRealBase.GetAreaSlots and DC_ZoneRealBase.GetAreaSlots(zone) or {}
    if window.selectedRect == nil and #slots > 0 then
        window.selectedRect = 1
    end

    for index, slot in ipairs(slots) do
        window.rectList:addItem(RealBaseUI.FormatAreaLabel(slot, index), {
            index = index,
            slot = slot,
            rect = slot.rect
        })
    end
end

local function validateCandidate(window, zoneID, slotIndex, rect)
    local currentZones = DC_ZoneWindowState.GetZones(window)
    local candidateZones = DC_ZoneData.copyZones(currentZones)
    local candidateZone = findZoneCopy(candidateZones, zoneID)
    if not candidateZone then
        return false, "Unable to resolve the selected zone."
    end

    if not (DC_ZoneRealBase and DC_ZoneRealBase.SetAreaSlotRect and DC_ZoneRealBase.SetAreaSlotRect(candidateZone, slotIndex, rect)) then
        return false, "Unable to update that area slot."
    end

    local context = window and window.realBaseContext or {}
    return DC_ZoneRealBase.ValidateZonesForOwner(
        context.ownerUsername,
        candidateZones,
        RealBaseUI.GetValidationOptions(window)
    )
end

local function applyRect(window, slotIndex, rect)
    local zone = getSelectedZone(window)
    if not zone then
        return false
    end

    local ok, reason = validateCandidate(window, zone.id, slotIndex, rect)
    if ok ~= true then
        refresh(window, reason or "Unable to assign that area.", true)
        return false
    end

    DC_ZoneRealBase.SetAreaSlotRect(zone, slotIndex, rect)
    DC_ZoneWindowState.MarkDirty(window)
    refresh(window, "Area updated.", false)
    return true
end

local function openSelector(window, slotIndex, existingRect)
    local zone = getSelectedZone(window)
    if not zone then
        return
    end

    local color = DC_ZoneData.getColor(zone)
    local selector = DC_ZoneSelector:new(
        0, 0, 340, 260,
        window.player,
        {
            r = color.r or 0.2,
            g = color.g or 0.8,
            b = color.b or 0.2,
            a = 0.5,
        },
        function(x1, y1, x2, y2, z)
            applyRect(window, slotIndex, { x1, y1, x2, y2, z or 0 })
        end,
        zone.name,
        existingRect,
        {
            maxTiles = getSlotTileLimit(window, zone),
            tileLimitLabel = tostring(zone and zone.zoneKind or "") == "base" and "Base tile budget" or "Area tile cap",
            currentTiles = getRectTileCount(existingRect),
            currentTilesLabel = tostring(zone and zone.zoneKind or "") == "base" and "Current base tiles" or "Current assigned tiles",
            validateRect = function(x1, y1, x2, y2, z)
                return validateCandidate(window, zone.id, slotIndex, { x1, y1, x2, y2, z or 0 })
            end,
            guideRects = getBaseGuideRects(window, zone),
            guideColor = { r = 0.22, g = 0.88, b = 0.28, a = 0.14 }
        }
    )
    selector:initialise()
    selector:addToUIManager()
end

function RealBaseUI.OnAddArea(window)
    local slot, slotIndex = RealBaseUI.GetSelectedSlot(window)
    if not slot or slot.rect then
        return
    end
    openSelector(window, slotIndex, nil)
end

function RealBaseUI.OnEditArea(window)
    local slot, slotIndex = RealBaseUI.GetSelectedSlot(window)
    if not slot then
        return
    end
    openSelector(window, slotIndex, slot.rect or nil)
end

function RealBaseUI.OnDeleteArea(window)
    local slot, slotIndex = RealBaseUI.GetSelectedSlot(window)
    if not slot or not slot.rect then
        return
    end
    applyRect(window, slotIndex, nil)
end

function RealBaseUI.OnShowArea(window)
    local slot = RealBaseUI.GetSelectedSlot(window)
    slot = slot and slot.rect and slot or nil
    if not slot or not slot.rect then
        return
    end

    local rect = slot.rect
    local zone = getSelectedZone(window)
    local color = DC_ZoneData.getColor(zone)
    window._showAreaTicks = 0
    window._showAreaMax = 300
    window._showAreaData = {
        x1 = math.min(rect[1], rect[3]),
        y1 = math.min(rect[2], rect[4]),
        x2 = math.max(rect[1], rect[3]) + 1,
        y2 = math.max(rect[2], rect[4]) + 1,
        z = rect[5] or window.player:getZ(),
        r = color.r or 0.5,
        g = color.g or 0.5,
        b = color.b or 0.5,
        a = 0.6
    }
end

return RealBaseUI
