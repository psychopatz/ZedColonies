require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_Bootstrap"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_Formatters"

DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal

local function isFunction(value)
    return type(value) == "function"
end

local function getConfig()
    local config = Internal.Config
    if type(config) ~= "table" then
        config = (DT_Labour and DT_Labour.Config) or {}
        Internal.Config = config
    end
    return config
end

local function formatReserveValue(value)
    if isFunction(Internal.formatReserveValue) then
        return Internal.formatReserveValue(value)
    end
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

local function getReserveDaysLeft(storedAmount, dailyNeed)
    if isFunction(Internal.getReserveDaysLeft) then
        return Internal.getReserveDaysLeft(storedAmount, dailyNeed)
    end
    local perDay = tonumber(dailyNeed) or 0
    if perDay <= 0 then
        return nil
    end
    return math.max(0, (tonumber(storedAmount) or 0) / perDay)
end

local function getSelectedWorkerForAction(window)
    return window.selectedWorker or window.selectedWorkerSummary or nil
end

local function updateToggleJobStatus(window, enabled, normalizedJob, presenceState)
    local config = getConfig()

    if normalizedJob == ((config.JobTypes or {}).Scavenge) then
        window:updateStatus(
            enabled and "Sending worker out from home..."
                or ((presenceState and presenceState ~= ((config.PresenceStates or {}).Home))
                    and "Calling worker home..."
                    or "Cancelling the scavenging trip...")
        )
        return
    end

    window:updateStatus(enabled and "Starting job..." or "Stopping job...")
end

local function sendToggleJobCommand(window, enabled, normalizedJob, presenceState)
    window:sendLabourCommand("SetWorkerJobEnabled", {
        workerID = window.selectedWorkerSummary.workerID,
        enabled = enabled
    })

    updateToggleJobStatus(window, enabled, normalizedJob, presenceState)
end

local function getScavengeProvisionWarningText(window)
    local worker = getSelectedWorkerForAction(window)
    local config = getConfig()
    local profile = isFunction(config.GetJobProfile) and config.GetJobProfile(worker and worker.jobType) or {}
    local workerName = tostring((worker and worker.name) or (window.selectedWorkerSummary and window.selectedWorkerSummary.name) or "this worker")
    local provisionCalories = math.max(0, tonumber(worker and (worker.provisionCaloriesReserve or worker.storedCalories)) or 0)
    local provisionHydration = math.max(0, tonumber(worker and (worker.provisionHydrationReserve or worker.storedHydration)) or 0)
    local totalCalories = math.max(0, tonumber(worker and (worker.combinedCaloriesTotal or worker.totalCaloriesAvailable or worker.storedCalories)) or 0)
    local totalHydration = math.max(0, tonumber(worker and (worker.combinedHydrationTotal or worker.totalHydrationAvailable or worker.storedHydration)) or 0)
    local dailyCaloriesNeed = math.max(0, tonumber(profile and profile.dailyCaloriesNeed) or 0)
    local dailyHydrationNeed = math.max(0, tonumber(profile and profile.dailyHydrationNeed) or 0)
    local calorieDays = getReserveDaysLeft(totalCalories, dailyCaloriesNeed)
    local hydrationDays = getReserveDaysLeft(totalHydration, dailyHydrationNeed)
    local lowestDays = nil

    if calorieDays and hydrationDays then
        lowestDays = math.min(calorieDays, hydrationDays)
    else
        lowestDays = calorieDays or hydrationDays
    end

    local warningLine = "Make sure they have enough food and water before leaving."
    if provisionCalories <= 0 and provisionHydration <= 0 then
        warningLine = "This worker has no stored provisions and may turn back quickly."
    elseif lowestDays and lowestDays < 1 then
        warningLine = "This worker has less than one day of total reserves and may return early."
    end

    return "Start scavenging run for " .. workerName .. "?\n\n"
        .. "Be sure to give the NPC provisions first. Scavengers can head back home when calories or hydration run low.\n\n"
        .. "Stored provisions:\n"
        .. "Calories: " .. formatReserveValue(provisionCalories)
        .. "\nHydration: " .. formatReserveValue(provisionHydration)
        .. "\n\nTotal reserve:\n"
        .. "Calories: " .. formatReserveValue(totalCalories)
        .. "\nHydration: " .. formatReserveValue(totalHydration)
        .. "\n\n"
        .. "Auto repeat: " .. ((((worker and worker.autoRepeatJob == true) or (worker and worker.autoRepeatScavenge == true)) and "On") or "Off")
        .. "\n\n"
        .. warningLine
        .. "\n\nPress Yes to start anyway, or No to provision them first."
end

local function openScavengeStartConfirmation(window, enabled, normalizedJob, presenceState)
    local text = getScavengeProvisionWarningText(window)

    local function onConfirm(_, button)
        if button and button.internal == "YES" then
            sendToggleJobCommand(window, enabled, normalizedJob, presenceState)
        else
            window:updateStatus("Scavenging start cancelled. Add provisions first if needed.")
        end
    end

    local modal = ISModalDialog:new(0, 0, 420, 260, text, true, nil, onConfirm, nil)
    modal:initialise()
    modal:addToUIManager()
end

local function getStopJobConfirmationText(window, normalizedJob, presenceState)
    local worker = getSelectedWorkerForAction(window)
    local config = getConfig()
    local workerName = tostring((worker and worker.name) or (window.selectedWorkerSummary and window.selectedWorkerSummary.name) or "this worker")
    local homeState = tostring((config.PresenceStates or {}).Home or "Home")

    if normalizedJob == ((config.JobTypes or {}).Scavenge) then
        if tostring(presenceState or "") ~= homeState then
            return "Call " .. workerName .. " back home?\n\n"
                .. "They will stop the current scavenging trip, return home, and stay there until you start them again.\n\n"
                .. "Press Yes to recall them, or No to keep them scavenging."
        end

        return "Cancel the scavenging job for " .. workerName .. "?\n\n"
            .. "This prevents them from heading out until you start the job again.\n\n"
            .. "Press Yes to cancel, or No to keep the job active."
    end

    return "Stop the current job for " .. workerName .. "?\n\n"
        .. "Press Yes to stop working, or No to leave the job running."
end

local function openStopJobConfirmation(window, enabled, normalizedJob, presenceState)
    local text = getStopJobConfirmationText(window, normalizedJob, presenceState)

    local function onConfirm(_, button)
        if button and button.internal == "YES" then
            sendToggleJobCommand(window, enabled, normalizedJob, presenceState)
        else
            window:updateStatus("Job stop cancelled.")
        end
    end

    local modal = ISModalDialog:new(0, 0, 400, 200, text, true, nil, onConfirm, nil)
    modal:initialise()
    modal:addToUIManager()
end

function DT_MainWindow:onToggleJob()
    if not self.selectedWorkerSummary then
        self:updateStatus("Select a worker first.")
        return
    end

    local config = getConfig()
    local state = tostring((self.selectedWorker and self.selectedWorker.state) or self.selectedWorkerSummary.state or "")
    if state == tostring((config.States or {}).Dead or "Dead") then
        self:sendLabourCommand("DeleteDeadWorker", {
            workerID = self.selectedWorkerSummary.workerID
        })
        self:updateStatus("Removing deceased worker record...")
        return
    end

    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType((self.selectedWorker and self.selectedWorker.jobType) or self.selectedWorkerSummary.jobType) or tostring((self.selectedWorker and self.selectedWorker.jobType) or self.selectedWorkerSummary.jobType or "")
    local presenceState = (self.selectedWorker and self.selectedWorker.presenceState) or self.selectedWorkerSummary.presenceState or nil
    local currentEnabled = self.selectedWorker and self.selectedWorker.jobEnabled
    if currentEnabled == nil then
        currentEnabled = self.selectedWorkerSummary.jobEnabled == true
    end
    local enabled = not currentEnabled

    if enabled and normalizedJob == ((config.JobTypes or {}).Scavenge) then
        openScavengeStartConfirmation(self, enabled, normalizedJob, presenceState)
        return
    end

    if not enabled then
        openStopJobConfirmation(self, enabled, normalizedJob, presenceState)
        return
    end

    sendToggleJobCommand(self, enabled, normalizedJob, presenceState)
end

function DT_MainWindow:onToggleAutoRepeat()
    if not self.selectedWorkerSummary then
        self:updateStatus("Select a worker first.")
        return
    end

    local config = getConfig()
    local worker = getSelectedWorkerForAction(self)
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType((worker and worker.jobType) or self.selectedWorkerSummary.jobType)
        or tostring((worker and worker.jobType) or self.selectedWorkerSummary.jobType or "")
    if normalizedJob ~= ((config.JobTypes or {}).Scavenge) then
        self:updateStatus("Auto repeat is only available for scavengers.")
        return
    end

    local enabled = not ((worker and worker.autoRepeatScavenge == true) or (self.selectedWorkerSummary.autoRepeatScavenge == true))
    self:sendLabourCommand("SetWorkerAutoRepeatScavenge", {
        workerID = self.selectedWorkerSummary.workerID,
        enabled = enabled
    })
    self:updateStatus(enabled and "Auto repeat enabled for scavenging." or "Auto repeat disabled for scavenging.")
end

function DT_MainWindow:onCycleJob()
    if not self.selectedWorkerSummary then
        self:updateStatus("Select a worker first.")
        return
    end

    local config = getConfig()
    local worker = self.selectedWorker or self.selectedWorkerSummary
    local workerID = self.selectedWorkerSummary.workerID
    local currentJobType = worker and worker.jobType or self.selectedWorkerSummary.jobType
    local normalizedJobType = config.NormalizeJobType and config.NormalizeJobType(currentJobType) or tostring(currentJobType or "")
    local currentAutoRepeat = (worker and (worker.autoRepeatJob == true or worker.autoRepeatScavenge == true))
        or (self.selectedWorkerSummary.autoRepeatJob == true)
        or (self.selectedWorkerSummary.autoRepeatScavenge == true)
    local workerName = tostring((worker and worker.name) or self.selectedWorkerSummary.name or self.selectedWorkerSummary.workerID)

    local modal = DT_LabourJobModal.Open({
        title = "Change Job",
        promptText = "Choose a new job for " .. workerName .. ".",
        selectedJobType = normalizedJobType,
        autoRepeatJob = currentAutoRepeat,
        onConfirm = function(jobType, option, autoRepeatJob)
            local selectedJobType = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
            local targetAutoRepeat = autoRepeatJob == true
            local changedJob = selectedJobType ~= normalizedJobType
            local changedAutoRepeat = targetAutoRepeat ~= currentAutoRepeat

            if not changedJob and not changedAutoRepeat then
                self:updateStatus(workerName .. " is already set to that job and auto-repeat state.")
                return
            end

            if changedJob then
                self:sendLabourCommand("SetWorkerJobType", {
                    workerID = workerID,
                    jobType = selectedJobType
                })
            end

            if changedAutoRepeat or changedJob then
                self:sendLabourCommand("SetWorkerAutoRepeatScavenge", {
                    workerID = workerID,
                    enabled = targetAutoRepeat
                })
            end

            if changedJob and changedAutoRepeat then
                self:updateStatus("Changing worker job and auto-repeat settings...")
            elseif changedJob then
                self:updateStatus("Changing worker job to " .. tostring(option and option.label or selectedJobType) .. "...")
            else
                self:updateStatus(targetAutoRepeat and "Auto repeat enabled." or "Auto repeat disabled.")
            end
        end
    })

    if not modal then
        self:updateStatus("No labour jobs are currently available.")
    end
end
