DC_Base = DC_Base or {}
DC_Base.Internal = DC_Base.Internal or {}

local Base = DC_Base
local Internal = Base.Internal

local function removeMirroredHeadquarters(ownerUsername)
    if not DC_Buildings or not DC_Buildings.GetBuildingsForOwner then
        return
    end

    local buildings = DC_Buildings.GetBuildingsForOwner(ownerUsername) or {}
    local index = #buildings
    while index >= 1 do
        local instance = buildings[index]
        if tostring(instance and instance.buildingType or "") == "Headquarters" then
            table.remove(buildings, index)
        end
        index = index - 1
    end
    if DC_Buildings.Save then
        DC_Buildings.Save(ownerUsername)
    end
end

local function getZoneRectBounds(rect)
    local x1 = math.min(tonumber(rect and rect[1]) or 0, tonumber(rect and rect[3]) or 0)
    local x2 = math.max(tonumber(rect and rect[1]) or 0, tonumber(rect and rect[3]) or 0)
    local y1 = math.min(tonumber(rect and rect[2]) or 0, tonumber(rect and rect[4]) or 0)
    local y2 = math.max(tonumber(rect and rect[2]) or 0, tonumber(rect and rect[4]) or 0)
    local z = math.floor(tonumber(rect and rect[5]) or 0)
    return x1, y1, x2, y2, z
end

local function zoneArea(zone)
    local total = 0
    for _, rect in ipairs(zone and zone.rects or {}) do
        local x1, y1, x2, y2 = getZoneRectBounds(rect)
        total = total + ((x2 - x1 + 1) * (y2 - y1 + 1))
    end
    return total
end

function Base.GetZones(ownerUsername)
    local state = Internal.EnsureState(ownerUsername, true)
    if not state then
        return {}
    end

    local zones = {}
    for _, zone in ipairs(state.zones or {}) do
        zones[#zones + 1] = DC_ZoneData.cloneZone and DC_ZoneData.cloneZone(zone) or Internal.Clone(zone)
    end
    table.sort(zones, function(a, b)
        return tostring(a.name or a.id or "") < tostring(b.name or b.id or "")
    end)
    return zones
end

function Base.GetBaseZone(ownerUsername)
    local state = Internal.EnsureState(ownerUsername, true)
    if not state then
        return nil
    end

    local wantedID = tostring(state.base.baseZoneID or "")
    for _, zone in ipairs(state.zones or {}) do
        if tostring(zone and zone.zoneType or "") == "base" then
            if wantedID == "" or tostring(zone.id or "") == wantedID then
                return DC_ZoneData.cloneZone and DC_ZoneData.cloneZone(zone) or Internal.Clone(zone)
            end
        end
    end
    return nil
end

function Base.CanCreateOrResizeBaseZone(ownerUsername, rect)
    local state = Internal.EnsureState(ownerUsername, true)
    if not state then
        return false, "Base data is unavailable."
    end
    if type(rect) ~= "table" then
        return false, "Base area is invalid."
    end

    local x1, y1, x2, y2 = getZoneRectBounds(rect)
    local maxWidth, maxHeight = Internal.GetTierRectCaps(1)
    local width = x2 - x1 + 1
    local height = y2 - y1 + 1
    if width > maxWidth or height > maxHeight then
        return false, "Tier 1 HQ supports a base up to " .. tostring(maxWidth) .. "x" .. tostring(maxHeight) .. "."
    end
    return true, nil
end

function Base.ValidateZonesForOwner(ownerUsername, zones)
    local sanitized = {}
    local baseZoneCount = 0

    for _, zone in ipairs(type(zones) == "table" and zones or {}) do
        local sanitizedZone = DC_ZoneData.cloneZone and DC_ZoneData.cloneZone(zone) or Internal.Clone(zone)
        if type(sanitizedZone) == "table" then
            sanitizedZone.zoneType = tostring(sanitizedZone.zoneType or "roaming")
            sanitizedZone.name = tostring(sanitizedZone.name or "Zone")
            sanitizedZone.colonyId = tostring(sanitizedZone.colonyId or "")
            sanitizedZone.rects = type(sanitizedZone.rects) == "table" and sanitizedZone.rects or {}
            if sanitizedZone.zoneType == "base" then
                baseZoneCount = baseZoneCount + 1
                if #sanitizedZone.rects > 1 then
                    return false, "The base zone can only have one area.", nil
                end
                if sanitizedZone.rects[1] then
                    local ok, reason = Base.CanCreateOrResizeBaseZone(ownerUsername, sanitizedZone.rects[1])
                    if not ok then
                        return false, reason, nil
                    end
                end
            end
            sanitized[#sanitized + 1] = sanitizedZone
        end
    end

    if baseZoneCount > 1 then
        return false, "Only one base zone can exist per colony.", nil
    end

    return true, nil, sanitized
end

function Base.ReplaceZones(ownerUsername, zones)
    local state = Internal.EnsureState(ownerUsername, true)
    if not state then
        return false, "Colony data is unavailable.", nil
    end

    local ok, reason, sanitized = Base.ValidateZonesForOwner(ownerUsername, zones)
    if not ok then
        return false, reason, nil
    end

    state.colonyData.zones = sanitized

    local currentBaseZoneID = tostring(state.base.baseZoneID or "")
    local foundBaseZoneID = ""
    for _, zone in ipairs(sanitized or {}) do
        if tostring(zone.zoneType or "") == "base" then
            foundBaseZoneID = tostring(zone.id or "")
            break
        end
    end

    if currentBaseZoneID ~= "" and currentBaseZoneID ~= foundBaseZoneID then
        state.base.baseZoneID = foundBaseZoneID
    elseif currentBaseZoneID == "" then
        state.base.baseZoneID = foundBaseZoneID
    end

    if state.base.baseMode == Base.Constants.Modes.Settled and foundBaseZoneID == "" then
        state.base.baseMode = Base.Constants.Modes.Nomad
        state.base.hqTier = 0
        state.base.hqEntityType = ""
        state.base.hqX = 0
        state.base.hqY = 0
        state.base.hqZ = 0
        state.base.placedStructures = {}
        removeMirroredHeadquarters(ownerUsername)
    end

    Internal.Save(ownerUsername, "zones")
    return true, nil, Base.GetZones(ownerUsername)
end

function Base.BuildClientSnapshot(ownerUsername)
    local state = Base.GetBaseState(ownerUsername)
    local zones = Base.GetZones(ownerUsername)
    local baseZone = Base.GetBaseZone(ownerUsername)
    local maxWidth, maxHeight = Internal.GetTierRectCaps(1)
    local status = "No base zone."

    if baseZone and state and state.baseMode == Base.Constants.Modes.Settled and state.hqInsideBase then
        status = "Base finalized."
    elseif baseZone and state and state.hqEntityType and state.hqEntityType ~= "" then
        status = "HQ is outside the base zone."
    elseif baseZone then
        status = "Base zone ready. Place HQ inside it."
    end

    return {
        base = state,
        zones = zones,
        validation = {
            statusText = status,
            tierMaxWidth = maxWidth,
            tierMaxHeight = maxHeight,
            totalZoneArea = (function()
                local total = 0
                for _, zone in ipairs(zones or {}) do
                    total = total + zoneArea(zone)
                end
                return total
            end)(),
        }
    }
end

return Base
