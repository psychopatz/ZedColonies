-- ============================================================================
-- DC_ZoneData.lua — Shared zone data model for Dynamic Colonies
--
-- Defines zone types, zone instance creation, and point-in-zone checks.
-- No UI dependencies — safe to require on both client and server.
-- ============================================================================

DC_ZoneData = DC_ZoneData or {}

-- ---------------------------------------------------------------------------
-- Zone Type Definitions
-- ---------------------------------------------------------------------------

DC_ZoneTypes = {
    BASE      = { id = "base",      label = "Base",        color = {0.95, 0.65, 0.18, 0.35} },
    ROAMING   = { id = "roaming",   label = "Roaming",     color = {0.30, 0.70, 1.00, 0.30} },
    FARMING   = { id = "farming",   label = "Farming",     color = {0.20, 0.80, 0.20, 0.30} },
    WOODCUT   = { id = "woodcut",   label = "Woodcutting", color = {0.60, 0.40, 0.10, 0.30} },
    MINING    = { id = "mining",    label = "Mining",       color = {0.50, 0.50, 0.50, 0.30} },
    STORAGE   = { id = "storage",   label = "Storage",     color = {0.80, 0.80, 0.20, 0.30} },
    EXCLUSION = { id = "exclusion", label = "Exclusion",   color = {0.80, 0.10, 0.10, 0.30} },
}

-- Lookup by id string → type table
DC_ZoneData._typeById = {}
for key, def in pairs(DC_ZoneTypes) do
    DC_ZoneData._typeById[def.id] = def
end


-- ---------------------------------------------------------------------------
-- Zone Instance Factory
-- ---------------------------------------------------------------------------

local _nextId = 0

--- Create a new zone instance.
--- @param name string       Display name for the zone
--- @param zoneTypeId string One of the DC_ZoneTypes id strings (e.g. "farming")
--- @param colonyId string   Colony this zone belongs to
--- @return table            The new zone table
function DC_ZoneData.createZone(name, zoneTypeId, colonyId)
    _nextId = _nextId + 1
    local id = "dczone_" .. tostring(getTimestamp and getTimestamp() or os.time()) .. "_" .. tostring(_nextId)

    return {
        id         = id,
        name       = name or ("Zone " .. tostring(_nextId)),
        zoneType   = zoneTypeId or "roaming",
        colonyId   = colonyId or "",
        rects      = {},   -- { {x1,y1,x2,y2,z}, ... }
        createdAt  = getTimestamp and getTimestamp() or os.time(),
    }
end


-- ---------------------------------------------------------------------------
-- Rect Management
-- ---------------------------------------------------------------------------

--- Add a rectangular area to a zone.
--- @param zone table  The zone table
--- @param x1 number   Start X (world)
--- @param y1 number   Start Y (world)
--- @param x2 number   End X (world)
--- @param y2 number   End Y (world)
--- @param z  number   Floor level
function DC_ZoneData.addRect(zone, x1, y1, x2, y2, z)
    if not zone or not zone.rects then return end

    -- Normalise so x1 <= x2, y1 <= y2
    local rx1 = math.min(x1, x2)
    local ry1 = math.min(y1, y2)
    local rx2 = math.max(x1, x2)
    local ry2 = math.max(y1, y2)

    table.insert(zone.rects, { rx1, ry1, rx2, ry2, z or 0 })
end

function DC_ZoneData.cloneZone(zone)
    if type(zone) ~= "table" then
        return nil
    end

    local copy = {
        id = tostring(zone.id or ""),
        name = tostring(zone.name or "Zone"),
        zoneType = tostring(zone.zoneType or "roaming"),
        colonyId = tostring(zone.colonyId or ""),
        rects = {},
        createdAt = zone.createdAt,
    }

    for _, rect in ipairs(zone.rects or {}) do
        copy.rects[#copy.rects + 1] = {
            math.floor(tonumber(rect[1]) or 0),
            math.floor(tonumber(rect[2]) or 0),
            math.floor(tonumber(rect[3]) or 0),
            math.floor(tonumber(rect[4]) or 0),
            math.floor(tonumber(rect[5]) or 0),
        }
    end

    return copy
end

function DC_ZoneData.getRectWidth(rect)
    if type(rect) ~= "table" then
        return 0
    end
    return math.abs((tonumber(rect[3]) or 0) - (tonumber(rect[1]) or 0)) + 1
end

function DC_ZoneData.getRectHeight(rect)
    if type(rect) ~= "table" then
        return 0
    end
    return math.abs((tonumber(rect[4]) or 0) - (tonumber(rect[2]) or 0)) + 1
end

function DC_ZoneData.getRectTileCount(rect)
    return DC_ZoneData.getRectWidth(rect) * DC_ZoneData.getRectHeight(rect)
end

function DC_ZoneData.nudgeRect(rect, dx, dy)
    if type(rect) ~= "table" then
        return
    end
    rect[1] = math.floor((tonumber(rect[1]) or 0) + (tonumber(dx) or 0))
    rect[2] = math.floor((tonumber(rect[2]) or 0) + (tonumber(dy) or 0))
    rect[3] = math.floor((tonumber(rect[3]) or 0) + (tonumber(dx) or 0))
    rect[4] = math.floor((tonumber(rect[4]) or 0) + (tonumber(dy) or 0))
end

function DC_ZoneData.scaleRect(rect, edge, amount)
    if type(rect) ~= "table" then
        return
    end

    local delta = math.floor(tonumber(amount) or 0)
    local x1 = math.min(tonumber(rect[1]) or 0, tonumber(rect[3]) or 0)
    local x2 = math.max(tonumber(rect[1]) or 0, tonumber(rect[3]) or 0)
    local y1 = math.min(tonumber(rect[2]) or 0, tonumber(rect[4]) or 0)
    local y2 = math.max(tonumber(rect[2]) or 0, tonumber(rect[4]) or 0)

    if edge == "W" then
        x1 = x1 - delta
    elseif edge == "E" then
        x2 = x2 + delta
    elseif edge == "N" then
        y1 = y1 - delta
    elseif edge == "S" then
        y2 = y2 + delta
    end

    if x2 <= x1 then
        x2 = x1 + 1
    end
    if y2 <= y1 then
        y2 = y1 + 1
    end

    rect[1] = x1
    rect[2] = y1
    rect[3] = x2
    rect[4] = y2
end


--- Remove a rect from a zone by index.
--- @param zone  table   The zone table
--- @param index number  1-based index into zone.rects
function DC_ZoneData.removeRect(zone, index)
    if not zone or not zone.rects then return end
    if index >= 1 and index <= #zone.rects then
        table.remove(zone.rects, index)
    end
end


-- ---------------------------------------------------------------------------
-- Queries
-- ---------------------------------------------------------------------------

--- Check if a world point is inside any rect of a zone.
--- @param zone table
--- @param x number
--- @param y number
--- @param z number   (optional, matched if present in rect)
--- @return boolean
function DC_ZoneData.isInsideZone(zone, x, y, z)
    if not zone or not zone.rects then return false end
    for _, r in ipairs(zone.rects) do
        if x >= r[1] and x <= r[3] and y >= r[2] and y <= r[4] then
            if z == nil or r[5] == nil or z == r[5] then
                return true
            end
        end
    end
    return false
end


--- Get the zone type definition for a zone instance.
--- @param zone table
--- @return table|nil  The DC_ZoneTypes entry, or nil
function DC_ZoneData.getTypeDef(zone)
    if not zone then return nil end
    return DC_ZoneData._typeById[zone.zoneType]
end


--- Get the colour for a zone (from its type).
--- @param zone table
--- @return table  {r, g, b, a}
function DC_ZoneData.getColor(zone)
    local def = DC_ZoneData.getTypeDef(zone)
    if def and def.color then
        return { r = def.color[1], g = def.color[2], b = def.color[3], a = def.color[4] }
    end
    return { r = 0.5, g = 0.5, b = 0.5, a = 0.3 }
end


--- Get all zone type ids as a simple list (for combo boxes).
--- @return table  Array of { id = "...", label = "..." }
function DC_ZoneData.getTypeList()
    local list = {}
    for _, def in pairs(DC_ZoneTypes) do
        table.insert(list, { id = def.id, label = def.label })
    end
    -- Sort alphabetically for consistent display
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end


return DC_ZoneData
