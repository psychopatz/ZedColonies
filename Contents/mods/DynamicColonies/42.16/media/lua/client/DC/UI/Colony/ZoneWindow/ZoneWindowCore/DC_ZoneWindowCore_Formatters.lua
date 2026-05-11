-- ============================================================================
-- DC_ZoneWindowCore_Formatters.lua — Display helpers for zone UI
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}

local Formatters = {}
DC_ZoneWindow.Internal.Formatters = Formatters


--- Format a zone for display in the list.
--- @param zone table
--- @return string  e.g. "Farmland (3 areas)"
function Formatters.formatZoneLabel(zone)
    if not zone then return "???" end
    local count = zone.rects and #zone.rects or 0
    local suffix = count == 1 and "1 area" or (tostring(count) .. " areas")
    return tostring(zone.name) .. "  (" .. suffix .. ")"
end


--- Format a rect for display in the rect list.
--- @param rect table  {x1, y1, x2, y2, z}
--- @param index number
--- @return string  e.g. "Area #1: 120x80 @ (4500, 6200)"
function Formatters.formatRectLabel(rect, index)
    if not rect then return "???" end
    local w = math.abs(rect[3] - rect[1]) + 1
    local h = math.abs(rect[4] - rect[2]) + 1
    return "Area #" .. tostring(index) .. ": " .. tostring(w) .. "x" .. tostring(h)
        .. " @ (" .. tostring(math.floor(rect[1])) .. ", " .. tostring(math.floor(rect[2])) .. ")"
end


--- Get the zone type label from a zone table.
--- @param zone table
--- @return string
function Formatters.getTypeLabel(zone)
    if not zone then return "Unknown" end
    local def = DC_ZoneData and DC_ZoneData.getTypeDef and DC_ZoneData.getTypeDef(zone)
    if def then return def.label end
    return tostring(zone.zoneType or "Unknown")
end
