DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.MirrorCommanderToNPC(worker, npcData)
    if not worker or not npcData then
        return false
    end

    local companionData = Internal.GetCompanionData(worker)
    npcData.dcCommanderUsername = companionData and companionData.commanderUsername or nil
    npcData.dcCommanderOnlineID = companionData and companionData.commanderOnlineID or nil
    npcData.dcCommandVersion = companionData and companionData.commandVersion or nil
    return true
end

function Internal.SyncCommanderToSoul(worker)
    local uuid = Internal.GetCompanionUUID(worker)
    local npcData = uuid and Internal.GetSoul(uuid) or nil
    if not uuid or not npcData then
        return false
    end

    Internal.MirrorCommanderToNPC(worker, npcData)
    Internal.SaveSoul(uuid, npcData)

    if not isClient() or isServer() then
        local updates = {
            dcCommanderUsername = npcData.dcCommanderUsername,
            dcCommanderOnlineID = npcData.dcCommanderOnlineID,
            dcCommandVersion = npcData.dcCommandVersion,
        }
        if DTNPCServerCore and DTNPCServerCore.UpdateNPCByUUID then
            DTNPCServerCore.UpdateNPCByUUID(uuid, updates, true)
        end
    end
    return true
end

function Internal.IsFollowerCommandState(state)
    return state == "Follow"
        or state == "ProtectRanged"
        or state == "ProtectMelee"
        or state == "ProtectAuto"
end