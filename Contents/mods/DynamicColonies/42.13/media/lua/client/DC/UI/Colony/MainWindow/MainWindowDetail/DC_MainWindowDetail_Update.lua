require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Formatters"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_ReserveData"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_WorkerPresentation"

DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
local MainWindowLayout = Internal.MainWindowLayout or {}

local function isFunction(value)
    return type(value) == "function"
end

local function getConfig()
    local config = Internal.Config
    if type(config) ~= "table" then
        config = (DC_Colony and DC_Colony.Config) or {}
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

local function buildActivityLogText(worker)
    if isFunction(Internal.buildActivityLogText) then
        return Internal.buildActivityLogText(worker)
    end
    return " <RGB:0.62,0.62,0.62> No recent worker activity yet. <LINE> "
end

local function formatHousingSummary(worker)
    local housingState = tostring(worker and worker.housingState or "Unhoused")
    local buildingType = tostring(worker and worker.housingBuildingType or "")
    local isHoused = housingState ~= "" and housingState ~= "Unhoused"

    if not isHoused then
        return "No"
    end

    if buildingType ~= "" and buildingType ~= "None" then
        return "Yes - " .. buildingType
    end

    return "Yes"
end

local function updateRichTextPanel(window, panel, cacheField, nextText, resetScroll)
    if not window or not panel then
        return false
    end

    local changed = window[cacheField] ~= nextText
    if changed then
        window[cacheField] = nextText
        panel:setText(nextText)
        MainWindowLayout.refreshRichTextPanel(panel, resetScroll and 0 or nil)
        return true
    end

    if resetScroll then
        MainWindowLayout.setRichTextPanelScroll(panel, 0)
    end

    return false
end

function DC_MainWindow:updateWorkerDetail(worker)
    local previousWorkerID = self.selectedWorker and self.selectedWorker.workerID or nil
    local nextWorkerID = worker and worker.workerID or nil
    local workerChanged = previousWorkerID ~= nextWorkerID
    local shouldResetScroll = workerChanged

    self.selectedWorker = worker

    if self.reservePanel and self.reservePanel.setWorker then
        self.reservePanel:setWorker(worker)
    end

    if not self.detailText or not self.activityLogText then
        return
    end

    if not worker then
        local detailChanged = updateRichTextPanel(
            self,
            self.detailText,
            "lastRenderedDetailText",
            " <RGB:0.6,0.6,0.6> No worker selected. Recruit one from ConversationUI or pick an existing labour worker from the list. ",
            true
        )
        local activityChanged = updateRichTextPanel(
            self,
            self.activityLogText,
            "lastRenderedActivityLogText",
            " <RGB:0.62,0.62,0.62> No recent worker activity yet. ",
            true
        )
        if self.applyDynamicLayout and (detailChanged or activityChanged or workerChanged) then
            self:applyDynamicLayout({
                refreshDetailText = false,
                refreshActivityText = false,
                refreshStatusText = false
            })
        end
        if self.btnToggleJob then
            self.btnToggleJob:setTitle("Start Job")
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, false)
            end
        end
        if self.btnAutoRepeat then
            self.btnAutoRepeat:setTitle("Work Mode: Continuous")
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
    local unemployedJob = tostring((config.JobTypes or {}).Unemployed or "Unemployed")
    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> Worker Status <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Tool State: <RGB:1,1,1> " .. tostring(worker.toolState or "Missing") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Housed: <RGB:1,1,1> " .. formatHousingSummary(worker) .. " <LINE> "
    if jobSkillEffects and jobSkillEffects.skillID then
        text = text .. " <RGB:0.72,0.72,0.72> Active Skill: <RGB:1,1,1> "
            .. tostring(jobSkillEffects.skillLabel or jobSkillEffects.skillID)
            .. " (Lv "
            .. tostring(jobSkillEffects.level or 0)
            .. ") <LINE> "
    else
        text = text .. " <RGB:0.72,0.72,0.72> Active Skill: <RGB:1,1,1> None <LINE> "
    end
    text = text .. " <RGB:0.72,0.72,0.72> Skill Speed Bonus: <RGB:1,1,1> x" .. formatDecimal(bonusMultiplier, 2) .. " <LINE> "

    if stateLabel == deadState and tostring(worker.deathCause or "") ~= "" then
        text = text .. " <RGB:0.88,0.52,0.52> Cause Of Death: <RGB:1,1,1> " .. tostring(worker.deathCause) .. " <LINE> "
    end

    local activityText = buildActivityLogText(worker)
    local detailChanged = updateRichTextPanel(self, self.detailText, "lastRenderedDetailText", text, shouldResetScroll)
    local activityChanged = updateRichTextPanel(
        self,
        self.activityLogText,
        "lastRenderedActivityLogText",
        activityText,
        shouldResetScroll
    )
    if self.applyDynamicLayout and (detailChanged or activityChanged or workerChanged) then
        self:applyDynamicLayout({
            refreshDetailText = false,
            refreshActivityText = false,
            refreshStatusText = false
        })
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
        elseif normalizedJobType == (config.JobTypes and config.JobTypes.TravelCompanion) then
            local presenceState = tostring(worker.presenceState or "")
            local homeState = tostring((config.PresenceStates or {}).Home or "Home")
            if worker.jobEnabled and presenceState ~= homeState then
                self.btnToggleJob:setTitle("Send Home")
            elseif worker.jobEnabled then
                self.btnToggleJob:setTitle("Cancel Duty")
            else
                self.btnToggleJob:setTitle("Start Duty")
            end
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, worker.jobEnabled == true)
            end
        elseif normalizedJobType == unemployedJob then
            self.btnToggleJob:setTitle("Assign Job")
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, false)
            end
        else
            self.btnToggleJob:setTitle(worker.jobEnabled and "Stop Job" or "Start Job")
            if MainWindowLayout.applyToggleButtonStyle then
                MainWindowLayout.applyToggleButtonStyle(self.btnToggleJob, worker.jobEnabled == true)
            end
        end
    end

    if self.btnAutoRepeat then
        self.btnAutoRepeat:setTitle("Work Mode: Continuous")
        self.btnAutoRepeat:setEnable(false)
    end

    if self.btnCycleJob then
        self.btnCycleJob:setEnable(stateLabel ~= deadState)
    end

    if self.btnWarehouse then
        self.btnWarehouse:setEnable(true)
    end
end
