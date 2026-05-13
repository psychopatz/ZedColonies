DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Config = Buildings.Config
local Internal = Buildings.Internal

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getOwnerKey(ownerUsername)
    local registry = getRegistry()
    if registry and registry.GetColonyIDForOwner then
        local colonyID = registry.GetColonyIDForOwner(ownerUsername, true)
        if colonyID ~= nil then
            return tostring(colonyID)
        end
    end

    return DC_Colony and DC_Colony.Config and DC_Colony.Config.GetOwnerUsername
        and DC_Colony.Config.GetOwnerUsername(ownerUsername)
        or tostring(ownerUsername or "local")
end

local function getAuthorityOwner(ownerUsername)
    return DC_Colony and DC_Colony.Config and DC_Colony.Config.GetOwnerUsername
        and DC_Colony.Config.GetOwnerUsername(ownerUsername)
        or tostring(ownerUsername or "local")
end

local function getIndexKey()
    return tostring(Config.MOD_DATA_KEY or "DColony_Buildings_Index")
end

local function getShardKey(ownerUsername)
    return tostring(Config.MOD_DATA_PREFIX or "DColony_Buildings_") .. tostring(getOwnerKey(ownerUsername))
end

local function getShardKeyForColonyID(colonyID)
    return tostring(Config.MOD_DATA_PREFIX or "DColony_Buildings_") .. tostring(colonyID)
end

Internal.GetRegistry = getRegistry
Internal.GetOwnerKey = getOwnerKey
Internal.GetAuthorityOwner = getAuthorityOwner
Internal.GetIndexKey = getIndexKey
Internal.GetShardKey = getShardKey
Internal.GetShardKeyForColonyID = getShardKeyForColonyID

return Internal