require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTickBox"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"

DT_LabourJobModal = ISCollapsableWindow:derive("DT_LabourJobModal")
DT_LabourJobModal.instance = nil

local function buildOrderedJobOptions(config)
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
        ordered[#ordered + 1] = {
            jobType = normalized,
            label = tostring(profile.displayName or normalized)
        }
        seen[normalized] = true
    end

    addJob(jobTypes.Scavenge)
    addJob(jobTypes.Farm)
    addJob(jobTypes.Fish)

    for jobType, profile in pairs(config.JobProfiles or {}) do
        local normalized = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
        if normalized ~= "" and not seen[normalized] then
            extras[#extras + 1] = {
                jobType = normalized,
                label = tostring(profile and profile.displayName or normalized)
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

function DT_LabourJobModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DT_LabourJobModal:createChildren()
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

    for index, option in ipairs(self.jobOptions or {}) do
        self.jobTickBox:addOption(tostring(option.label or option.jobType or "Unknown"))
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
    self:addChild(self.btnAutoRepeat)

    self.btnCancel = ISButton:new(self.width - 100, buttonY, 90, 24, "Cancel", self, self.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self:addChild(self.btnCancel)

    if not self.selectedOptionIndex and #self.jobOptions > 0 then
        self:selectJobIndex(1)
    else
        self:updateConfirmState()
    end
end

function DT_LabourJobModal:selectJobIndex(index)
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

function DT_LabourJobModal:onJobSelected(index, selected)
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

function DT_LabourJobModal:updateConfirmState()
    if self.btnAutoRepeat then
        self.btnAutoRepeat:setTitle("Auto Repeat: " .. (self.autoRepeatJob == true and "On" or "Off"))
    end

    if self.btnConfirm then
        self.btnConfirm:setEnable(self.selectedOptionIndex ~= nil and self.selectedJobType ~= nil)
    end
end

function DT_LabourJobModal:onToggleAutoRepeat()
    self.autoRepeatJob = not (self.autoRepeatJob == true)
    self:updateConfirmState()
end

function DT_LabourJobModal:onConfirm()
    local option = self.selectedOptionIndex and self.jobOptions[self.selectedOptionIndex] or nil
    if self.onConfirmCallback and option then
        self.onConfirmCallback(option.jobType, option, self.autoRepeatJob == true)
    end
    self:close()
end

function DT_LabourJobModal:onCancel()
    self:close()
end

function DT_LabourJobModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DT_LabourJobModal.instance == self then
        DT_LabourJobModal.instance = nil
    end
end

function DT_LabourJobModal.Open(args)
    args = args or {}

    local config = DT_Labour and DT_Labour.Config or {}
    local jobOptions = buildOrderedJobOptions(config)
    if #jobOptions <= 0 then
        return nil
    end

    if DT_LabourJobModal.instance then
        DT_LabourJobModal.instance:close()
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

    local modal = DT_LabourJobModal:new(x, y, width, height)
    modal.title = tostring(args.title or "Change Job")
    modal.promptText = tostring(args.promptText or "Choose a job.")
    modal.currentJobLabel = tostring(currentJobLabel or "Unknown")
    modal.jobOptions = jobOptions
    modal.selectedJobType = selectedJobType
    modal.autoRepeatJob = args.autoRepeatJob == true or args.autoRepeatScavenge == true
    modal.onConfirmCallback = args.onConfirm
    modal:initialise()
    modal:instantiate()
    modal:setVisible(true)
    modal:addToUIManager()
    modal:bringToTop()

    DT_LabourJobModal.instance = modal
    return modal
end

function DT_LabourJobModal:new(x, y, width, height)
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

return DT_LabourJobModal
