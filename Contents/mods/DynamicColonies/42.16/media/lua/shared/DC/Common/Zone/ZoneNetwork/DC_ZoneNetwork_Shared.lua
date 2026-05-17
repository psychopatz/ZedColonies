require "DC/Common/Zone/DC_ZoneDataStore"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Network = DC_Colony.Network
local Internal = Network.Internal

local function getStore()
    return DC_ZoneDataStore
end

local function getConfig()
    return DC_Colony and DC_Colony.Config or nil
end

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getCommandModule()
    local config = getConfig()
    return config and config.COMMAND_MODULE or "DColony"
end

local function getOwnerUsername(player)
    local config = getConfig()
    return config and config.GetOwnerUsername and config.GetOwnerUsername(player) or tostring(player or "local")
end

local function resolveColonyID(playerOwner, requestedColonyId)
    local colonyID = tostring(requestedColonyId or "")
    local registry = getRegistry()
    local ownedColonyID = registry and registry.GetColonyIDForOwner and registry.GetColonyIDForOwner(playerOwner, false) or nil

    if colonyID == "" then
        if ownedColonyID then
            return tostring(ownedColonyID)
        end
        return tostring(playerOwner or "local")
    end

    -- if ownedColonyID and tostring(ownedColonyID) ~= colonyID then
    --     local colonyData = registry and registry.GetColonyData and registry.GetColonyData(colonyID, false) or nil
    --     if not colonyData or tostring(colonyData.ownerUsername or "") ~= tostring(playerOwner or "") then
    --         -- return nil, "Access denied."
    --     end
    -- end

    return colonyID
end

local function sendSnapshot(player, colonyId, snapshot, options)
    options = type(options) == "table" and options or {}
    if not Internal.sendResponse then
        return
    end

    Internal.sendResponse(player, getCommandModule(), "SyncZonesSnapshot", {
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

    if DC_ZoneRealBase and DC_ZoneRealBase.EnsureSystemZonesForOwner then
        DC_ZoneRealBase.EnsureSystemZonesForOwner(owner, colonyId)
    elseif DC_ZoneRealBase and DC_ZoneRealBase.EnsureBaseZoneForOwner then
        DC_ZoneRealBase.EnsureBaseZoneForOwner(owner, colonyId)
    end

    local store = getStore()
    if not (store and store.BuildSnapshot) then
        return
    end

    local snapshot = store.BuildSnapshot(colonyId)
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

    local zonesToSave = zones
    if DC_ZoneRealBase and DC_ZoneRealBase.SanitizeSnapshotForSave then
        local valid, validationReason, sanitizedZones = DC_ZoneRealBase.SanitizeSnapshotForSave(owner, colonyId, zones, {})
        if valid ~= true then
            if Internal.syncNotice then
                Internal.syncNotice(player, validationReason or "Unable to save that Base Zone layout.", "error", true)
            end
            sendSnapshot(player, colonyId, store.BuildSnapshot(colonyId), {})
            return
        end
        zonesToSave = sanitizedZones
    end

    local store = getStore()
    if not (store and store.SaveSnapshot and store.BuildSnapshot) then
        return
    end

    local ok, saveReason, snapshot = store.SaveSnapshot(colonyId, zonesToSave, knownVersion)
    if not ok then
        local currentSnapshot = snapshot or store.BuildSnapshot(colonyId)
        sendSnapshot(player, colonyId, currentSnapshot, { conflict = saveReason == "conflict" })
        if saveReason == "conflict" and Internal.syncNotice then
            Internal.syncNotice(player, "Zone data changed on the server. Refreshed your view.", "warning", false)
        end
        return
    end

    if DynamicTrading_Factions and DynamicTrading_Factions.GetPlayerFaction and DynamicTrading_Factions.RefreshPlayerFaction then
        local faction = DynamicTrading_Factions.GetPlayerFaction(owner)
        if faction and faction.id then
            DynamicTrading_Factions.RefreshPlayerFaction(faction.id)
        end
    end

    if DC_Colony and DC_Colony.Defense and DC_Colony.Defense.InvalidateOwner then
        DC_Colony.Defense.InvalidateOwner(owner)
    end

    if DC_Colony and DC_Colony.ResidentBridge and DC_Colony.ResidentBridge.RefreshOwnerWorkers then
        DC_Colony.ResidentBridge.RefreshOwnerWorkers(owner)
    end

    sendSnapshot(player, colonyId, snapshot or store.BuildSnapshot(colonyId), {})
    if Internal.syncFactionStatusSummary then
        Internal.syncFactionStatusSummary(player, owner)
    end
end

return Network
