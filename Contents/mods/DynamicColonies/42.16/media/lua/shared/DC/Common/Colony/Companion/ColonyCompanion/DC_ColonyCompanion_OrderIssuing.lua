DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

local function buildCompanionOrderPayload(uuid, order, args)
    local payload = type(args) == "table" and args or {}
    local npcData = uuid and Internal.GetSoul(uuid) or nil

    payload.systemCompanionOrder = true
    payload.returnStatus = payload.returnStatus or "Resting"
    payload.state = tostring(order or payload.state or "Follow")

    if payload.state == "Follow" then
        payload.combatOrder = nil
    elseif payload.state == "Stay" then
        payload.combatOrder = nil
    elseif payload.state == "ProtectAuto"
        or payload.state == "ProtectMelee"
        or payload.state == "ProtectRanged" then
        payload.combatOrder = payload.combatOrder or payload.state
    elseif payload.combatOrder == nil and npcData then
        payload.combatOrder = npcData.combatOrder or nil
    end

    return payload
end

function Internal.IssueCommanderFollowOrder(worker, targetPlayer, stateOverride, combatOrderOverride)
    local uuid = Internal.GetCompanionUUID(worker)
    if not uuid or not targetPlayer or not DTNPCServerCore or not DTNPCServerCore.IssueOrderByUUID then
        return false
    end

    local npcData = Internal.GetSoul(uuid)
    local state = stateOverride or (npcData and Internal.IsFollowerCommandState(tostring(npcData.state or "")) and tostring(npcData.state or nil)) or "Follow"
    local combatOrder = combatOrderOverride or npcData and npcData.combatOrder or nil
    return DTNPCServerCore.IssueOrderByUUID(uuid, targetPlayer, {
        state = state,
        combatOrder = combatOrder,
        returnStatus = "Resting",
        systemCompanionOrder = true,
    }) == true
end

function Internal.IssueWorkerCompanionOrder(player, workerID, order, args)
    if isClient() and not isServer() then
        return false, "Server-only companion control."
    end

    local registry = Internal.GetRegistry()
    local worker = registry and registry.GetWorker and registry.GetWorker(workerID) or nil
    local uuid = worker and Internal.GetCompanionUUID(worker) or nil
    if not worker or not uuid or not DTNPCServerCore or not DTNPCServerCore.IssueOrderByUUID then
        return false, "Companion is unavailable."
    end

    local canCommand, commandReason = Internal.CanPlayerCommandCompanion(player, worker)
    if not canCommand then
        return false, commandReason or "Only the current commander can command this companion."
    end

    local payload = buildCompanionOrderPayload(uuid, order, args)
    local changed = DTNPCServerCore.IssueOrderByUUID(uuid, player, payload)
    if changed == true then
        local companionData = Internal.GetCompanionData(worker)
        companionData.currentOrder = tostring(order or payload.state or companionData.currentOrder or "Follow")
    end
    return changed == true, uuid
end