require "DC/Common/Zone/DC_ZoneData"

DC_ZoneDataStore = DC_ZoneDataStore or {}

local Store = DC_ZoneDataStore

Store.MOD_DATA_KEY = Store.MOD_DATA_KEY or "DColony_Zones"
Store.EventsAdded = Store.EventsAdded or false

local function normalizeColonyId(colonyId)
    local text = tostring(colonyId or "")
    if text == "" then
        return "local"
    end
    return text
end

local function ensureModDataTable(key, defaults)
    if not ModData.exists(key) then
        ModData.add(key, defaults or {})
    end

    local data = ModData.get(key)
    if type(data) == "table" then
        return data
    end

    if ModData.remove then
        ModData.remove(key)
    end

    ModData.add(key, defaults or {})
    return ModData.get(key)
end

local function buildEmptyRoot()
    return {
        schemaVersion = 1,
        colonies = {}
    }
end

local function buildEmptyColony(colonyId)
    local normalizedColonyId = normalizeColonyId(colonyId)
    return {
        schemaVersion = 1,
        colonyId = normalizedColonyId,
        version = 1,
        zones = {}
    }
end

function Store.GetRoot()
    local root = ensureModDataTable(Store.MOD_DATA_KEY, buildEmptyRoot())
    if type(root.colonies) ~= "table" then
        root.colonies = {}
    end
    if type(root.schemaVersion) ~= "number" then
        root.schemaVersion = 1
    end
    return root
end

function Store.GetColonyRecord(colonyId)
    local root = Store.GetRoot()
    local normalizedColonyId = normalizeColonyId(colonyId)
    local record = root.colonies[normalizedColonyId]

    if type(record) ~= "table" then
        record = buildEmptyColony(normalizedColonyId)
        root.colonies[normalizedColonyId] = record
    end

    if type(record.zones) ~= "table" then
        record.zones = {}
    end
    if type(record.version) ~= "number" then
        record.version = 1
    end

    return record
end

function Store.GetZones(colonyId)
    return Store.GetColonyRecord(colonyId).zones
end

function Store.ReplaceZones(colonyId, zones)
    local record = Store.GetColonyRecord(colonyId)
    record.zones = DC_ZoneData.normalizeZones(zones, record.colonyId)
    return record.zones
end

function Store.GetColonyVersion(colonyId)
    return Store.GetColonyRecord(colonyId).version
end

function Store.SetColonyVersion(colonyId, version)
    local record = Store.GetColonyRecord(colonyId)
    record.version = math.max(1, math.floor(tonumber(version) or 1))
    return record.version
end

function Store.BuildSnapshot(colonyId)
    local record = Store.GetColonyRecord(colonyId)
    return {
        schemaVersion = record.schemaVersion or 1,
        colonyId = record.colonyId,
        version = record.version,
        zones = DC_ZoneData.normalizeZones(record.zones, record.colonyId)
    }
end

function Store.ApplySnapshot(colonyId, snapshot)
    local record = Store.GetColonyRecord(colonyId)
    local source = type(snapshot) == "table" and snapshot or {}
    local normalizedZones = DC_ZoneData.normalizeZones(source.zones or {}, record.colonyId)

    record.schemaVersion = math.max(1, math.floor(tonumber(source.schemaVersion) or record.schemaVersion or 1))
    record.colonyId = tostring(source.colonyId or record.colonyId or colonyId or "local")
    record.version = math.max(1, math.floor(tonumber(source.version) or record.version or 1))
    record.zones = normalizedZones

    return record
end

function Store.SaveSnapshot(colonyId, zones, knownVersion)
    local record = Store.GetColonyRecord(colonyId)
    local currentVersion = math.max(1, math.floor(tonumber(record.version) or 1))
    if knownVersion ~= nil and tostring(knownVersion) ~= tostring(currentVersion) then
        return false, "conflict", Store.BuildSnapshot(colonyId)
    end

    Store.ReplaceZones(colonyId, zones)
    Store.Commit(colonyId)
    return true, nil, Store.BuildSnapshot(colonyId)
end

function Store.Commit(colonyId)
    local record = Store.GetColonyRecord(colonyId)
    record.version = (tonumber(record.version) or 0) + 1
    if ModData.transmit then
        ModData.transmit(Store.MOD_DATA_KEY)
    end
    if GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
    return record.version
end

function Store.Init()
    Store.GetRoot()
end

if Events and Events.OnInitGlobalModData and not Store.EventsAdded then
    Events.OnInitGlobalModData.Add(Store.Init)
    Store.EventsAdded = true
end

return Store