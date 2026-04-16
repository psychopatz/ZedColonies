DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.RefreshCompanionCommanderValidity(worker)
    if not worker or not Internal.IsTravelCompanionWorker(worker) then
        return true
    end

    local companionData = Internal.GetCompanionData(worker)
    local commander = tostring(companionData.commanderUsername or "")
    local presenceState = tostring(worker.presenceState or "")
    local activeState = Config.PresenceStates and Config.PresenceStates.CompanionActive or "CompanionActive"
    local toPlayerState = Config.PresenceStates and Config.PresenceStates.CompanionToPlayer or "CompanionToPlayer"
    if presenceState ~= activeState and presenceState ~= toPlayerState then
        companionData.commandInvalidSinceMs = nil
        return true
    end

    local validOnline = false
    if commander ~= "" and Internal.IsUsernameInWorkerColony(worker, commander) then
        validOnline = Internal.IsOnlinePlayerValid(commander)
    end

    if validOnline then
        if companionData.commandInvalidSinceMs ~= nil then
            companionData.commandInvalidSinceMs = nil
            Internal.SyncCommanderToSoul(worker)
            Internal.SaveRegistry()
        end
        return true
    end

    local now = Internal.GetCurrentMillis()
    if companionData.commandInvalidSinceMs == nil then
        companionData.commandInvalidSinceMs = now
        local uuid = Internal.GetCompanionUUID(worker)
        if uuid and DTNPCServerCore and DTNPCServerCore.IssueOrderByUUID then
            DTNPCServerCore.IssueOrderByUUID(uuid, { ownerUsername = worker.ownerUsername }, {
                state = "Stay",
                returnStatus = "Resting",
                systemCompanionOrder = true,
            })
        end
        Internal.SyncCommanderToSoul(worker)
        Internal.SaveRegistry()
        return false
    end

    if now - (tonumber(companionData.commandInvalidSinceMs) or now) >= Internal.Constants.COMMAND_INVALID_GRACE_MS then
        Internal.BeginWorkerCompanionReturn(nil, worker, Config.ReturnReasons.Manual)
        Internal.SaveRegistry()
        return false
    end

    return false
end