DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local JobActions = DC_MainWindow.Internal.JobActions or {}
local FlavorText = JobActions.FlavorText or {}

function DC_MainWindow:onCycleJob()
    if not self.selectedWorkerSummary then
        self:updateStatus(tostring(FlavorText.selectWorkerFirst or "Select a worker first."))
        return
    end

    local config = JobActions.getConfig()
    local worker = self.selectedWorker or self.selectedWorkerSummary
    local workerID = self.selectedWorkerSummary.workerID
    local currentJobType = worker and worker.jobType or self.selectedWorkerSummary.jobType
    local normalizedJobType = config.NormalizeJobType and config.NormalizeJobType(currentJobType) or tostring(currentJobType or "")
    local currentAutoRepeat = (worker and (worker.autoRepeatJob == true or worker.autoRepeatScavenge == true))
        or (self.selectedWorkerSummary.autoRepeatJob == true)
        or (self.selectedWorkerSummary.autoRepeatScavenge == true)
    local workerName = tostring((worker and worker.name) or self.selectedWorkerSummary.name or self.selectedWorkerSummary.workerID)

    local modal = DC_ColonyJobModal.Open({
        title = tostring(FlavorText.changeJobTitle or "Change Job"),
        promptText = string.format(tostring(FlavorText.changeJobPrompt or "Choose a new job for %s."), workerName),
        selectedJobType = normalizedJobType,
        autoRepeatJob = currentAutoRepeat,
        worker = worker,
        onConfirm = function(jobType, option, autoRepeatJob, extra)
            local selectedJobType = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
            local targetAutoRepeat = selectedJobType ~= tostring((config.JobTypes or {}).Unemployed or "Unemployed")
            local changedJob = selectedJobType ~= normalizedJobType
            local changedAutoRepeat = targetAutoRepeat ~= currentAutoRepeat
            local isGatherer = selectedJobType == tostring((config.JobTypes or {}).Gatherer or "Gatherer")
            local gathererConfig = type(extra) == "table" and extra.gathererConfig or nil

            if not changedJob and not changedAutoRepeat and not gathererConfig then
                self:updateStatus(string.format(tostring(FlavorText.currentJobAlreadySet or "%s is already set to that job."), workerName))
                return
            end

            if isGatherer and gathererConfig then
                self:sendColonyCommand("SetWorkerGathererConfig", {
                    workerID = workerID,
                    selectedResources = gathererConfig.selectedResources,
                    gathererConfig = gathererConfig,
                    assignJob = changedJob
                })
                self:updateStatus(changedJob
                    and string.format(tostring(FlavorText.changingGathererJob or "Changing worker job to Gatherer for %s..."), workerName)
                    or string.format(tostring(FlavorText.savingGathererSetup or "Saving gatherer setup for %s..."), workerName))
                return
            end

            if changedJob then
                if selectedJobType == ((config.JobTypes or {}).TravelCompanion) then
                    local optimisticDetail = JobActions.copyShallow(self.selectedWorker or worker or self.selectedWorkerSummary)
                    optimisticDetail.jobType = selectedJobType
                    optimisticDetail.profession = selectedJobType
                    self.selectedWorker = optimisticDetail
                    self.selectedWorkerSummary = JobActions.copyShallow(self.selectedWorkerSummary)
                    self.selectedWorkerSummary.jobType = selectedJobType
                    JobActions.replaceCachedWorkerDetail(optimisticDetail)
                    JobActions.replaceCachedWorkerSummary(self.selectedWorkerSummary)
                    JobActions.applyOptimisticJobState(self, true, selectedJobType, (config.PresenceStates or {}).Home)
                end
                self:sendColonyCommand("SetWorkerJobType", {
                    workerID = workerID,
                    jobType = selectedJobType
                })
            end

            if changedAutoRepeat or changedJob then
                self:sendColonyCommand("SetWorkerAutoRepeatScavenge", {
                    workerID = workerID,
                    enabled = targetAutoRepeat
                })
            end

            if changedJob and changedAutoRepeat then
                self:updateStatus(tostring(FlavorText.changingWorkerJob or "Changing worker job..."))
            elseif changedJob then
                self:updateStatus(string.format(
                    tostring(FlavorText.changingWorkerJobTo or "Changing worker job to %s..."),
                    tostring(option and option.label or selectedJobType)
                ))
            else
                self:updateStatus(tostring(FlavorText.autoRepeatAlwaysOnActiveJobs or "Continuous work is always on for active jobs."))
            end
        end
    })

    if not modal then
        self:updateStatus(tostring(FlavorText.noLabourJobsAvailable or "No labour jobs are currently available."))
    end
end

return DC_MainWindow