DC_ColonyJobModal = DC_ColonyJobModal or {}
DC_ColonyJobModal.Internal = DC_ColonyJobModal.Internal or {}

local FlavorText = DC_ColonyJobModal.Internal.FlavorText or {}

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
        self.btnAutoRepeat:setTitle(tostring(FlavorText.autoRepeatTitle or "Work Mode: Continuous"))
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
        local config = DC_Colony and DC_Colony.Config or {}
        local selectedJobType = config.NormalizeJobType and config.NormalizeJobType(option.jobType) or tostring(option.jobType or "")
        if selectedJobType == tostring((config.JobTypes or {}).Gatherer or "Gatherer") then
            local workerName = tostring(self.worker and (self.worker.name or self.worker.workerID) or "this worker")
            if DC_GathererConfigModal and DC_GathererConfigModal.Open then
                DC_GathererConfigModal.Open({
                    worker = self.worker,
                    config = self.worker and self.worker.gathererConfig or nil,
                    title = tostring(FlavorText.gathererTitle or "Gatherer Setup"),
                    promptText = "Choose what " .. workerName .. " should gather.",
                    onSave = function(gathererConfig)
                        self.onConfirmCallback(option.jobType, option, self.autoRepeatJob == true, {
                            gathererConfig = gathererConfig
                        })
                    end
                })
                self:close()
                return
            end
        end

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

return DC_ColonyJobModal