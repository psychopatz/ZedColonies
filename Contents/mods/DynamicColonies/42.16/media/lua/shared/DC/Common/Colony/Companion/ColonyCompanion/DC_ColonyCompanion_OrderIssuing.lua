DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

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

    args = type(args) == "table" and args or {}
    args.state = order
    local changed = DTNPCServerCore.IssueOrderByUUID(uuid, player, args)
    return changed == true, uuid
end