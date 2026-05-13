DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegWorkerState or {}

function Data.isTravelCompanionSupported()
    if Config.IsTravelCompanionSupported then
        return Config.IsTravelCompanionSupported() == true
    end
    local activated = getActivatedMods and getActivatedMods() or nil
    return activated and activated.contains and activated:contains("DynamicTradingV2") or false
end

function Data.suspendUnsupportedCompanion(worker)
    local jobTypes = Config.JobTypes or {}
    local presenceStates = Config.PresenceStates or {}
    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
    if normalizedJob ~= tostring(jobTypes.TravelCompanion or "TravelCompanion") or Data.isTravelCompanionSupported() then
        if worker and type(worker.companion) == "table" then
            worker.companion.v1Suspended = nil
        end
        return
    end

    worker.jobEnabled = false
    worker.autoRepeatJob = false
    worker.autoRepeatScavenge = false
    worker.state = tostring(worker.state or "") == tostring((Config.States or {}).Dead or "Dead")
        and worker.state
        or ((Config.States or {}).Idle or "Idle")
    worker.presenceState = presenceStates.Home or "Home"
    worker.travelHoursRemaining = 0
    worker.returnReason = nil

    worker.companion = type(worker.companion) == "table" and worker.companion or {}
    worker.companion.v1Suspended = true
    worker.companion.stage = nil
    worker.companion.awaitingDespawn = false
    worker.companion.currentOrder = nil
    worker.companion.returnReason = nil
    worker.companion.returnTravelHours = nil
    worker.companion.commandInvalidSinceMs = nil
end

return Data