DC_ColonyJobModal = DC_ColonyJobModal or {}
DC_ColonyJobModal.Internal = DC_ColonyJobModal.Internal or {}

local FlavorText = DC_ColonyJobModal.Internal.FlavorText or {}

DC_ColonyJobModal.Internal = DC_ColonyJobModal.Internal or {}

local function getJobListClass()
    return DC_ColonyJobModal.Internal.JobOptionList or ISScrollingListBox
end

function DC_ColonyJobModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DC_ColonyJobModal:createChildren()
    ISCollapsableWindow.createChildren(self)

    local JobOptionList = getJobListClass()
    local pad = 10
    local th = self:titleBarHeight()
    local contentY = th + pad
    local optionCount = math.max(1, #(self.jobOptions or {}))
    local listY = contentY + 48
    local visibleRows = math.max(1, math.min(optionCount, self.maxVisibleRows or 10))
    local desiredListHeight = math.max(28 + 8, math.floor((visibleRows * 28) + 8))
    local maxListHeight = math.max(28 + 8, self.height - listY - 54)
    local listHeight = math.min(desiredListHeight, maxListHeight)
    local buttonY = listY + listHeight + 14

    self.promptLabel = ISLabel:new(pad, contentY, 20, tostring(self.promptText or FlavorText.promptText or "Choose a job."), 1, 1, 1, 1, UIFont.Small, true)
    self.promptLabel:initialise()
    self.promptLabel:instantiate()
    self:addChild(self.promptLabel)

    self.currentLabel = ISLabel:new(
        pad,
        contentY + 22,
        20,
        tostring((FlavorText.currentJobPrefix or "Current Job: ") .. tostring(self.currentJobLabel or "Unknown")),
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
    if self.jobList.setFont then
        self.jobList:setFont(UIFont.Small, 4)
    end
    for index, option in ipairs(self.jobOptions or {}) do
        self.jobList:addItem(option.label or option.jobType or "Unknown", option)
        if option.jobType == self.selectedJobType then
            self.selectedOptionIndex = index
            self.jobList.selected = index
        end
    end
    self:addChild(self.jobList)

    self.btnConfirm = ISButton:new(pad, buttonY, 90, 24, tostring(FlavorText.confirmTitle or "Confirm"), self, self.onConfirm)
    self.btnConfirm:initialise()
    self.btnConfirm:instantiate()
    self:addChild(self.btnConfirm)

    self.btnAutoRepeat = ISButton:new(math.floor((self.width - 150) / 2), buttonY, 150, 24, "", self, self.onToggleAutoRepeat)
    self.btnAutoRepeat:initialise()
    self.btnAutoRepeat:instantiate()
    self.btnAutoRepeat:setEnable(false)
    self:addChild(self.btnAutoRepeat)

    self.btnCancel = ISButton:new(self.width - 100, buttonY, 90, 24, tostring(FlavorText.cancelTitle or "Cancel"), self, self.onCancel)
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

return DC_ColonyJobModal