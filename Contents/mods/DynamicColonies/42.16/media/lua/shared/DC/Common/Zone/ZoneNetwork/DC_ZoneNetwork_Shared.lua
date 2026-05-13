require "DC/Common/Zone/DC_ZoneDataStore"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Network = DC_Colony.Network
local Internal = Network.Internal
local ColonyConfig = DC_Colony.Config
local Registry = DC_Colony.Registry
local Store = DC_ZoneDataStore

local function getOwnerUsername(player)
    return ColonyConfig and ColonyConfig.GetOwnerUsername and ColonyConfig.GetOwnerUsername(player) or tostring(player or "local")
end

local function resolveColonyID(playerOwner, requestedColonyId)
    local colonyID = tostring(requestedColonyId or "")
    local ownedColonyID = Registry and Registry.GetColonyIDForOwner and Registry.GetColonyIDForOwner(playerOwner, false) or nil

    if colonyID == "" then
        if ownedColonyID then
            return tostring(ownedColonyID)
        end
        return tostring(playerOwner or "local")
    end

    if ownedColonyID and tostring(ownedColonyID) ~= colonyID then
        local colonyData = Registry and Registry.GetColonyData and Registry.GetColonyData(colonyID, false) or nil
        if not colonyData or tostring(colonyData.ownerUsername or "") ~= tostring(playerOwner or "") then
            return nil, "Access denied."
        end
    end

    return colonyID
end

local function sendSnapshot(player, colonyId, snapshot, options)
    options = type(options) == "table" and options or {}
    if not Internal.sendResponse then
        return
    end

    Internal.sendResponse(player, ColonyConfig.COMMAND_MODULE, "SyncZonesSnapshot", {
        colonyId = colonyId,
        version = snapshot and snapshot.version or nil,
        unchanged = options.unchanged == true,
        conflict = options.conflict == true,
        snapshot = snapshot
    })
end

function Internal.syncZonesSnapshot(player, requestedColonyId, knownVersion)
    local owner = getOwnerUsername(player)
    local colonyId, reason = resolveColonyID(owner, requestedColonyId)
    if not colonyId then
        if Internal.syncNotice then
            Internal.syncNotice(player, reason or "Unable to access that colony's zones.", "error", true)
        end
        return
    end

    local snapshot = Store.BuildSnapshot(colonyId)
    if knownVersion ~= nil and tostring(knownVersion) == tostring(snapshot.version) then
        sendSnapshot(player, colonyId, snapshot, { unchanged = true })
        return
    end

    sendSnapshot(player, colonyId, snapshot, {})
end

function Internal.saveZonesSnapshot(player, requestedColonyId, zones, knownVersion)
    local owner = getOwnerUsername(player)
    local colonyId, reason = resolveColonyID(owner, requestedColonyId)
    if not colonyId then
        if Internal.syncNotice then
            Internal.syncNotice(player, reason or "Unable to save that colony's zones.", "error", true)
        end
        return
    end

    local ok, saveReason, snapshot = Store.SaveSnapshot(colonyId, zones, knownVersion)
    if not ok then
        local currentSnapshot = snapshot or Store.BuildSnapshot(colonyId)
        sendSnapshot(player, colonyId, currentSnapshot, { conflict = saveReason == "conflict" })
        if saveReason == "conflict" and Internal.syncNotice then
            Internal.syncNotice(player, "Zone data changed on the server. Refreshed your view.", "warning", false)
        end
        return
    end

    sendSnapshot(player, colonyId, snapshot or Store.BuildSnapshot(colonyId), {})
end

return Network