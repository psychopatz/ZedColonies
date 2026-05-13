DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local JobActions = DC_MainWindow.Internal.JobActions or {}
local FlavorText = JobActions.FlavorText or {}

function JobActions.sendToggleJobCommand(window, enabled, normalizedJob, presenceState)
    JobActions.debugJobAction(
        "sendToggleJobCommand workerID=" .. tostring(window and window.selectedWorkerSummary and window.selectedWorkerSummary.workerID)
            .. " enabled=" .. tostring(enabled)
            .. " jobType=" .. tostring(normalizedJob)
            .. " presenceState=" .. tostring(presenceState)
    )

    if normalizedJob == ((JobActions.getConfig().JobTypes or {}).TravelCompanion)
        or normalizedJob == ((JobActions.getConfig().JobTypes or {}).Scavenge) then
        JobActions.applyOptimisticJobState(window, enabled, normalizedJob, presenceState)
    end

    window:sendColonyCommand("SetWorkerJobEnabled", {
        workerID = window.selectedWorkerSummary.workerID,
        enabled = enabled
    })

    JobActions.updateToggleJobStatus(window, enabled, normalizedJob, presenceState)
end

function JobActions.getScavengeProvisionWarningText(window)
    local worker = JobActions.getSelectedWorkerForAction(window)
    local config = JobActions.getConfig()
    local profile = JobActions.isFunction(config.GetJobProfile) and config.GetJobProfile(worker and worker.jobType) or {}
    local workerName = tostring((worker and worker.name) or (window.selectedWorkerSummary and window.selectedWorkerSummary.name) or FlavorText.fallbackWorkerName or "this worker")
    local provisionCalories = math.max(0, tonumber(worker and (worker.provisionCaloriesReserve or worker.storedCalories)) or 0)
    local provisionHydration = math.max(0, tonumber(worker and (worker.provisionHydrationReserve or worker.storedHydration)) or 0)
    local totalCalories = math.max(0, tonumber(worker and (worker.combinedCaloriesTotal or worker.totalCaloriesAvailable or worker.storedCalories)) or 0)
    local totalHydration = math.max(0, tonumber(worker and (worker.combinedHydrationTotal or worker.totalHydrationAvailable or worker.storedHydration)) or 0)
    local dailyCaloriesNeed = math.max(0, tonumber(profile and profile.dailyCaloriesNeed) or 0)
    local dailyHydrationNeed = math.max(0, tonumber(profile and profile.dailyHydrationNeed) or 0)
    local calorieDays = JobActions.getReserveDaysLeft(totalCalories, dailyCaloriesNeed)
    local hydrationDays = JobActions.getReserveDaysLeft(totalHydration, dailyHydrationNeed)
    local lowestDays = nil

    if calorieDays and hydrationDays then
        lowestDays = math.min(calorieDays, hydrationDays)
    else
        lowestDays = calorieDays or hydrationDays
    end

    local warningLine = tostring(FlavorText.scavengeWarningDefault or "Make sure they have enough food and water before leaving.")
    if provisionCalories <= 0 and provisionHydration <= 0 then
        warningLine = tostring(FlavorText.scavengeWarningNoProvisions or "This worker has no stored provisions and may turn back quickly.")
    elseif lowestDays and lowestDays < 1 then
        warningLine = tostring(FlavorText.scavengeWarningLowReserve or "This worker has less than one day of total reserves and may return early.")
    end

    return string.format(
        tostring(FlavorText.scavengeProvisionText or "Start scavenging run for %s?"),
        workerName,
        JobActions.formatReserveValue(provisionCalories),
        JobActions.formatReserveValue(provisionHydration),
        JobActions.formatReserveValue(totalCalories),
        JobActions.formatReserveValue(totalHydration),
        warningLine
    )
end

function JobActions.openScavengeStartConfirmation(window, enabled, normalizedJob, presenceState)
    local text = JobActions.getScavengeProvisionWarningText(window)

    local function onConfirm(_, button)
        if button and button.internal == "YES" then
            JobActions.debugJobAction("Scavenge start confirmed for workerID=" .. tostring(window and window.selectedWorkerSummary and window.selectedWorkerSummary.workerID))
            JobActions.sendToggleJobCommand(window, enabled, normalizedJob, presenceState)
        else
            JobActions.debugJobAction("Scavenge start cancelled for workerID=" .. tostring(window and window.selectedWorkerSummary and window.selectedWorkerSummary.workerID))
            window:updateStatus(tostring(FlavorText.scavengeStartCancelled or "Scavenging start cancelled. Add provisions first if needed."))
        end
    end

    local modal = ISModalDialog:new(0, 0, 420, 260, text, true, nil, onConfirm, nil)
    modal:initialise()
    modal:addToUIManager()
end

function JobActions.getStopJobConfirmationText(window, normalizedJob, presenceState)
    local worker = JobActions.getSelectedWorkerForAction(window)
    local config = JobActions.getConfig()
    local workerName = tostring((worker and worker.name) or (window.selectedWorkerSummary and window.selectedWorkerSummary.name) or FlavorText.fallbackWorkerName or "this worker")
    local homeState = tostring((config.PresenceStates or {}).Home or "Home")

    if normalizedJob == ((config.JobTypes or {}).Scavenge) then
        if tostring(presenceState or "") ~= homeState then
            return string.format(tostring(FlavorText.stopScavengeReturnHome or "Call %s back home?"), workerName)
        end

        return string.format(tostring(FlavorText.stopScavengeCancelJob or "Cancel the scavenging job for %s?"), workerName)
    end

    if normalizedJob == ((config.JobTypes or {}).TravelCompanion) then
        if tostring(presenceState or "") ~= homeState then
            return string.format(tostring(FlavorText.stopCompanionSendHome or "Send %s home from companion duty?"), workerName)
        end

        return string.format(tostring(FlavorText.stopCompanionCancelDuty or "Cancel companion duty for %s?"), workerName)
    end

    return string.format(tostring(FlavorText.stopGenericJob or "Stop the current job for %s?"), workerName)
end

function JobActions.openStopJobConfirmation(window, enabled, normalizedJob, presenceState)
    local text = JobActions.getStopJobConfirmationText(window, normalizedJob, presenceState)

    local function onConfirm(_, button)
        if button and button.internal == "YES" then
            JobActions.debugJobAction(
                "Stop confirmed workerID=" .. tostring(window and window.selectedWorkerSummary and window.selectedWorkerSummary.workerID)
                    .. " jobType=" .. tostring(normalizedJob)
            )
            JobActions.sendToggleJobCommand(window, enabled, normalizedJob, presenceState)
        else
            JobActions.debugJobAction(
                "Stop cancelled workerID=" .. tostring(window and window.selectedWorkerSummary and window.selectedWorkerSummary.workerID)
                    .. " jobType=" .. tostring(normalizedJob)
            )
            window:updateStatus(normalizedJob == ((JobActions.getConfig().JobTypes or {}).TravelCompanion)
                and tostring(FlavorText.stopCompanionDutyCancelled or "Companion duty stop cancelled.")
                or tostring(FlavorText.stopJobCancelled or "Job stop cancelled."))
        end
    end

    local modal = ISModalDialog:new(0, 0, 400, 200, text, true, nil, onConfirm, nil)
    modal:initialise()
    modal:addToUIManager()
end

function DC_MainWindow:onToggleJob()
    if not self.selectedWorkerSummary then
        self:updateStatus(tostring(FlavorText.selectWorkerFirst or "Select a worker first."))
        return
    end

    local config = JobActions.getConfig()
    local state = tostring((self.selectedWorker and self.selectedWorker.state) or self.selectedWorkerSummary.state or "")
    if state == tostring((config.States or {}).Dead or "Dead") then
        self:sendColonyCommand("DeleteDeadWorker", {
            workerID = self.selectedWorkerSummary.workerID
        })
        self:updateStatus(tostring(FlavorText.removeDeceasedWorkerRecord or "Removing deceased worker record..."))
        return
    end

    local activeWorker = JobActions.getSelectedWorkerForAction(self)
    if JobActions.isUnemployedJob(activeWorker) then
        self:updateStatus(tostring(FlavorText.unemployedChooseRole or "This worker is unemployed. Choose a role first."))
        self:onCycleJob()
        return
    end

    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType((self.selectedWorker and self.selectedWorker.jobType) or self.selectedWorkerSummary.jobType) or tostring((self.selectedWorker and self.selectedWorker.jobType) or self.selectedWorkerSummary.jobType or "")
    local presenceState = (self.selectedWorker and self.selectedWorker.presenceState) or self.selectedWorkerSummary.presenceState or nil
    local currentEnabled = self.selectedWorker and self.selectedWorker.jobEnabled
    if currentEnabled == nil then
        currentEnabled = self.selectedWorkerSummary.jobEnabled == true
    end
    local enabled = not currentEnabled

    if enabled and state == tostring((config.States or {}).Incapacitated or "Incapacitated") then
        self:updateStatus(tostring(FlavorText.incapacitatedRecover or "This worker is incapacitated and must recover before returning to duty."))
        return
    end

    JobActions.debugJobAction(
        "onToggleJob workerID=" .. tostring(self.selectedWorkerSummary.workerID)
            .. " currentEnabled=" .. tostring(currentEnabled)
            .. " targetEnabled=" .. tostring(enabled)
            .. " jobType=" .. tostring(normalizedJob)
            .. " presenceState=" .. tostring(presenceState)
            .. " state=" .. tostring(state)
    )

    if enabled and normalizedJob == ((config.JobTypes or {}).Scavenge) then
        JobActions.openScavengeStartConfirmation(self, enabled, normalizedJob, presenceState)
        return
    end

    if not enabled then
        JobActions.openStopJobConfirmation(self, enabled, normalizedJob, presenceState)
        return
    end

    JobActions.sendToggleJobCommand(self, enabled, normalizedJob, presenceState)
end

function DC_MainWindow:onToggleAutoRepeat()
    self:updateStatus(tostring(FlavorText.autoRepeatAlwaysOnStop or "Continuous work is always on. Use Stop Job when you want a worker to stop."))
end

return DC_MainWindow