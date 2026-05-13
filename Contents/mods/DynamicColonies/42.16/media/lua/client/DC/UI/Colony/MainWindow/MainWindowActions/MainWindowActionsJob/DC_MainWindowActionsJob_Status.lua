DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local JobActions = DC_MainWindow.Internal.JobActions or {}
local FlavorText = JobActions.FlavorText or {}

function JobActions.replaceCachedWorkerSummary(summary)
    if type(summary) ~= "table" or not summary.workerID then
        return
    end

    DC_MainWindow.cachedWorkers = DC_MainWindow.cachedWorkers or {}
    for index, worker in ipairs(DC_MainWindow.cachedWorkers) do
        if worker and worker.workerID == summary.workerID then
            DC_MainWindow.cachedWorkers[index] = summary
            return
        end
    end

    DC_MainWindow.cachedWorkers[#DC_MainWindow.cachedWorkers + 1] = summary
end

function JobActions.replaceCachedWorkerDetail(worker)
    if type(worker) ~= "table" or not worker.workerID then
        return
    end

    DC_MainWindow.cachedDetails = DC_MainWindow.cachedDetails or {}
    DC_MainWindow.cachedDetails[worker.workerID] = worker
end

function JobActions.applyOptimisticJobState(window, enabled, normalizedJob, presenceState)
    if not window or not window.selectedWorkerSummary then
        return
    end

    local config = JobActions.getConfig()
    local states = config.PresenceStates or {}
    local activeWorker = JobActions.getSelectedWorkerForAction(window)
    local summary = JobActions.copyShallow(window.selectedWorkerSummary)
    local detail = JobActions.copyShallow(window.selectedWorker or activeWorker or summary)
    local travelHours = JobActions.getTravelHours(config, detail)
    local homeState = tostring(states.Home or "Home")

    detail.workerID = detail.workerID or summary.workerID
    summary.workerID = summary.workerID or detail.workerID

    if normalizedJob == ((config.JobTypes or {}).TravelCompanion) then
        if enabled then
            detail.jobEnabled = true
            detail.presenceState = states.CompanionToPlayer or "CompanionToPlayer"
            detail.travelHoursRemaining = travelHours
            detail.returnReason = nil
            detail.state = config.States and config.States.Working or "Working"
        elseif tostring(presenceState or "") ~= homeState then
            detail.jobEnabled = false
            detail.presenceState = states.CompanionReturning or "CompanionReturning"
            detail.travelHoursRemaining = travelHours
            detail.returnReason = (config.ReturnReasons and config.ReturnReasons.Manual) or "ManualRecall"
            detail.state = config.States and config.States.Working or "Working"
        else
            detail.jobEnabled = false
            detail.presenceState = states.Home or "Home"
            detail.travelHoursRemaining = 0
            detail.returnReason = nil
            detail.state = config.States and config.States.Idle or "Idle"
        end
    elseif normalizedJob == ((config.JobTypes or {}).Scavenge) then
        if enabled then
            detail.jobEnabled = true
            detail.presenceState = states.AwayToSite or "AwayToSite"
            detail.travelHoursRemaining = travelHours
            detail.returnReason = nil
            detail.state = config.States and config.States.Working or "Working"
        elseif tostring(presenceState or "") ~= homeState then
            detail.jobEnabled = false
            detail.presenceState = states.AwayToHome or "AwayToHome"
            detail.travelHoursRemaining = travelHours
            detail.returnReason = (config.ReturnReasons and config.ReturnReasons.Manual) or "ManualRecall"
            detail.state = config.States and config.States.Idle or "Idle"
        else
            detail.jobEnabled = false
            detail.presenceState = states.Home or "Home"
            detail.travelHoursRemaining = 0
            detail.returnReason = nil
            detail.state = config.States and config.States.Idle or "Idle"
        end
    else
        detail.jobEnabled = enabled == true
        if detail.jobEnabled == false and tostring(detail.presenceState or "") == "" then
            detail.presenceState = states.Home or "Home"
        end
    end

    summary.jobEnabled = detail.jobEnabled
    summary.presenceState = detail.presenceState
    summary.travelHoursRemaining = detail.travelHoursRemaining
    summary.returnReason = detail.returnReason
    summary.state = detail.state
    summary.jobType = detail.jobType or summary.jobType
    summary.maxHp = detail.maxHp or summary.maxHp
    summary.hp = detail.hp or summary.hp

    window.selectedWorkerSummary = summary
    window.selectedWorker = detail
    JobActions.replaceCachedWorkerSummary(summary)
    JobActions.replaceCachedWorkerDetail(detail)
    if window.populateWorkerList then
        window:populateWorkerList(DC_MainWindow.cachedWorkers)
    end
    if window.updateWorkerDetail then
        window:updateWorkerDetail(detail)
    end
    window.syncStatusMutedFrames = math.max(tonumber(window.syncStatusMutedFrames) or 0, 45)
end

function JobActions.isUnemployedJob(worker)
    local config = JobActions.getConfig()
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType((worker and worker.jobType) or nil) or tostring(worker and worker.jobType or "")
    return normalizedJob == ((config.JobTypes or {}).Unemployed)
end

function JobActions.updateToggleJobStatus(window, enabled, normalizedJob, presenceState)
    local config = JobActions.getConfig()

    if normalizedJob == ((config.JobTypes or {}).Scavenge) then
        window:updateStatus(
            enabled and tostring(FlavorText.sendWorkerOut or "Sending worker out from home...")
                or ((presenceState and presenceState ~= ((config.PresenceStates or {}).Home))
                    and tostring(FlavorText.callWorkerHome or "Calling worker home...")
                    or tostring(FlavorText.cancelScavengingTrip or "Cancelling the scavenging trip..."))
        )
        return
    end

    if normalizedJob == ((config.JobTypes or {}).TravelCompanion) then
        local homeState = (config.PresenceStates or {}).Home
        window:updateStatus(
            enabled and tostring(FlavorText.callCompanionToPlayer or "Calling your companion to your location...")
                or ((presenceState and presenceState ~= homeState)
                    and tostring(FlavorText.stopCompanionAndSendHome or "Stopping companion duty and sending them home...")
                    or tostring(FlavorText.stopCompanionDuty or "Stopping companion duty..."))
        )
        return
    end

    window:updateStatus(enabled and tostring(FlavorText.startJob or "Starting job...") or tostring(FlavorText.stopJob or "Stopping job..."))
end

return JobActions