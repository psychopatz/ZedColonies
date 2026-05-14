DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Research = DC_Colony.Research
local Internal = Research.Internal

local function getOwnerKey(ownerUsername)
    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

local function getDataKey(ownerUsername)
    local owner = getOwnerKey(ownerUsername)
    local colonyID = Registry.GetColonyIDForOwner and Registry.GetColonyIDForOwner(owner, true) or owner
    return "DColony_Research_" .. tostring(colonyID)
end

function Internal.EnsureOwnerData(ownerUsername)
    local key = getDataKey(ownerUsername)
    local data = Registry and Registry.Internal and Registry.Internal.EnsureModDataTable
        and Registry.Internal.EnsureModDataTable(key, {
            ownerUsername = getOwnerKey(ownerUsername),
            queue = {},
            blueprints = {},
            version = 1,
            lastProcessedHour = -1,
            nextJobID = 1,
        }) or nil
    if data then
        data.ownerUsername = getOwnerKey(ownerUsername)
        data.queue = type(data.queue) == "table" and data.queue or {}
        data.blueprints = type(data.blueprints) == "table" and data.blueprints or {}
        data.version = math.max(1, math.floor(tonumber(data.version) or 1))
        data.lastProcessedHour = tonumber(data.lastProcessedHour) or -1
        data.nextJobID = math.max(1, math.floor(tonumber(data.nextJobID) or 1))
    end
    return data
end

function Internal.Touch(ownerUsername)
    local data = Internal.EnsureOwnerData(ownerUsername)
    if data then
        data.version = math.max(1, math.floor(tonumber(data.version) or 1)) + 1
    end
    return data
end

function Internal.NextJobID(ownerUsername)
    local data = Internal.EnsureOwnerData(ownerUsername)
    if not data then
        return ""
    end

    local nextID = math.max(1, math.floor(tonumber(data.nextJobID) or 1))
    data.nextJobID = nextID + 1
    return tostring(data.ownerUsername or getOwnerKey(ownerUsername)) .. "_research_" .. tostring(nextID)
end

return Research
