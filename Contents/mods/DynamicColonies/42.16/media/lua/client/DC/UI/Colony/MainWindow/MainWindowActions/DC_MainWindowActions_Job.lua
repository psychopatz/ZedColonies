require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Formatters"

DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal

local function isFunction(value)
    return type(value) == "function"
end

local function debugJobAction(message)
    local text = "[DC Job Debug][Client] " .. tostring(message)
    print(text)
    if DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DTCommons", "Colony", "Job", tostring(message))
    end
end

local function getConfig()
    local config = Internal.Config
    if type(config) ~= "table" then
        config = (DC_Colony and DC_Colony.Config) or {}
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

local function getLocalPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
end

local function getLocalUsername()
    local player = getLocalPlayer()
    if player and player.getUsername then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then
            return username
        end
    end
    return nil
end

local function getCompanionCommander(worker)
    local companionData = type(worker and worker.companion) == "table" and worker.companion or {}
    local username = tostring(companionData.commanderUsername or worker and worker.companionCommanderUsername or "")
    return username ~= "" and username or nil
end

local function addUniqueUsername(list, seen, username)
    username = tostring(username or "")
    if username == "" or seen[username] then
        return
    end
    seen[username] = true
    list[#list + 1] = username
end

local function getOwnedFactionStatus()
    if DC_System and DC_System.GetOwnedFactionStatus then
        local status = DC_System.GetOwnedFactionStatus()
        if type(status) == "table" then
            return status
        end
    end
    return DC_MainWindow.cachedOwnedFactionStatus
end

local function getCompanionTransferCandidates()
    local status = getOwnedFactionStatus() or {}
    local faction = type(status.faction) == "table" and status.faction or {}
    local localUsername = getLocalUsername()
    local candidates = {}
    local seen = {}

    addUniqueUsername(candidates, seen, status.authorityOwner or status.ownerUsername or status.leaderUsername)
    addUniqueUsername(candidates, seen, faction.authorityOwner or faction.ownerUsername or faction.leaderUsername)

    local memberSources = {
        status.memberUsernames,
        status.members,
        faction.memberUsernames,
        faction.members
    }
    for _, source in ipairs(memberSources) do
        if type(source) == "table" then
            for _, entry in ipairs(source) do
                if type(entry) == "table" then
                    addUniqueUsername(candidates, seen, entry.username or entry.name)
                else
                    addUniqueUsername(candidates, seen, entry)
                end
            end
        end
    end

    local filtered = {}
    for _, username in ipairs(candidates) do
        if username ~= localUsername then
            filtered[#filtered + 1] = username
        end
    end
    table.sort(filtered)
    return filtered
end

local function copyShallow(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = entry
    end
    return copy
end

local function getTravelHours(config, worker)
    return math.max(
        0,
        tonumber(config.GetScavengeTravelHours and config.GetScavengeTravelHours(worker))
            or tonumber(config.DEFAULT_SCAVENGE_TRAVEL_HOURS)
            or 0
    )
end

local function replaceCachedWorkerSummary(summary)
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

local function replaceCachedWorkerDetail(worker)
    if type(worker) ~= "table" or not worker.workerID then
        return
    end

    DC_MainWindow.cachedDetails = DC_MainWindow.cachedDetails or {}
    DC_MainWindow.cachedDetails[worker.workerID] = worker
end

local function applyOptimisticJobState(window, enabled, normalizedJob, presenceState)
    if not window or not window.selectedWorkerSummary then
        return
    end

    local config = getConfig()
    local states = config.PresenceStates or {}
    local activeWorker = getSelectedWorkerForAction(window)
    local summary = copyShallow(window.selectedWorkerSummary)
    local detail = copyShallow(window.selectedWorker or activeWorker or summary)
    local travelHours = getTravelHours(config, detail)
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
    replaceCachedWorkerSummary(summary)
    replaceCachedWorkerDetail(detail)
    if window.populateWorkerList then
        window:populateWorkerList(DC_MainWindow.cachedWorkers)
    end
    if window.updateWorkerDetail then
        window:updateWorkerDetail(detail)
    end
    window.syncStatusMutedFrames = math.max(tonumber(window.syncStatusMutedFrames) or 0, 45)
end

local function isUnemployedJob(worker)
    local config = getConfig()
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType((worker and worker.jobType) or nil) or tostring(worker and worker.jobType or "")
    return normalizedJob == ((config.JobTypes or {}).Unemployed)
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

    if normalizedJob == ((config.JobTypes or {}).TravelCompanion) then
        local homeState = (config.PresenceStates or {}).Home
        window:updateStatus(
            enabled and "Calling your companion to your location..."
                or ((presenceState and presenceState ~= homeState)
                    and "Stopping companion duty and sending them home..."
                    or "Stopping companion duty...")
        )
        return
    end

    window:updateStatus(enabled and "Starting job..." or "Stopping job...")
end

local function sendToggleJobCommand(window, enabled, normalizedJob, presenceState)
    debugJobAction(
        "sendToggleJobCommand workerID=" .. tostring(window and window.selectedWorkerSummary and window.selectedWorkerSummary.workerID)
            .. " enabled=" .. tostring(enabled)
            .. " jobType=" .. tostring(normalizedJob)
            .. " presenceState=" .. tostring(presenceState)
    )

    if normalizedJob == ((getConfig().JobTypes or {}).TravelCompanion)
        or normalizedJob == ((getConfig().JobTypes or {}).Scavenge) then
        applyOptimisticJobState(window, enabled, normalizedJob, presenceState)
    end

    window:sendColonyCommand("SetWorkerJobEnabled", {
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
        .. "Work mode: Continuous until stopped"
        .. "\n\n"
        .. warningLine
        .. "\n\nPress Yes to start anyway, or No to provision them first."
end

local function openScavengeStartConfirmation(window, enabled, normalizedJob, presenceState)
    local text = getScavengeProvisionWarningText(window)

    local function onConfirm(_, button)
        if button and button.internal == "YES" then
            debugJobAction("Scavenge start confirmed for workerID=" .. tostring(window and window.selectedWorkerSummary and window.selectedWorkerSummary.workerID))
            sendToggleJobCommand(window, enabled, normalizedJob, presenceState)
        else
            debugJobAction("Scavenge start cancelled for workerID=" .. tostring(window and window.selectedWorkerSummary and window.selectedWorkerSummary.workerID))
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

    if normalizedJob == ((config.JobTypes or {}).TravelCompanion) then
        if tostring(presenceState or "") ~= homeState then
            return "Send " .. workerName .. " home from companion duty?\n\n"
                .. "They will leave your position, despawn, and finish the trip home on the colony travel timer.\n\n"
                .. "Press Yes to send them home, or No to keep them with you."
        end

        return "Cancel companion duty for " .. workerName .. "?\n\n"
            .. "This keeps them at home until you call them to you again.\n\n"
            .. "Press Yes to cancel, or No to leave the job active."
    end

    return "Stop the current job for " .. workerName .. "?\n\n"
        .. "Press Yes to stop working, or No to leave the job running."
end

local function openStopJobConfirmation(window, enabled, normalizedJob, presenceState)
    local text = getStopJobConfirmationText(window, normalizedJob, presenceState)

    local function onConfirm(_, button)
        if button and button.internal == "YES" then
            debugJobAction(
                "Stop confirmed workerID=" .. tostring(window and window.selectedWorkerSummary and window.selectedWorkerSummary.workerID)
                    .. " jobType=" .. tostring(normalizedJob)
            )
            sendToggleJobCommand(window, enabled, normalizedJob, presenceState)
        else
            debugJobAction(
                "Stop cancelled workerID=" .. tostring(window and window.selectedWorkerSummary and window.selectedWorkerSummary.workerID)
                    .. " jobType=" .. tostring(normalizedJob)
            )
            window:updateStatus(normalizedJob == ((getConfig().JobTypes or {}).TravelCompanion)
                and "Companion duty stop cancelled."
                or "Job stop cancelled.")
        end
    end

    local modal = ISModalDialog:new(0, 0, 400, 200, text, true, nil, onConfirm, nil)
    modal:initialise()
    modal:addToUIManager()
end

function DC_MainWindow:onCompanionCommand()
    local worker = getSelectedWorkerForAction(self)
    if not worker or not worker.workerID then
        self:updateStatus("Select a companion worker first.")
        return
    end

    local config = getConfig()
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
    if normalizedJob ~= tostring((config.JobTypes or {}).TravelCompanion or "TravelCompanion") then
        self:updateStatus("Command authority only applies to Travel Companion workers.")
        return
    end
    if worker.jobEnabled ~= true then
        self:updateStatus("Start companion duty before assigning command.")
        return
    end

    local commander = getCompanionCommander(worker)
    local localUsername = getLocalUsername()
    if commander == nil or commander ~= localUsername then
        self:sendColonyCommand("ClaimCompanionCommand", {
            workerID = worker.workerID
        })
        self:updateStatus("Trying to claim companion command. Stand within 6 tiles of the companion.")
        return
    end

    local candidates = getCompanionTransferCandidates()
    if #candidates == 0 then
        self:updateStatus("No other colony members are available for command transfer.")
        return
    end

    local x = (getMouseX and getMouseX()) or (self:getAbsoluteX() + 20)
    local y = (getMouseY and getMouseY()) or (self:getAbsoluteY() + 40)
    local menu = ISContextMenu.get(0, x, y)
    local heading = menu:addOption("Transfer companion command to...")
    if heading then
        heading.notAvailable = true
    end

    for _, username in ipairs(candidates) do
        menu:addOption(username, nil, function()
            self:sendColonyCommand("TransferCompanionCommand", {
                workerID = worker.workerID,
                username = username
            })
            self:updateStatus("Transferring companion command to " .. tostring(username) .. "...")
        end)
    end
end

function DC_MainWindow:onToggleJob()
    if not self.selectedWorkerSummary then
        self:updateStatus("Select a worker first.")
        return
    end

    local config = getConfig()
    local state = tostring((self.selectedWorker and self.selectedWorker.state) or self.selectedWorkerSummary.state or "")
    if state == tostring((config.States or {}).Dead or "Dead") then
        self:sendColonyCommand("DeleteDeadWorker", {
            workerID = self.selectedWorkerSummary.workerID
        })
        self:updateStatus("Removing deceased worker record...")
        return
    end

    local activeWorker = getSelectedWorkerForAction(self)
    if isUnemployedJob(activeWorker) then
        self:updateStatus("This worker is unemployed. Choose a role first.")
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
        self:updateStatus("This worker is incapacitated and must recover before returning to duty.")
        return
    end

    debugJobAction(
        "onToggleJob workerID=" .. tostring(self.selectedWorkerSummary.workerID)
            .. " currentEnabled=" .. tostring(currentEnabled)
            .. " targetEnabled=" .. tostring(enabled)
            .. " jobType=" .. tostring(normalizedJob)
            .. " presenceState=" .. tostring(presenceState)
            .. " state=" .. tostring(state)
    )

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

function DC_MainWindow:onToggleAutoRepeat()
    self:updateStatus("Continuous work is always on. Use Stop Job when you want a worker to stop.")
end

function DC_MainWindow:onCycleJob()
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

    local modal = DC_ColonyJobModal.Open({
        title = "Change Job",
        promptText = "Choose a new job for " .. workerName .. ".",
        selectedJobType = normalizedJobType,
        autoRepeatJob = currentAutoRepeat,
        worker = worker,
        onConfirm = function(jobType, option, autoRepeatJob)
            local selectedJobType = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
            local targetAutoRepeat = selectedJobType ~= tostring((config.JobTypes or {}).Unemployed or "Unemployed")
            local changedJob = selectedJobType ~= normalizedJobType
            local changedAutoRepeat = targetAutoRepeat ~= currentAutoRepeat

            if not changedJob and not changedAutoRepeat then
                self:updateStatus(workerName .. " is already set to that job.")
                return
            end

            if changedJob then
                if selectedJobType == ((config.JobTypes or {}).TravelCompanion) then
                    local optimisticDetail = copyShallow(self.selectedWorker or worker or self.selectedWorkerSummary)
                    optimisticDetail.jobType = selectedJobType
                    optimisticDetail.profession = selectedJobType
                    self.selectedWorker = optimisticDetail
                    self.selectedWorkerSummary = copyShallow(self.selectedWorkerSummary)
                    self.selectedWorkerSummary.jobType = selectedJobType
                    replaceCachedWorkerDetail(optimisticDetail)
                    replaceCachedWorkerSummary(self.selectedWorkerSummary)
                    applyOptimisticJobState(self, true, selectedJobType, (config.PresenceStates or {}).Home)
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
                self:updateStatus("Changing worker job...")
            elseif changedJob then
                self:updateStatus("Changing worker job to " .. tostring(option and option.label or selectedJobType) .. "...")
            else
                self:updateStatus("Continuous work is always on for active jobs.")
            end
        end
    })

    if not modal then
        self:updateStatus("No labour jobs are currently available.")
    end
end
