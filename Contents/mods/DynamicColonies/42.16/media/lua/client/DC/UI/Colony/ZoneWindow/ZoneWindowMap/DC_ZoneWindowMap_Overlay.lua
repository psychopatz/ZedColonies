-- ============================================================================
-- DC_ZoneWindowMap_Overlay.lua — Zone rendering on PZ map widget
--
-- Draws all zone rects on the map with type-based colours, highlights the
-- selected zone/rect with bright borders, and shows zone labels.
-- Inspired by PhunZones2/ui_map_overlay.lua.
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}

require "DC/UI/Colony/ZoneWindow/RealBase/DC_ZoneWindowRealBase_Formatters"

local FONT = UIFont.Small
local FONT_HGT = getTextManager():getFontHeight(FONT)
local LABEL_PAD_X = 6
local LABEL_PAD_Y = 3

local MapOverlay = {}
MapOverlay.__index = MapOverlay
DC_ZoneWindow.Internal.MapOverlay = MapOverlay


-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

function MapOverlay:new(mapWidget)
    local o = setmetatable({}, self)
    o.mapWidget = mapWidget
    o.zones = {}              -- array of zone tables
    o.selectedZoneId = nil
    o.selectedRectIdx = nil
    return o
end


-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function MapOverlay:setZones(zones)
    self.zones = zones or {}
end

function MapOverlay:setSelected(zoneId, rectIdx)
    self.selectedZoneId = zoneId
    self.selectedRectIdx = rectIdx
end


-- ---------------------------------------------------------------------------
-- Coordinate helpers
-- ---------------------------------------------------------------------------

function MapOverlay:_api()
    return self.mapWidget and self.mapWidget.mapAPI
end

function MapOverlay:_wToS(wx, wy)
    local api = self:_api()
    if not api then return 0, 0 end
    return api:worldToUIX(wx, wy), api:worldToUIY(wx, wy)
end

function MapOverlay:_rectToScreen(rect)
    local x1s, y1s = self:_wToS(rect[1], rect[2])
    local x2s, y2s = self:_wToS(rect[3], rect[4])
    if x1s > x2s then x1s, x2s = x2s, x1s end
    if y1s > y2s then y1s, y2s = y2s, y1s end
    return math.floor(x1s), math.floor(y1s), math.ceil(x2s), math.ceil(y2s)
end


-- ---------------------------------------------------------------------------
-- Rendering — called from the hooked map widget render
-- ---------------------------------------------------------------------------

function MapOverlay:render(widget)
    if not self:_api() then return end
    self:_renderZones(widget)
end


function MapOverlay:_renderZones(widget)
    -- Draw unselected zones first, selected last (on top)
    local selectedZone = nil

    for _, zone in ipairs(self.zones) do
        if zone.id == self.selectedZoneId then
            selectedZone = zone
        else
            self:_renderZone(widget, zone, false)
        end
    end

    -- Draw selected zone on top
    if selectedZone then
        self:_renderZone(widget, selectedZone, true)
    end
end


function MapOverlay:_renderZone(widget, zone, isSelected)
    if not zone or not zone.rects then return end

    local color = DC_ZoneData.getColor(zone)
    local fillA = isSelected and 0.35 or 0.18
    local borderA = isSelected and 1.0 or 0.5
    local borderW = isSelected and 2 or 1

    for ptIdx, rect in ipairs(zone.rects) do
        local x1, y1, x2, y2 = self:_rectToScreen(rect)
        local w = x2 - x1
        local h = y2 - y1

        if w >= 2 and h >= 2 then
            local isActiveRect = isSelected and (ptIdx == self.selectedRectIdx)

            -- Fill
            widget:drawRect(x1, y1, w, h, fillA, color.r, color.g, color.b)

            -- Border
            widget:drawRectBorder(x1, y1, w, h, borderA, color.r, color.g, color.b)
            if isSelected then
                widget:drawRectBorder(x1 + 1, y1 + 1, w - 2, h - 2, borderA * 0.4, color.r, color.g, color.b)
            end

            -- Active rect gets an orange accent
            if isActiveRect then
                widget:drawRectBorder(x1, y1, w, h, 0.9, 0.9, 0.55, 0.1)
                widget:drawRectBorder(x1 + 1, y1 + 1, w - 2, h - 2, 0.5, 0.9, 0.55, 0.1)
            end

            -- Label: show on first rect of each zone
            if ptIdx == 1 or isActiveRect then
                local label = zone.name or "Zone"
                if isSelected and DC_ZoneWindow.Internal and DC_ZoneWindow.Internal.RealBase
                    and DC_ZoneWindow.Internal.RealBase.GetWoodcutCoverageText then
                    local coverage = DC_ZoneWindow.Internal.RealBase.GetWoodcutCoverageText(zone)
                    if coverage and coverage ~= "" then
                        label = tostring(label) .. " | " .. tostring(coverage)
                    end
                end
                self:_drawLabel(widget, label, x1, y1, x2, y2, color, isSelected)
            end
        end
    end
end


function MapOverlay:_drawLabel(widget, label, x1, y1, x2, y2, color, bold)
    local w = x2 - x1
    local h = y2 - y1
    local lw = getTextManager():MeasureStringX(FONT, label)

    local lx = x1 + math.floor((w - lw) / 2)
    local ly = y1 + math.floor((h - FONT_HGT) / 2)

    -- Clamp inside widget
    lx = math.max(0, lx)

    -- Background pill
    local bx = lx - LABEL_PAD_X
    local by = ly - LABEL_PAD_Y
    local bw = lw + LABEL_PAD_X * 2
    local bh = FONT_HGT + LABEL_PAD_Y * 2
    widget:drawRect(bx, by, bw, bh, 0.78, 0.05, 0.05, 0.08)
    widget:drawRectBorder(bx, by, bw, bh, 0.4, color.r, color.g, color.b)

    local a = bold and 1.0 or 0.85
    widget:drawText(label, lx, ly, color.r, color.g, color.b, a, FONT)
end


-- ---------------------------------------------------------------------------
-- Hook into map widget's render pipeline
-- ---------------------------------------------------------------------------

function MapOverlay:hookMapWidget()
    local widget = self.mapWidget
    if not widget then return end

    local overlay = self
    local origRender = widget.render

    widget.render = function(s)
        if origRender then
            origRender(s)
        end
        overlay:render(s)
    end
end


return MapOverlay
