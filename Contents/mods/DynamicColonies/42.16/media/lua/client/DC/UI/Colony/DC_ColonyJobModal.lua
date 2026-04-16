require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISScrollingListBox"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonySkills/DC_ColonySkills"

DC_ColonyJobModal = ISCollapsableWindow:derive("DC_ColonyJobModal")
DC_ColonyJobModal.instance = nil

local JobOptionList = ISScrollingListBox:derive("DC_ColonyJobModal_List")
local JOB_ROW_HEIGHT = 28
local JOB_LIST_MAX_VISIBLE_ROWS = 10

local function getJobDisplayColor(config, jobType)
    local normalized = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
    local jobTypes = config.JobTypes or {}

    if normalized == tostring(jobTypes.Builder or "Builder") then
        return { r = 0.48, g = 0.9, b = 0.48, a = 1 }
    end
    if normalized == tostring(jobTypes.Scavenge or "Scavenge") then
        return { r = 0.95, g = 0.78, b = 0.36, a = 1 }
    end
    if normalized == tostring(jobTypes.Farm or "Farm") then
        return { r = 0.62, g = 0.88, b = 0.42, a = 1 }
    end
    if normalized == tostring(jobTypes.Fish or "Fish") then
        return { r = 0.48, g = 0.78, b = 0.98, a = 1 }
    end
    if normalized == tostring(jobTypes.Doctor or "Doctor") then
        return { r = 0.95, g = 0.52, b = 0.52, a = 1 }
    end
    if normalized == tostring(jobTypes.Unemployed or "Unemployed") then
        return { r = 0.7, g = 0.7, b = 0.7, a = 1 }
    end

    return { r = 0.9, g = 0.9, b = 0.9, a = 1 }
end

local function canSelectJob(config, worker, normalizedJob)
    if config.CanWorkerTakeJob then
        local capable, reason = config.CanWorkerTakeJob(worker, normalizedJob)
        return capable, reason
    end
    return true, nil
end

local function getSkillColor(level)
    level = tonumber(level) or 0
    if level >= 5 then
        return { r = 0.48, g = 0.9, b = 0.48, a = 1 }
    elseif level >= 3 then
        return { r = 0.95, g = 0.78, b = 0.36, a = 1 }
    elseif level >= 1 then
        return { r = 0.95, g = 0.52, b = 0.52, a = 1 }
    else
        return { r = 0.75, g = 0.35, b = 0.35, a = 1 }
    end
end

local function buildOrderedJobOptions(config, worker)
    local ordered = {}
    local seen = {}
    local jobTypes = config.JobTypes or {}
    local extras = {}

    local function addJob(jobType)
        local normalized = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
        if normalized == "" or seen[normalized] then
            return
        end

        local profile = config.GetJobProfile and config.GetJobProfile(normalized) or {}
        local enabled, reason = canSelectJob(config, worker, normalized)
        local label = tostring(profile.displayName or normalized)

        local color = nil
        local skillID = config.GetWorkerJobSkillID and config.GetWorkerJobSkillID(worker, {jobType = normalized}) or nil
        if skillID and DC_Colony.Skills then
            local entry = DC_Colony.Skills.GetSkillEntry(worker, skillID)
            local level = entry and entry.level or 0
            local skillLabel = config.GetSkillDisplayName and config.GetSkillDisplayName(skillID) or skillID
            label = label .. " - Lvl " .. tostring(level) .. " " .. skillLabel
            color = getSkillColor(level)
        else
            color = getJobDisplayColor(config, normalized)
        end

        if enabled == false and normalized == tostring((jobTypes.TravelCompanion or "TravelCompanion")) and string.find(tostring(reason or ""), "V2", 1, true) then
            label = label .. " (Needs V2)"
        end
        ordered[#ordered + 1] = {
            jobType = normalized,
            label = label,
            enabled = enabled,
            disabledReason = reason,
            color = color,
            disabledColor = enabled and nil or { r = 0.92, g = 0.28, b = 0.28, a = 1 }
        }
        seen[normalized] = true
    end

    addJob(jobTypes.Unemployed)
    addJob(jobTypes.Scavenge)
    addJob(jobTypes.Farm)
    addJob(jobTypes.Fish)

    for jobType, profile in pairs(config.JobProfiles or {}) do
        local normalized = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
        if normalized ~= "" and not seen[normalized] then
            local enabled, reason = canSelectJob(config, worker, normalized)
            local label = tostring(profile and profile.displayName or normalized)
            
            local color = nil
            local skillID = config.GetWorkerJobSkillID and config.GetWorkerJobSkillID(worker, {jobType = normalized}) or nil
            if skillID and DC_Colony.Skills then
                local entry = DC_Colony.Skills.GetSkillEntry(worker, skillID)
                local level = entry and entry.level or 0
                local skillLabel = config.GetSkillDisplayName and config.GetSkillDisplayName(skillID) or skillID
                label = label .. " - Lvl " .. tostring(level) .. " " .. skillLabel
                color = getSkillColor(level)
            else
                color = getJobDisplayColor(config, normalized)
            end

            if enabled == false and normalized == tostring((jobTypes.TravelCompanion or "TravelCompanion")) and string.find(tostring(reason or ""), "V2", 1, true) then
                label = label .. " (Needs V2)"
            end
            extras[#extras + 1] = {
                jobType = normalized,
                label = label,
                enabled = enabled,
                disabledReason = reason,
                color = color,
                disabledColor = enabled and nil or { r = 0.92, g = 0.28, b = 0.28, a = 1 }
            }
            seen[normalized] = true
        end
    end

    table.sort(extras, function(a, b)
        return tostring(a.label or a.jobType) < tostring(b.label or b.jobType)
    end)

    for _, option in ipairs(extras) do
        ordered[#ordered + 1] = option
    end

    return ordered
end

function JobOptionList:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = JOB_ROW_HEIGHT
    o.font = UIFont.Small
    o.doDrawItem = self.doDrawItem
    return o
end

function JobOptionList:onMouseDown(x, y)
    local result = ISScrollingListBox.onMouseDown(self, x, y)
    local item = self.items and self.items[self.selected] or nil
    local option = item and item.item or nil
    if option and self.target and self.target.selectJobIndex then
        if option.enabled == false then
            self.selected = self.target.selectedOptionIndex or -1
            return true
        end
        self.target:selectJobIndex(item.index)
    end
    return result
end

function JobOptionList:doDrawItem(y, item, alt)
    local option = item and item.item or nil
    if not option then
        return y + self.itemheight
    end

    local width = self:getWidth()
    local isSelected = self.selected == item.index
    if isSelected then
        self:drawRect(0, y, width, self.itemheight, 0.24, 0.18, 0.38, 0.62)
    elseif alt then
        self:drawRect(0, y, width, self.itemheight, 0.04, 1, 1, 1)
    end

    self:drawRectBorder(0, y, width, self.itemheight, 0.08, 1, 1, 1)

    local boxX = 6
    local boxY = y + 6
    local boxSize = 14
    local textX = boxX + boxSize + 8
    local palette = option.enabled == false and option.disabledColor or option.color or { r = 0.9, g = 0.9, b = 0.9, a = 1 }

    self:drawRectBorder(boxX, boxY, boxSize, boxSize, 0.7, 1, 1, 1)
    if isSelected and option.enabled ~= false then
        self:drawRect(boxX + 3, boxY + 3, boxSize - 6, boxSize - 6, 1, 0.18, 0.92, 0.28)
    end

    self:drawText(tostring(option.label or option.jobType or "Unknown"), textX, y + 5, palette.r or 1, palette.g or 1, palette.b or 1, palette.a or 1, UIFont.Small)

    if option.enabled == false and tostring(option.disabledReason or "") ~= "" then
        self:drawTextRight(tostring(option.disabledReason), width - 8, y + 5, 0.78, 0.46, 0.46, 0.9, UIFont.Small)
    end

    return y + self.itemheight
end

function DC_ColonyJobModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_ColonyJobModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = 10
    local th = self:titleBarHeight()
    local contentY = th + pad
    local optionCount = math.max(1, #(self.jobOptions or {}))
    local listY = contentY + 48
    local visibleRows = math.max(1, math.min(optionCount, self.maxVisibleRows or JOB_LIST_MAX_VISIBLE_ROWS))
    local desiredListHeight = math.max(JOB_ROW_HEIGHT + 8, math.floor((visibleRows * JOB_ROW_HEIGHT) + 8))
    local maxListHeight = math.max(JOB_ROW_HEIGHT + 8, self.height - listY - 54)
    local listHeight = math.min(desiredListHeight, maxListHeight)
    local buttonY = listY + listHeight + 14

    self.promptLabel = ISLabel:new(pad, contentY, 20, tostring(self.promptText or "Choose a job."), 1, 1, 1, 1, UIFont.Small, true)
    self.promptLabel:initialise()
    self.promptLabel:instantiate()
    self:addChild(self.promptLabel)

    self.currentLabel = ISLabel:new(
        pad,
        contentY + 22,
        20,
        "Current Job: " .. tostring(self.currentJobLabel or "Unknown"),
        0.75,
        0.75,
        0.75,
        1,
        UIFont.Small,
        true
    )
    self.currentLabel:initialise()
    self.currentLabel:instantiate()
    self:addChild(self.currentLabel)

    self.jobList = JobOptionList:new(pad, listY, self.width - (pad * 2), listHeight)
    self.jobList:initialise()
    self.jobList:instantiate()
    self.jobList.target = self
    self.jobList:setFont(UIFont.Small, 4)
    for index, option in ipairs(self.jobOptions or {}) do
        self.jobList:addItem(option.label or option.jobType or "Unknown", option)
        if option.jobType == self.selectedJobType then
            self.selectedOptionIndex = index
            self.jobList.selected = index
        end
    end
    self:addChild(self.jobList)

    self.btnConfirm = ISButton:new(pad, buttonY, 90, 24, "Confirm", self, self.onConfirm)
    self.btnConfirm:initialise()
    self.btnConfirm:instantiate()
    self:addChild(self.btnConfirm)

    self.btnAutoRepeat = ISButton:new(math.floor((self.width - 150) / 2), buttonY, 150, 24, "", self, self.onToggleAutoRepeat)
    self.btnAutoRepeat:initialise()
    self.btnAutoRepeat:instantiate()
    self.btnAutoRepeat:setEnable(false)
    self:addChild(self.btnAutoRepeat)

    self.btnCancel = ISButton:new(self.width - 100, buttonY, 90, 24, "Cancel", self, self.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self:addChild(self.btnCancel)

    if self.selectedOptionIndex and self.jobOptions[self.selectedOptionIndex] and self.jobOptions[self.selectedOptionIndex].enabled == false then
        self.selectedOptionIndex = nil
        self.selectedJobType = nil
    end

    if not self.selectedOptionIndex and #self.jobOptions > 0 then
        for index, option in ipairs(self.jobOptions) do
            if option.enabled ~= false then
                self:selectJobIndex(index)
                return
            end
        end
        self:updateConfirmState()
    else
        self:updateConfirmState()
    end
end

function DC_ColonyJobModal:selectJobIndex(index)
    if not self.jobList or not self.jobOptions or not self.jobOptions[index] then
        return
    end

    if self.jobOptions[index].enabled == false then
        return
    end

    self.selectedOptionIndex = index
    self.selectedJobType = self.jobOptions[index].jobType
    self.jobList.selected = index
    self:updateConfirmState()
end

function DC_ColonyJobModal:onJobSelected(index, selected)
    self:selectJobIndex(index)
end

function DC_ColonyJobModal:updateConfirmState()
    if self.btnAutoRepeat then
        self.btnAutoRepeat:setTitle("Work Mode: Continuous")
    end

    if self.btnConfirm then
        local option = self.selectedOptionIndex and self.jobOptions and self.jobOptions[self.selectedOptionIndex] or nil
        self.btnConfirm:setEnable(option ~= nil and option.enabled ~= false and self.selectedJobType ~= nil)
    end
end

function DC_ColonyJobModal:onToggleAutoRepeat()
    self:updateConfirmState()
end

function DC_ColonyJobModal:onConfirm()
    local option = self.selectedOptionIndex and self.jobOptions[self.selectedOptionIndex] or nil
    if self.onConfirmCallback and option then
        self.onConfirmCallback(option.jobType, option, self.autoRepeatJob == true)
    end
    self:close()
end

function DC_ColonyJobModal:onCancel()
    self:close()
end

function DC_ColonyJobModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DC_ColonyJobModal.instance == self then
        DC_ColonyJobModal.instance = nil
    end
end

function DC_ColonyJobModal.Open(args)
    args = args or {}

    local config = DC_Colony and DC_Colony.Config or {}
    local jobOptions = buildOrderedJobOptions(config, args.worker)
    if #jobOptions <= 0 then
        return nil
    end

    if DC_ColonyJobModal.instance then
        DC_ColonyJobModal.instance:close()
    end

    local selectedJobType = config.NormalizeJobType and config.NormalizeJobType(args.selectedJobType) or tostring(args.selectedJobType or "")
    local currentJobLabel = selectedJobType
    for _, option in ipairs(jobOptions) do
        if option.jobType == selectedJobType then
            currentJobLabel = option.label
            break
        end
    end
    if selectedJobType == "" then
        selectedJobType = jobOptions[1].jobType
        currentJobLabel = jobOptions[1].label
    end

    local width = 520
    local screenHeight = getCore():getScreenHeight()
    local maxVisibleRows = math.max(1, math.floor((screenHeight - 220) / JOB_ROW_HEIGHT))
    local visibleRows = math.max(1, math.min(#jobOptions, JOB_LIST_MAX_VISIBLE_ROWS, maxVisibleRows))
    local listHeight = math.max(JOB_ROW_HEIGHT + 8, math.floor((visibleRows * JOB_ROW_HEIGHT) + 8))
    local height = math.min(screenHeight - 80, 140 + listHeight + 56)
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    local modal = DC_ColonyJobModal:new(x, y, width, height)
    modal.title = tostring(args.title or "Change Job")
    modal.promptText = tostring(args.promptText or "Choose a job.")
    modal.currentJobLabel = tostring(currentJobLabel or "Unknown")
    modal.jobOptions = jobOptions
    modal.selectedJobType = selectedJobType
    modal.autoRepeatJob = selectedJobType ~= tostring((config.JobTypes or {}).Unemployed or "Unemployed")
    modal.maxVisibleRows = visibleRows
    modal.onConfirmCallback = args.onConfirm
    modal:initialise()
    modal:instantiate()
    modal:setVisible(true)
    modal:addToUIManager()
    modal:bringToTop()

    DC_ColonyJobModal.instance = modal
    return modal
end

function DC_ColonyJobModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.title = "Change Job"
    o.resizable = false
    o.promptText = "Choose a job."
    o.currentJobLabel = "Unknown"
    o.jobOptions = {}
    o.selectedJobType = nil
    o.selectedOptionIndex = nil
    o.autoRepeatJob = false
    o.onConfirmCallback = nil
    o.updatingSelection = false
    return o
end

return DC_ColonyJobModal
