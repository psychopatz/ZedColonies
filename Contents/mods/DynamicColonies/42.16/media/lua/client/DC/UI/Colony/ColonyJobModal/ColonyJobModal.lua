require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISScrollingListBox"
require "DC/Common/Colony/Job/Common/DC_Job_ColonyJobModal_FlavorText"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonySkills/DC_ColonySkills"
require "DC/Common/Colony/Job/Common/DC_Job_Config"
require "DC/Common/Colony/Job/Common/DC_Job_ConfigLogic"
require "DC/Common/Colony/Job/Gatherer/DC_Job_Gatherer_Config"
require "DC/UI/Colony/Gatherer/DC_GathererConfigModal"

local FlavorText = DC_Colony.Job and DC_Colony.Job.ColonyJobModalFlavorText or {}

DC_ColonyJobModal = ISCollapsableWindow:derive("DC_ColonyJobModal")
DC_ColonyJobModal.instance = nil
DC_ColonyJobModal.Internal = DC_ColonyJobModal.Internal or {}
DC_ColonyJobModal.Internal.FlavorText = FlavorText

require "DC/UI/Colony/ColonyJobModal/ColonyJobModal_Options"
require "DC/UI/Colony/ColonyJobModal/ColonyJobModal_List"
require "DC/UI/Colony/ColonyJobModal/ColonyJobModal_Layout"
require "DC/UI/Colony/ColonyJobModal/ColonyJobModal_Actions"

function DC_ColonyJobModal.Open(args)
    args = args or {}

    local config = DC_Colony and DC_Colony.Config or {}
    local jobOptions = DC_ColonyJobModal.Internal.BuildOrderedJobOptions(config, args.worker)
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
    local maxVisibleRows = math.max(1, math.floor((screenHeight - 220) / 28))
    local visibleRows = math.max(1, math.min(#jobOptions, 10, maxVisibleRows))
    local listHeight = math.max(28 + 8, math.floor((visibleRows * 28) + 8))
    local height = math.min(screenHeight - 80, 140 + listHeight + 56)
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2

    local modal = DC_ColonyJobModal:new(x, y, width, height)
    modal.title = tostring(args.title or FlavorText.windowTitle or "Change Job")
    modal.promptText = tostring(args.promptText or FlavorText.promptText or "Choose a job.")
    modal.currentJobLabel = tostring(currentJobLabel or "Unknown")
    modal.jobOptions = jobOptions
    modal.worker = args.worker
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
    o.title = FlavorText.windowTitle or "Change Job"
    o.resizable = false
    o.promptText = FlavorText.promptText or "Choose a job."
    o.currentJobLabel = "Unknown"
    o.jobOptions = {}
    o.worker = nil
    o.selectedJobType = nil
    o.selectedOptionIndex = nil
    o.autoRepeatJob = false
    o.onConfirmCallback = nil
    o.updatingSelection = false
    return o
end

return DC_ColonyJobModal