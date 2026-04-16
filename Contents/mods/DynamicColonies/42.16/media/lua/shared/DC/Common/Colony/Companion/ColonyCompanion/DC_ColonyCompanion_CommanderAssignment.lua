DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.CanPlayerCommandCompanion(player, workerOrNPC)
    local username = Internal.GetPlayerUsername(player)
    local worker = Internal.ResolveWorkerFromCommandContext(workerOrNPC)
    if not username or not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false, "Companion command is unavailable."
    end

    if not Internal.IsUsernameInWorkerColony(worker, username) then
        return false, "You are not part of this companion's colony."
    end

    local companionData = Internal.GetCompanionData(worker)
    local commander = tostring((companionData and companionData.commanderUsername)
        or (type(workerOrNPC) == "table" and workerOrNPC.dcCommanderUsername)
        or "")
    if commander == "" then
        return false, "No commander assigned. Use Claim Command while nearby."
    end

    if commander ~= username then
        return false, "Only " .. commander .. " can command this companion. Use Claim Command while nearby to take over."
    end

    return true, nil, worker
end

function Internal.AssignWorkerCompanionCommander(player, worker, targetUsername, reason)
    if not worker or not Internal.IsTravelCompanionWorker(worker) then
        return false, "Companion command is unavailable."
    end

    local username = targetUsername and tostring(targetUsername or "") or Internal.GetPlayerUsername(player)
    if username == "" then
        return false, "A target username is required."
    end

    if not Internal.IsUsernameInWorkerColony(worker, username) then
        return false, "That player is not part of this companion's colony."
    end

    local companionData = Internal.GetCompanionData(worker)
    local _, onlinePlayer = Internal.IsOnlinePlayerValid(username)
    companionData.commanderUsername = username
    companionData.commanderOnlineID = onlinePlayer and Internal.GetPlayerOnlineID(onlinePlayer) or nil
    companionData.commandVersion = Internal.GetCommandVersion(companionData) + 1
    companionData.commandAssignedAtMs = Internal.GetCurrentMillis()
    companionData.commandInvalidSinceMs = nil
    companionData.commandReason = reason or "assigned"
    Internal.SyncCommanderToSoul(worker)
    return true, username
end