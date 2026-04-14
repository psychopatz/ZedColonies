DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry

local function isTravelCompanionSupported()
    if Config.IsTravelCompanionSupported then
        return Config.IsTravelCompanionSupported() == true
    end
    local activated = getActivatedMods and getActivatedMods() or nil
    return activated and activated.contains and activated:contains("DynamicTradingV2") or false
end

local function forceUnsupportedCompanionHome(worker)
    if not worker then
        return
    end
    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    if normalizedJob ~= tostring((Config.JobTypes or {}).TravelCompanion or "TravelCompanion") or isTravelCompanionSupported() then
        return
    end
    worker.jobEnabled = false
    worker.presenceState = (Config.PresenceStates or {}).Home or "Home"
    worker.travelHoursRemaining = 0
    worker.returnReason = nil
    if type(worker.companion) == "table" then
        worker.companion.v1Suspended = true
        worker.companion.stage = nil
        worker.companion.awaitingDespawn = false
        worker.companion.currentOrder = nil
        worker.companion.returnReason = nil
        worker.companion.returnTravelHours = nil
        worker.companion.commandInvalidSinceMs = nil
    end
end

function Registry.SetWorkerState(worker, state)
    if worker then
        worker.state = state
    end
end

function Registry.SetWorkerHome(worker, x, y, z)
    if not worker then
        return
    end

    worker.homeX = math.floor(tonumber(x) or tonumber(worker.homeX) or 0)
    worker.homeY = math.floor(tonumber(y) or tonumber(worker.homeY) or 0)
    worker.homeZ = math.floor(tonumber(z) or tonumber(worker.homeZ) or 0)
end

function Registry.SetWorkerPresenceState(worker, presenceState, travelHoursRemaining)
    if not worker then
        return
    end

    worker.presenceState = presenceState or worker.presenceState or Config.PresenceStates.Home
    worker.travelHoursRemaining = math.max(0, tonumber(travelHoursRemaining) or 0)
end

function Registry.SendWorkerHome(worker, reason, travelHours)
    if not worker then
        return
    end

    worker.jobEnabled = false
    worker.returnReason = reason or worker.returnReason or Config.ReturnReasons.Manual
    worker.presenceState = Config.PresenceStates.AwayToHome
    worker.travelHoursRemaining = math.max(0, tonumber(travelHours) or 0)
end

function Registry.SetWorkerJobEnabled(worker, enabled)
    if worker then
        local shouldEnable = enabled == true
        local normalizedJob = Config.NormalizeJobType(worker.jobType)
        local incapacitatedState = tostring((Config.States or {}).Incapacitated or "Incapacitated")
        if shouldEnable then
            if normalizedJob == Config.JobTypes.Unemployed then
                worker.jobEnabled = false
                worker.state = Config.States.Idle
                return
            end
            if tostring(worker.state or "") == incapacitatedState then
                worker.jobEnabled = false
                return
            end
            worker.jobEnabled = true
            worker.autoRepeatJob = true
            worker.autoRepeatScavenge = normalizedJob == Config.JobTypes.Scavenge
            worker.returnReason = nil
            if normalizedJob == Config.JobTypes.Scavenge
                and (worker.presenceState == nil or worker.presenceState == Config.PresenceStates.Home) then
                worker.travelHoursRemaining = 0
            end
            return
        end

        worker.jobEnabled = false
    end
end

function Registry.SetWorkerAutoRepeatScavenge(worker, enabled)
    if not worker then
        return
    end

    local normalizedJob = Config.NormalizeJobType(worker.jobType)
    if normalizedJob == Config.JobTypes.Unemployed then
        worker.autoRepeatJob = false
        worker.autoRepeatScavenge = false
        return
    end

    worker.autoRepeatJob = true
    worker.autoRepeatScavenge = normalizedJob == Config.JobTypes.Scavenge
end

function Registry.SetWorkerJobType(worker, jobType)
    if not worker then return end
    forceUnsupportedCompanionHome(worker)
    local normalizedJob = Config.NormalizeJobType(jobType)
    worker.jobType = normalizedJob
    worker.profession = worker.jobType
    worker.workProgress = 0
    worker.workTarget = nil
    worker.workCycleHours = nil
    worker.returnReason = nil
    if normalizedJob == Config.JobTypes.Unemployed then
        worker.jobEnabled = false
        worker.autoRepeatJob = false
        worker.autoRepeatScavenge = false
        worker.state = Config.States.Idle
    else
        worker.jobEnabled = true
        worker.autoRepeatJob = true
        worker.autoRepeatScavenge = normalizedJob == Config.JobTypes.Scavenge
    end
    if worker.presenceState == nil then
        worker.presenceState = Config.PresenceStates.Home
    end
end

return Registry
