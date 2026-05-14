DC_ZoneRealBase = DC_ZoneRealBase or {}

local RealBase = DC_ZoneRealBase

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

local function buildAreaID(zone, sourceArea, fallbackIndex)
    local areaID = tostring(sourceArea and (sourceArea.areaID or sourceArea.id) or "")
    if areaID ~= "" then
        return areaID
    end

    local sourceKind = tostring(sourceArea and sourceArea.sourceKind or zone and zone.zoneKind or "area")
    local sourceBuildingID = tostring(sourceArea and sourceArea.sourceBuildingID or "")
    local base = "dcarea_" .. tostring(zone and zone.id or "zone") .. "_" .. tostring(fallbackIndex or 1)
    if sourceBuildingID ~= "" then
        base = base .. "_" .. sourceBuildingID
    end
    if sourceKind ~= "" then
        base = base .. "_" .. sourceKind
    end
    return base
end

function RealBase.BuildAreaSlot(args)
    args = type(args) == "table" and args or {}
    return {
        areaID = tostring(args.areaID or ""),
        label = tostring(args.label or "Area"),
        sourceKind = tostring(args.sourceKind or "manual"),
        sourceBuildingID = args.sourceBuildingID and tostring(args.sourceBuildingID) or nil,
        sourceBuildingType = args.sourceBuildingType and tostring(args.sourceBuildingType) or nil,
        sourceJobType = args.sourceJobType and tostring(args.sourceJobType) or nil,
        rect = normalizeRect(args.rect),
        createdAt = normalizeNumber(args.createdAt or (getTimestamp and getTimestamp() or os.time()), os.time())
    }
end

function RealBase.NormalizeAreaSlot(zone, slot, fallbackIndex)
    local normalized = copyDeep(type(slot) == "table" and slot or {})
    normalized.areaID = buildAreaID(zone, normalized, fallbackIndex)
    normalized.label = tostring(normalized.label or normalized.name or ("Area #" .. tostring(fallbackIndex or 1)))
    normalized.sourceKind = tostring(normalized.sourceKind or (zone and zone.zoneKind == "base" and "base" or "building") or "manual")
    if normalized.sourceBuildingID ~= nil and tostring(normalized.sourceBuildingID) ~= "" then
        normalized.sourceBuildingID = tostring(normalized.sourceBuildingID)
    else
        normalized.sourceBuildingID = nil
    end
    if normalized.sourceBuildingType ~= nil and tostring(normalized.sourceBuildingType) ~= "" then
        normalized.sourceBuildingType = tostring(normalized.sourceBuildingType)
    elseif zone and zone.sourceBuildingType ~= nil and tostring(zone.sourceBuildingType) ~= "" then
        normalized.sourceBuildingType = tostring(zone.sourceBuildingType)
    else
        normalized.sourceBuildingType = nil
    end
    if normalized.sourceJobType ~= nil and tostring(normalized.sourceJobType) ~= "" then
        normalized.sourceJobType = tostring(normalized.sourceJobType)
    elseif zone and zone.sourceJobType ~= nil and tostring(zone.sourceJobType) ~= "" then
        normalized.sourceJobType = tostring(zone.sourceJobType)
    else
        normalized.sourceJobType = nil
    end
    normalized.createdAt = normalizeNumber(normalized.createdAt or (getTimestamp and getTimestamp() or os.time()), os.time())
    normalized.rect = normalizeRect(normalized.rect or normalized.area or normalized.bounds)
    return normalized
end

function RealBase.NormalizeZoneShape(zone)
    if type(zone) ~= "table" then
        return zone
    end

    zone.zoneKind = tostring(zone.zoneKind or "")
    if zone.sourceBuildingType ~= nil and tostring(zone.sourceBuildingType) ~= "" then
        zone.sourceBuildingType = tostring(zone.sourceBuildingType)
    else
        zone.sourceBuildingType = nil
    end
    if zone.sourceJobType ~= nil and tostring(zone.sourceJobType) ~= "" then
        zone.sourceJobType = tostring(zone.sourceJobType)
    else
        zone.sourceJobType = nil
    end

    local areaSlots = {}
    if type(zone.areaSlots) == "table" then
        for index, slot in ipairs(zone.areaSlots) do
            areaSlots[#areaSlots + 1] = RealBase.NormalizeAreaSlot(zone, slot, index)
        end
    elseif type(zone.rects) == "table" and #zone.rects > 0 then
        for index, rect in ipairs(zone.rects) do
            areaSlots[#areaSlots + 1] = RealBase.NormalizeAreaSlot(zone, {
                label = "Area #" .. tostring(index),
                sourceKind = zone.zoneKind == "base" and "base" or "legacy",
                sourceBuildingType = zone.sourceBuildingType,
                rect = rect
            }, index)
        end
    end

    if zone.zoneKind == "base" then
        if #areaSlots <= 0 then
            areaSlots[1] = RealBase.NormalizeAreaSlot(zone, {
                label = "Base Area",
                sourceKind = "base",
                rect = nil
            }, 1)
        elseif #areaSlots > 1 then
            areaSlots = { areaSlots[1] }
        end
    end

    zone.areaSlots = areaSlots
    zone.rects = {}
    for _, slot in ipairs(areaSlots) do
        if slot.rect then
            zone.rects[#zone.rects + 1] = copyDeep(slot.rect)
        end
    end

    return zone
end

function RealBase.GetAreaSlots(zone)
    if type(zone) ~= "table" then
        return {}
    end
    RealBase.NormalizeZoneShape(zone)
    return zone.areaSlots or {}
end

function RealBase.GetAreaSlot(zone, index)
    local slots = RealBase.GetAreaSlots(zone)
    local wantedIndex = math.floor(tonumber(index) or 0)
    if wantedIndex <= 0 then
        return nil
    end
    return slots[wantedIndex]
end

function RealBase.SetAreaSlotRect(zone, index, rect)
    local slot = RealBase.GetAreaSlot(zone, index)
    if not slot then
        return false
    end
    slot.rect = normalizeRect(rect)
    RealBase.NormalizeZoneShape(zone)
    return true
end

function RealBase.GetRectTileCount(rect)
    if type(rect) ~= "table" then
        return 0
    end

    return (math.abs((rect[3] or 0) - (rect[1] or 0)) + 1) * (math.abs((rect[4] or 0) - (rect[2] or 0)) + 1)
end

function RealBase.GetZoneTileCount(zone)
    local total = 0
    for _, slot in ipairs(RealBase.GetAreaSlots(zone)) do
        total = total + RealBase.GetRectTileCount(slot.rect)
    end
    return total
end

return RealBase
