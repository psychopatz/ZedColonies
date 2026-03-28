require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTickBox"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_ColonyJobModal = ISCollapsableWindow:derive("DC_ColonyJobModal")
DC_ColonyJobModal.instance = nil

local function getJobDisplayColor(config, jobType)
    local normalized = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
    local jobTypes = config.JobTypes or {}

    if normalized == tostring(jobTypes.Builder or "Builder") then
        return { r = 0.48, g = 0.9, b = 0.48, a = 1 }
    end
    if normalized == tostring(jobTypes.FollowPlayer or "FollowPlayer") then
        return { r = 0.52, g = 0.76, b = 1, a = 1 }
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
        return config.CanWorkerTakeJob(worker, normalizedJob)
    end
    return true
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
        if config.IsJobTypeVisible and config.IsJobTypeVisible(normalized, worker) == false then
            return
        end

        local profile = config.GetJobProfile and config.GetJobProfile(normalized) or {}
        local enabled = canSelectJob(config, worker, normalized)
        ordered[#ordered + 1] = {
            jobType = normalized,
            label = tostring(profile.displayName or normalized),
            enabled = enabled,
            color = getJobDisplayColor(config, normalized),
            disabledColor = enabled and nil or { r = 0.92, g = 0.28, b = 0.28, a = 1 }
        }
        seen[normalized] = true
    end

    addJob(jobTypes.Unemployed)
    addJob(jobTypes.Scavenge)
    addJob(jobTypes.Farm)
    addJob(jobTypes.Fish)
    addJob(jobTypes.FollowPlayer)

    for jobType, profile in pairs(config.JobProfiles or {}) do
        local normalized = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
        if normalized ~= "" and not seen[normalized] then
            if not (config.IsJobTypeVisible and config.IsJobTypeVisible(normalized, worker) == false) then
                local enabled = canSelectJob(config, worker, normalized)
                extras[#extras + 1] = {
                    jobType = normalized,
                    label = tostring(profile and profile.displayName or normalized),
                    enabled = enabled,
                    color = getJobDisplayColor(config, normalized),
                    disabledColor = enabled and nil or { r = 0.92, g = 0.28, b = 0.28, a = 1 }
                }
            end
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
    local tickBoxY = contentY + 48
    local tickBoxSpacing = 20
    local tickBoxListHeight = (optionCount * tickBoxSpacing) + 20
    local buttonY = tickBoxY + tickBoxListHeight + 14

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

    self.jobTickBox = ISTickBox:new(pad, tickBoxY, 20, 20, "", self, self.onJobSelected)
    self.jobTickBox:initialise()
    self.jobTickBox:instantiate()
    self.jobTickBox:setFont(UIFont.Small)
    self.jobTickBox.getTextColor = function(box, index, color)
        local option = self.jobOptions and self.jobOptions[index] or nil
        local palette = option and ((option.enabled == false and option.disabledColor) or option.color) or nil
        if palette then
            color.r = palette.r or 1
            color.g = palette.g or 1
            color.b = palette.b or 1
            color.a = palette.a or 1
            return
        end
        ISTickBox.getTextColor(box, index, color)
    end

    for index, option in ipairs(self.jobOptions or {}) do
        local optionLabel = tostring(option.label or option.jobType or "Unknown")
        self.jobTickBox:addOption(optionLabel)
        if option.enabled == false then
            self.jobTickBox:disableOption(optionLabel, true)
        end
        self.jobTickBox:setSelected(index, option.jobType == self.selectedJobType)
        if option.jobType == self.selectedJobType then
            self.selectedOptionIndex = index
        end
    end

    self:addChild(self.jobTickBox)

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
    if not self.jobTickBox or not self.jobOptions or not self.jobOptions[index] then
        return
    end

    self.updatingSelection = true
    for optionIndex = 1, #self.jobOptions do
        self.jobTickBox:setSelected(optionIndex, optionIndex == index)
    end
    self.updatingSelection = false

    self.selectedOptionIndex = index
    self.selectedJobType = self.jobOptions[index].jobType
    self:updateConfirmState()
end

function DC_ColonyJobModal:onJobSelected(index, selected)
    if self.updatingSelection then
        return
    end

    if selected then
        self:selectJobIndex(index)
        return
    end

    if self.selectedOptionIndex == index then
        self:selectJobIndex(index)
    end
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

    local width = 420
    local height = 132 + (#jobOptions * 20)
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    local modal = DC_ColonyJobModal:new(x, y, width, height)
    modal.title = tostring(args.title or "Change Job")
    modal.promptText = tostring(args.promptText or "Choose a job.")
    modal.currentJobLabel = tostring(currentJobLabel or "Unknown")
    modal.jobOptions = jobOptions
    modal.selectedJobType = selectedJobType
    modal.autoRepeatJob = selectedJobType ~= tostring((config.JobTypes or {}).Unemployed or "Unemployed")
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
