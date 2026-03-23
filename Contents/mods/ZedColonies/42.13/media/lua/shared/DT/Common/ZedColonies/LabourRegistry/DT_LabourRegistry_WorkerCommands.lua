DT_Labour = DT_Labour or {}
DT_Labour.Registry = DT_Labour.Registry or {}
DT_Labour.Registry.Internal = DT_Labour.Registry.Internal or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry

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
        if shouldEnable then
            worker.jobEnabled = true
            worker.returnReason = nil
            if Config.NormalizeJobType(worker.jobType) == Config.JobTypes.Scavenge
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

    worker.autoRepeatJob = enabled == true
    worker.autoRepeatScavenge = enabled == true
end

function Registry.SetWorkerJobType(worker, jobType)
    if not worker then return end
    worker.jobType = Config.NormalizeJobType(jobType)
    worker.profession = worker.jobType
    worker.workProgress = 0
    worker.workTarget = nil
    worker.returnReason = nil
    if worker.presenceState == nil then
        worker.presenceState = Config.PresenceStates.Home
    end
end

return Registry
