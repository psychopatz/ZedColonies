require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_Bootstrap"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_Formatters"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_ReserveData"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_WorkerPresentation"

DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal
local MainWindowLayout = Internal.MainWindowLayout or {}

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

local function formatBool(value)
    if isFunction(Internal.formatBool) then
        return Internal.formatBool(value)
    end
    return value and "Yes" or "No"
end

local function formatDecimal(value, decimals)
    if isFunction(Internal.formatDecimal) then
        return Internal.formatDecimal(value, decimals)
    end
    local places = tonumber(decimals) or 2
    return string.format("%." .. tostring(places) .. "f", tonumber(value) or 0)
end

local function formatReserveValue(value)
    if isFunction(Internal.formatReserveValue) then
        return Internal.formatReserveValue(value)
    end
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

local function formatCoords(x, y, z)
    if isFunction(Internal.formatCoords) then
        return Internal.formatCoords(x, y, z)
    end
    if x == nil or y == nil then
        return "Unassigned"
    end
    return "(" .. tostring(math.floor(tonumber(x) or 0))
        .. ", " .. tostring(math.floor(tonumber(y) or 0))
        .. ", " .. tostring(math.floor(tonumber(z) or 0)) .. ")"
end

local function formatDurationHours(hoursLeft)
    if isFunction(Internal.formatDurationHours) then
        return Internal.formatDurationHours(hoursLeft)
    end
    local safeHours = math.max(0, tonumber(hoursLeft) or 0)
    if safeHours <= 0 then
        return "empty now"
    end
    if safeHours < 1 then
        return "< 1h"
    end
    return tostring(math.floor(safeHours + 0.5)) .. "h"
end

local function getJobDisplayName(worker, profile)
    if isFunction(Internal.getJobDisplayName) then
        return Internal.getJobDisplayName(worker, profile)
    end
    return tostring(profile and profile.displayName or worker and worker.jobType or "Unknown")
end

local function getScavengePresenceDetailLabel(worker)
    if isFunction(Internal.getScavengePresenceDetailLabel) then
        return Internal.getScavengePresenceDetailLabel(worker)
    end
    return tostring(worker and worker.presenceState or "Home")
end

local function getReturnReasonLabel(worker)
    if isFunction(Internal.getReturnReasonLabel) then
        return Internal.getReturnReasonLabel(worker)
    end
    return tostring(worker and worker.returnReason or "None")
end

local function getScavengeCapabilitySummary(worker)
    if isFunction(Internal.getScavengeCapabilitySummary) then
        return Internal.getScavengeCapabilitySummary(worker)
    end
    return "Open containers only"
end

local function buildActivityLogText(worker)
    if isFunction(Internal.buildActivityLogText) then
        return Internal.buildActivityLogText(worker)
    end
    return " <RGB:0.62,0.62,0.62> No recent worker activity yet. <LINE> "
end

function DT_MainWindow:updateWorkerDetail(worker)
    local previousWorkerID = self.selectedWorker and self.selectedWorker.workerID or nil
    local nextWorkerID = worker and worker.workerID or nil
    local shouldResetScroll = previousWorkerID ~= nextWorkerID

    self.selectedWorker = worker

    if self.reservePanel and self.reservePanel.setWorker then
        self.reservePanel:setWorker(worker)
    end

    if not self.detailText or not self.activityLogText then
        return
    end

    if self.applyDynamicLayout then
        self:applyDynamicLayout()
    end

    if not worker then
        self.detailText:setText(" <RGB:0.6,0.6,0.6> No worker selected. Recruit one from ConversationUI or pick an existing labour worker from the list. ")
        MainWindowLayout.refreshRichTextPanel(self.detailText, 0)
        self.activityLogText:setText(" <RGB:0.62,0.62,0.62> No recent worker activity yet. ")
        MainWindowLayout.refreshRichTextPanel(self.activityLogText, 0)
        if self.applyDynamicLayout then
            self:applyDynamicLayout()
        end
        if self.btnToggleJob then
            self.btnToggleJob:setTitle("Start Job")
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, false)
            end
        end
        if self.btnAutoRepeat then
            self.btnAutoRepeat:setTitle("Auto Repeat: Off")
            self.btnAutoRepeat:setEnable(false)
        end
        if self.btnCycleJob then
            self.btnCycleJob:setEnable(false)
        end
        if self.btnWarehouse then
            self.btnWarehouse:setEnable(false)
        end
        return
    end

    local config = getConfig()
    local profile = (isFunction(config.GetJobProfile) and config.GetJobProfile(worker.jobType)) or {}
    local toolTags = profile.requiredToolTags or {}
    local jobSkillEffects = worker.jobSkillEffects or {
        skillID = worker.jobSkillID,
        skillLabel = worker.jobSkillLabel,
        level = worker.jobSkillLevel,
        speedMultiplier = worker.jobSkillSpeedMultiplier or 1
    }
    local bonusMultiplier = tonumber(jobSkillEffects.speedMultiplier) or 1
    local normalizedJobType = isFunction(config.NormalizeJobType) and config.NormalizeJobType(worker.jobType) or worker.jobType
    local stateLabel = tostring(worker.state or "")
    local deadState = tostring((config.States or {}).Dead or "Dead")
    local workProgressData = isFunction(Internal.getWorkerProgressData) and Internal.getWorkerProgressData(worker, profile) or nil
    local toolSummary = (#toolTags > 0) and table.concat(toolTags, ", ")
        or ((normalizedJobType == (config.JobTypes and config.JobTypes.Scavenge)) and "Optional scavenger kit" or "Optional")
    if normalizedJobType == (config.JobTypes and config.JobTypes.Builder) then
        toolSummary = "Builder.Tool.Hammer, Builder.Tool.Saw"
    end
    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> Overview <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Job Enabled: <RGB:1,1,1> " .. formatBool(worker.jobEnabled == true) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Skill Speed Bonus: <RGB:1,1,1> x" .. formatDecimal(bonusMultiplier, 2) .. " <LINE> "
    if jobSkillEffects and jobSkillEffects.skillID then
        text = text .. " <RGB:0.72,0.72,0.72> Active Skill: <RGB:1,1,1> "
            .. tostring(jobSkillEffects.skillLabel or jobSkillEffects.skillID)
            .. " (Lv "
            .. tostring(jobSkillEffects.level or 0)
            .. ") <LINE> "
    end
    text = text .. " <RGB:0.72,0.72,0.72> Stored Money: <RGB:1,1,1> $" .. formatReserveValue(worker.moneyStored) .. " <LINE> <LINE> "

    text = text .. " <RGB:1,1,1> <SIZE:Medium> Housing <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Housing State: <RGB:1,1,1> " .. tostring(worker.housingState or "Unhoused") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Housing Building: <RGB:1,1,1> " .. tostring(worker.housingBuildingType or "None") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Recovery Multiplier: <RGB:1,1,1> x" .. formatDecimal(worker.housingRecoveryMultiplier or 0.33, 2) .. " <LINE> <LINE> "

    text = text .. " <RGB:1,1,1> <SIZE:Medium> Medical Care <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Infirmary Bed: <RGB:1,1,1> " .. formatBool(worker.infirmaryBedAssigned == true) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Infirmary Building: <RGB:1,1,1> " .. tostring(worker.infirmaryBuildingType or "None") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Doctor Coverage: <RGB:1,1,1> " .. formatBool(worker.doctorCovered == true) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Sleep Healing: <RGB:1,1,1> " .. tostring(worker.sleepHealingSource or "None") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Healing Rate: <RGB:1,1,1> " .. formatDecimal(worker.sleepHealingRate or 0, 2) .. " HP/h <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Medical Supply Blocked: <RGB:1,1,1> " .. formatBool(worker.medicalSupplyBlocked == true) .. " <LINE> <LINE> "

    if stateLabel == deadState and tostring(worker.deathCause or "") ~= "" then
        text = text .. " <RGB:0.88,0.52,0.52> Cause Of Death: <RGB:1,1,1> " .. tostring(worker.deathCause) .. " <LINE> <LINE> "
    end

    text = text .. " <RGB:1,1,1> <SIZE:Medium> Work Status <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Current Job: <RGB:1,1,1> " .. getJobDisplayName(worker, profile) .. " <LINE> "
    if normalizedJobType == (config.JobTypes and config.JobTypes.Scavenge) then
        text = text .. " <RGB:0.72,0.72,0.72> Location State: <RGB:1,1,1> " .. getScavengePresenceDetailLabel(worker) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Travel ETA: <RGB:1,1,1> " .. formatDecimal(worker.travelHoursRemaining or 0, 2) .. "h <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Return Reason: <RGB:1,1,1> " .. getReturnReasonLabel(worker) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Auto Repeat: <RGB:1,1,1> " .. formatBool((worker.autoRepeatJob == true) or (worker.autoRepeatScavenge == true)) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Home Coordinates: <RGB:1,1,1> " .. formatCoords(worker.homeX, worker.homeY, worker.homeZ) .. " <LINE> "
    end
    text = text .. " <RGB:0.72,0.72,0.72> Site State: <RGB:1,1,1> " .. tostring(worker.siteState or "Deferred") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Tool State: <RGB:1,1,1> " .. tostring(worker.toolState or "Missing") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Required Tools: <RGB:1,1,1> " .. toolSummary .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Work Coordinates: <RGB:1,1,1> " .. formatCoords(worker.workX, worker.workY, worker.workZ) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Pending Output: <RGB:1,1,1> " .. tostring(worker.outputCount or 0) .. " <LINE> "
    if worker.assignedProjectID then
        text = text .. " <RGB:0.72,0.72,0.72> Building Project: <RGB:1,1,1> "
            .. tostring(worker.assignedProjectBuildingType or "Project")
            .. " L"
            .. tostring(worker.assignedProjectTargetLevel or 1)
            .. " <LINE> "
    elseif normalizedJobType == (config.JobTypes and config.JobTypes.Builder) then
        text = text .. " <RGB:0.72,0.72,0.72> Building Project: <RGB:1,1,1> No Project <LINE> "
    end
    if workProgressData then
        local progressUnit = "h"
        if normalizedJobType == (config.JobTypes and config.JobTypes.Scavenge) then
            progressUnit = " work"
        elseif normalizedJobType == (config.JobTypes and config.JobTypes.Builder) then
            progressUnit = " work points"
        end
        text = text .. " <RGB:0.72,0.72,0.72> Current Activity: <RGB:1,1,1> " .. tostring(workProgressData.displayText or workProgressData.label or "Working") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Activity Progress: <RGB:1,1,1> "
            .. formatReserveValue(workProgressData.progressAmount or workProgressData.progressHours or 0)
            .. " / "
            .. formatReserveValue(workProgressData.workTarget or workProgressData.cycleHours or 0)
            .. progressUnit
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Activity ETA: <RGB:1,1,1> "
            .. formatDurationHours(workProgressData.remainingWorldHours)
            .. " <LINE> "
    end

    if normalizedJobType == (config.JobTypes and config.JobTypes.Scavenge) then
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Scavenge Profile <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Tier: <RGB:1,1,1> " .. tostring(worker.scavengeTierLabel or "Tier 0 - Open Containers") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Site Profile: <RGB:1,1,1> " .. tostring(worker.scavengeSiteProfileLabel or "Unsorted Location") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Room Context: <RGB:1,1,1> " .. tostring(worker.scavengeSiteRoomName or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Zone Context: <RGB:1,1,1> " .. tostring(worker.scavengeSiteZoneType or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Loot Rolls: <RGB:1,1,1> " .. tostring(worker.scavengePoolRolls or 0) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Failure Weight: <RGB:1,1,1> " .. tostring(worker.scavengeFailureWeight or 0) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Gear Search Speed: <RGB:1,1,1> x" .. formatDecimal(worker.scavengeSearchSpeedMultiplier or 1, 2) .. " <LINE> "
        if workProgressData and workProgressData.effectiveSpeedMultiplier then
            text = text .. " <RGB:0.72,0.72,0.72> Speed Breakdown: <RGB:1,1,1> Base x"
                .. formatDecimal(workProgressData.baseSpeedMultiplier or 1, 2)
                .. " | Skill x"
                .. formatDecimal(workProgressData.skillSpeedMultiplier or 1, 2)
                .. " | Gear x"
                .. formatDecimal(workProgressData.equipmentSpeedMultiplier or 1, 2)
                .. " | Effective x"
                .. formatDecimal(workProgressData.effectiveSpeedMultiplier or 1, 2)
                .. " <LINE> "
        end
        text = text .. " <RGB:0.72,0.72,0.72> Carry Load (Raw): <RGB:1,1,1> "
            .. formatDecimal(worker.haulRawWeight or 0, 2)
            .. " / "
            .. formatDecimal(worker.maxCarryWeight or 0, 2)
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Base Carry Limit: <RGB:1,1,1> " .. formatDecimal(worker.baseCarryWeight or worker.maxCarryWeight or 0, 2) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Effective Burden: <RGB:1,1,1> "
            .. formatDecimal(worker.haulEffectiveWeight or 0, 2)
            .. " / "
            .. formatDecimal(worker.effectiveCarryLimit or worker.baseCarryWeight or 0, 2)
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Raw Carry Allowance: <RGB:1,1,1> " .. formatDecimal(worker.rawCarryAllowance or worker.maxCarryWeight or 0, 2) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Carry Containers: <RGB:1,1,1> " .. tostring(worker.carryContainerCount or 0) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Completed Runs: <RGB:1,1,1> " .. tostring(worker.dumpTrips or 0) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Warehouse Weight Used: <RGB:1,1,1> "
            .. formatDecimal(worker.warehouseUsedWeight or 0, 2)
            .. " / "
            .. formatDecimal(worker.warehouseMaxWeight or 0, 2)
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Unlocked Pools: <RGB:1,1,1> " .. getScavengeCapabilitySummary(worker) .. " <LINE> "
    end

    self.detailText:setText(text)
    MainWindowLayout.refreshRichTextPanel(self.detailText, shouldResetScroll and 0 or nil)
    self.activityLogText:setText(buildActivityLogText(worker))
    MainWindowLayout.refreshRichTextPanel(self.activityLogText, shouldResetScroll and 0 or nil)
    if self.applyDynamicLayout then
        self:applyDynamicLayout()
    end

    if self.btnToggleJob then
        if stateLabel == deadState then
            self.btnToggleJob:setTitle("Bury Person")
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, true)
            end
        elseif normalizedJobType == (config.JobTypes and config.JobTypes.Scavenge) then
            local presenceState = tostring(worker.presenceState or "")
            local homeState = tostring((config.PresenceStates or {}).Home or "Home")
            if worker.jobEnabled and presenceState ~= homeState then
                self.btnToggleJob:setTitle("Return Home")
            elseif worker.jobEnabled then
                self.btnToggleJob:setTitle("Cancel Job")
            else
                self.btnToggleJob:setTitle("Start Job")
            end
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, worker.jobEnabled == true)
            end
        else
            self.btnToggleJob:setTitle(worker.jobEnabled and "Stop Job" or "Start Job")
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, worker.jobEnabled == true)
            end
        end
    end

    if self.btnAutoRepeat then
        local allowAutoRepeat = stateLabel ~= deadState and normalizedJobType == (config.JobTypes and config.JobTypes.Scavenge)
        self.btnAutoRepeat:setTitle("Auto Repeat: " .. ((((worker.autoRepeatJob == true) or (worker.autoRepeatScavenge == true)) and "On") or "Off"))
        self.btnAutoRepeat:setEnable(allowAutoRepeat)
    end

    if self.btnCycleJob then
        self.btnCycleJob:setEnable(stateLabel ~= deadState)
    end

    if self.btnWarehouse then
        self.btnWarehouse:setEnable(true)
    end
end
