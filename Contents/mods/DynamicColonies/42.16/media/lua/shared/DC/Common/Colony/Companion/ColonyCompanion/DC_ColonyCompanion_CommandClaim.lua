DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.ClaimWorkerCompanionCommand(player, workerID)
    local username = Internal.GetPlayerUsername(player)
    local registry = Internal.GetRegistry()
    local owner = Config.GetOwnerUsername(player)
    local worker = registry and registry.GetWorkerForOwner and registry.GetWorkerForOwner(owner, workerID) or nil
    if not username or not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false, "Companion is unavailable.", nil
    end
    if not Internal.IsUsernameInWorkerColony(worker, username) then
        return false, "You are not part of this companion's colony.", worker
    end

    local uuid = Internal.GetCompanionUUID(worker)
    local zombie = nil
    if uuid and DTNPCServerCore and DTNPCServerCore.GetNPCDataByUUID then
        zombie = DTNPCServerCore.GetNPCDataByUUID(uuid)
    end
    if not zombie then
        return false, "Move near the live companion before claiming command.", worker
    end

    local dz = math.abs((tonumber(player:getZ()) or 0) - (tonumber(zombie:getZ()) or 0))
    local dx = (tonumber(player:getX()) or 0) - (tonumber(zombie:getX()) or 0)
    local dy = (tonumber(player:getY()) or 0) - (tonumber(zombie:getY()) or 0)
    local distance = math.sqrt((dx * dx) + (dy * dy))
    if dz > 1 or distance > Internal.Constants.COMMAND_CLAIM_RANGE_TILES then
        return false, "Move closer to claim command.", worker
    end

    local ok, result = Internal.AssignWorkerCompanionCommander(player, worker, username, "claimed")
    if ok then
        Internal.IssueCommanderFollowOrder(worker, player, "Follow", nil)
        Internal.AppendLog(worker, username .. " claimed companion command.", Internal.GetCurrentWorldHours(), "travel")
        Internal.SaveRegistry()
    end
    return ok, ok and "Command claimed." or result, worker
end