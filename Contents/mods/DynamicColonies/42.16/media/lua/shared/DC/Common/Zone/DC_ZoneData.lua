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


local function copyDeep(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = copyDeep(entry)
    end
    return copy
end

local function normalizeNumber(value, fallback)
    return math.floor(tonumber(value) or fallback or 0)
end

local function normalizeRect(rect)
    if type(rect) ~= "table" then
        return nil
    end

    local x1 = tonumber(rect[1] or rect.x1)
    local y1 = tonumber(rect[2] or rect.y1)
    local x2 = tonumber(rect[3] or rect.x2)
    local y2 = tonumber(rect[4] or rect.y2)
    if x1 == nil or y1 == nil or x2 == nil or y2 == nil then
        return nil
    end

    local z = tonumber(rect[5] or rect.z or 0) or 0
    return {
        normalizeNumber(math.min(x1, x2), 0),
        normalizeNumber(math.min(y1, y2), 0),
        normalizeNumber(math.max(x1, x2), 0),
        normalizeNumber(math.max(y1, y2), 0),
        normalizeNumber(z, 0)
    }
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


--- Check whether a zone type id is known.
function DC_ZoneData.isValidZoneType(zoneTypeId)
    return DC_ZoneData._typeById[tostring(zoneTypeId or "")] ~= nil
end


--- Return a normalized copy of a zone table.
function DC_ZoneData.normalizeZone(zone, colonyId, fallbackIndex, usedIds)
    if type(zone) ~= "table" then
        return nil
    end

    local normalized = copyDeep(zone)
    local zoneID = tostring(normalized.id or normalized.zoneID or "")
    if zoneID == "" or (usedIds and usedIds[zoneID]) then
        local timestamp = tostring(normalized.createdAt or (getTimestamp and getTimestamp() or os.time()))
        zoneID = "dczone_" .. tostring(colonyId or normalized.colonyId or "local") .. "_" .. tostring(fallbackIndex or 1) .. "_" .. timestamp
        while usedIds and usedIds[zoneID] do
            timestamp = tostring(tonumber(timestamp) or os.time())
            zoneID = zoneID .. "_" .. timestamp
        end
    end
    normalized.id = zoneID
    if usedIds then
        usedIds[zoneID] = true
    end

    normalized.name = tostring(normalized.name or ("Zone " .. tostring(fallbackIndex or 1)))
    normalized.zoneType = tostring(normalized.zoneType or "roaming")
    if not DC_ZoneData.isValidZoneType(normalized.zoneType) then
        normalized.zoneType = "roaming"
    end
    normalized.colonyId = tostring(colonyId or normalized.colonyId or "")
    normalized.createdAt = normalizeNumber(normalized.createdAt or (getTimestamp and getTimestamp() or os.time()), os.time())

    local rects = {}
    local sourceRects = type(normalized.rects) == "table" and normalized.rects or {}
    for _, rect in ipairs(sourceRects) do
        local normalizedRect = normalizeRect(rect)
        if normalizedRect then
            rects[#rects + 1] = normalizedRect
        end
    end
    normalized.rects = rects

    return normalized
end


--- Return a normalized array of zone tables.
function DC_ZoneData.normalizeZones(zones, colonyId)
    local normalizedZones = {}
    local usedIds = {}
    local sourceZones = type(zones) == "table" and zones or {}

    for index, zone in ipairs(sourceZones) do
        local normalizedZone = DC_ZoneData.normalizeZone(zone, colonyId, index, usedIds)
        if normalizedZone then
            normalizedZones[#normalizedZones + 1] = normalizedZone
        end
    end

    return normalizedZones
end


--- Deep copy helper for zone tables.
function DC_ZoneData.copyZone(zone)
    return copyDeep(zone)
end


--- Deep copy helper for zone arrays.
function DC_ZoneData.copyZones(zones)
    local copy = {}
    local sourceZones = type(zones) == "table" and zones or {}

    for index, zone in ipairs(sourceZones) do
        copy[index] = copyDeep(zone)
    end

    return copy
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
