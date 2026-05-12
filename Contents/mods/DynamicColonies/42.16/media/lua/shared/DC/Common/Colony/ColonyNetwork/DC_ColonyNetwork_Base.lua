require "DC/Common/Base/DC_Base"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Network = DC_Colony.Network
local Internal = Network.Internal
local Base = DC_Base

Network.Handlers = Network.Handlers or {}

local function buildSnapshotVersion(ownerUsername)
    local state = Base.GetBaseState(ownerUsername)
    local versions = state and state.versions or {}
    return table.concat({
        "base",
        tostring(versions.base or 1),
        tostring(versions.zones or 1),
        tostring(versions.colony or 1),
    }, ":")
end

function Internal.syncBaseSnapshot(player, ownerUsername, knownVersion)
    local owner = Config.GetOwnerUsername(ownerUsername or player)
    local snapshot = Base.BuildClientSnapshot(owner)
    local version = buildSnapshotVersion(owner)
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncBaseSnapshot", {
            version = version,
            unchanged = true
        })
        return
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncBaseSnapshot", {
        version = version,
        snapshot = snapshot
    })
end

Network.Handlers.RequestBaseSnapshot = function(player, args)
    if Internal.syncBaseSnapshot then
        Internal.syncBaseSnapshot(player, player, args and args.knownVersion)
    end
end

Network.Handlers.SaveBaseZonesSnapshot = function(player, args)
    local owner = Config.GetOwnerUsername(player)
    local ok, reason = Base.ReplaceZones(owner, args and args.zones or {})
    if not ok and Internal.syncNotice then
        Internal.syncNotice(player, reason or "Unable to save base zones.", "error", true)
    elseif ok and Internal.syncNotice then
        Internal.syncNotice(player, "Base zones updated.", "info", false)
    end

    if Internal.syncBaseSnapshot then
        Internal.syncBaseSnapshot(player, owner)
    end
end

return Network
