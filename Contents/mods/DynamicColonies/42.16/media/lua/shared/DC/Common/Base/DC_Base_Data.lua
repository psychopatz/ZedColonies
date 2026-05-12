DC_Base = DC_Base or {}
DC_Base.Internal = DC_Base.Internal or {}

local Base = DC_Base
local Internal = Base.Internal
local Config = DC_Colony.Config
local Registry = DC_Colony.Registry

Base.Constants = Base.Constants or {
    Modes = {
        Nomad = "Nomad",
        Settled = "Settled",
    },
    StructureTypes = {
        Headquarters = "Headquarters",
    },
    HeadquartersEntityType = "Base.DCColonyHQ",
    HeadquartersBuildingType = "Headquarters",
    HeadquartersPlotX = 0,
    HeadquartersPlotY = 0,
    Tier1MaxWidth = 50,
    Tier1MaxHeight = 50,
    NearbyEdgeBuffer = 8,
    MaxVisibleHomeWorkers = 4,
}

local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = deepCopy(entry)
    end
    return copy
end

local function ensureArray(value)
    return type(value) == "table" and value or {}
end

local function normalizeStructureList(structures)
    local normalized = {}
    for _, entry in ipairs(ensureArray(structures)) do
        if type(entry) == "table" then
            normalized[#normalized + 1] = {
                structureType = tostring(entry.structureType or ""),
                entityType = tostring(entry.entityType or ""),
                x = math.floor(tonumber(entry.x) or 0),
                y = math.floor(tonumber(entry.y) or 0),
                z = math.floor(tonumber(entry.z) or 0),
                squareKey = tostring(entry.squareKey or ""),
            }
        end
    end
    return normalized
end

function Internal.Clone(value)
    return deepCopy(value)
end

function Internal.GetOwnerUsername(ownerUsername)
    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

function Internal.GetColonyData(ownerUsername, createIfMissing)
    if not Registry or not Registry.GetColonyData then
        return nil
    end
    return Registry.GetColonyData(ownerUsername, createIfMissing == true)
end

function Internal.NormalizeBaseData(colonyData)
    if type(colonyData) ~= "table" then
        return nil
    end

    colonyData.base = type(colonyData.base) == "table" and colonyData.base or {}
    local baseData = colonyData.base
    local constants = Base.Constants
    local modes = constants.Modes

    local baseMode = tostring(baseData.baseMode or modes.Nomad)
    if baseMode ~= modes.Settled then
        baseMode = modes.Nomad
    end

    baseData.baseMode = baseMode
    baseData.hqTier = math.max(0, math.min(1, math.floor(tonumber(baseData.hqTier) or 0)))
    baseData.hqEntityType = tostring(baseData.hqEntityType or "")
    baseData.hqX = math.floor(tonumber(baseData.hqX) or 0)
    baseData.hqY = math.floor(tonumber(baseData.hqY) or 0)
    baseData.hqZ = math.floor(tonumber(baseData.hqZ) or 0)
    baseData.baseZoneID = tostring(baseData.baseZoneID or "")
    baseData.placedStructures = normalizeStructureList(baseData.placedStructures)
    return baseData
end

function Internal.NormalizeZones(colonyData)
    if type(colonyData) ~= "table" then
        return {}
    end

    colonyData.zones = ensureArray(colonyData.zones)
    local normalized = {}
    for _, zone in ipairs(colonyData.zones) do
        if type(zone) == "table" then
            normalized[#normalized + 1] = DC_ZoneData.cloneZone and DC_ZoneData.cloneZone(zone) or deepCopy(zone)
        end
    end
    colonyData.zones = normalized
    return normalized
end

function Internal.EnsureState(ownerUsername, createIfMissing)
    local colonyData = Internal.GetColonyData(ownerUsername, createIfMissing)
    if not colonyData then
        return nil
    end

    local state = {
        ownerUsername = Internal.GetOwnerUsername(ownerUsername),
        colonyData = colonyData,
        base = Internal.NormalizeBaseData(colonyData),
        zones = Internal.NormalizeZones(colonyData),
    }
    return state
end

function Internal.TouchVersion(ownerUsername, kind)
    if not Registry then
        return 0
    end
    if kind == "base" and Registry.TouchBaseVersion then
        return Registry.TouchBaseVersion(ownerUsername)
    end
    if kind == "zones" and Registry.TouchZonesVersion then
        return Registry.TouchZonesVersion(ownerUsername)
    end
    if Registry.TouchColonyVersion then
        return Registry.TouchColonyVersion(ownerUsername)
    end
    return 0
end

function Internal.Save(ownerUsername, kind)
    Internal.TouchVersion(ownerUsername, kind)
    if Registry and Registry.Save then
        Registry.Save()
    end
end

function Internal.MakeSquareKey(x, y, z)
    return table.concat({
        tostring(math.floor(tonumber(x) or 0)),
        tostring(math.floor(tonumber(y) or 0)),
        tostring(math.floor(tonumber(z) or 0)),
    }, ":")
end

function Internal.GetTierRectCaps(tier)
    local level = math.max(0, math.floor(tonumber(tier) or 0))
    if level <= 1 then
        return Base.Constants.Tier1MaxWidth, Base.Constants.Tier1MaxHeight
    end
    return Base.Constants.Tier1MaxWidth, Base.Constants.Tier1MaxHeight
end

function Base.GetBaseState(ownerUsername)
    local state = Internal.EnsureState(ownerUsername, true)
    if not state then
        return nil
    end

    local baseZone = Base.GetBaseZone(ownerUsername)
    local baseData = state.base
    local zoneType = baseZone and DC_ZoneData.getTypeDef and DC_ZoneData.getTypeDef(baseZone) or nil
    local hasBaseZone = baseZone ~= nil
    local hqInsideBase = hasBaseZone
        and baseData.hqEntityType ~= ""
        and DC_ZoneData.isInsideZone(baseZone, baseData.hqX, baseData.hqY, baseData.hqZ)
        or false

    return {
        ownerUsername = state.ownerUsername,
        baseMode = baseData.baseMode,
        hqTier = baseData.hqTier,
        hqEntityType = baseData.hqEntityType ~= "" and baseData.hqEntityType or nil,
        hqX = baseData.hqEntityType ~= "" and baseData.hqX or nil,
        hqY = baseData.hqEntityType ~= "" and baseData.hqY or nil,
        hqZ = baseData.hqEntityType ~= "" and baseData.hqZ or nil,
        baseZoneID = baseData.baseZoneID ~= "" and baseData.baseZoneID or nil,
        hasBaseZone = hasBaseZone,
        hqInsideBase = hqInsideBase,
        baseZoneTypeLabel = zoneType and zoneType.label or nil,
        versions = shallowCopy(state.colonyData.versions),
    }
end

return Base
