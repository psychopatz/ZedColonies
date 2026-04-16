DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.TransferWorkerCompanionCommand(player, workerID, targetUsername)
    local username = Internal.GetPlayerUsername(player)
    local target = tostring(targetUsername or "")
    local registry = Internal.GetRegistry()
    local owner = Config.GetOwnerUsername(player)
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, workerID) or nil
    if not username or not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false, "Companion is unavailable.", nil
    end

    local companionData = Internal.GetCompanionData(worker)
    if tostring(companionData.commanderUsername or "") ~= username then
        return false, "Only the current commander can transfer command.", worker
    end
    if target == "" then
        return false, "A target username is required.", worker
    end
    if not Internal.IsUsernameInWorkerColony(worker, target) then
        return false, "That player is not part of this companion's colony.", worker
    end

    local ok, result = Internal.AssignWorkerCompanionCommander(player, worker, target, "transferred")
    if ok then
        local online, targetPlayer = Internal.IsOnlinePlayerValid(target)
        if online then
            Internal.IssueCommanderFollowOrder(worker, targetPlayer, "Follow", nil)
        else
            companionData.commandInvalidSinceMs = Internal.GetCurrentMillis()
            local uuid = Internal.GetCompanionUUID(worker)
            if uuid and DTNPCServerCore and DTNPCServerCore.IssueOrderByUUID then
                DTNPCServerCore.IssueOrderByUUID(uuid, { ownerUsername = worker.ownerUsername }, {
                    state = "Stay",
                    returnStatus = "Resting",
                    systemCompanionOrder = true,
                })
            end
            Internal.SyncCommanderToSoul(worker)
        end
        Internal.AppendLog(worker, username .. " transferred companion command to " .. target .. ".", Internal.GetCurrentWorldHours(), "travel")
        Internal.SaveRegistry()
    end
    return ok, ok and "Command transferred to " .. target .. "." or result, worker
end