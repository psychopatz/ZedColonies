require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"

DT_BuildingActionModal = ISCollapsableWindow:derive("DT_BuildingActionModal")
DT_BuildingActionModal.instance = DT_BuildingActionModal.instance or nil

function DT_BuildingActionModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DT_BuildingActionModal:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()

    self.promptLabel = ISLabel:new(10, th + 14, 20, tostring(self.promptText or "Choose an action."), 1, 1, 1, 1, UIFont.Small, true)
    self.promptLabel:initialise()
    self:addChild(self.promptLabel)

    self.btnBuild = ISButton:new(10, self.height - 34, 90, 24, "Build", self, self.onBuildClicked)
    self.btnBuild:initialise()
    self:addChild(self.btnBuild)

    self.btnCancel = ISButton:new(self.width - 100, self.height - 34, 90, 24, "Cancel", self, self.onCancelClicked)
    self.btnCancel:initialise()
    self:addChild(self.btnCancel)
end

function DT_BuildingActionModal:onBuildClicked()
    if self.onBuildCallback then
        self.onBuildCallback(self.plot)
    end
    self:close()
end

function DT_BuildingActionModal:onCancelClicked()
    self:close()
end

function DT_BuildingActionModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DT_BuildingActionModal.instance == self then
        DT_BuildingActionModal.instance = nil
    end
end

function DT_BuildingActionModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function DT_BuildingActionModal.Open(args)
    args = args or {}
    if DT_BuildingActionModal.instance then
        DT_BuildingActionModal.instance:close()
    end

    local width = 260
    local height = 140
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local modal = DT_BuildingActionModal:new(x, y, width, height)
    modal.title = "Plot Actions"
    modal.plot = args.plot
    modal.promptText = "Plot " .. tostring(args.plot and args.plot.x or 0) .. "," .. tostring(args.plot and args.plot.y or 0)
    modal.onBuildCallback = args.onBuild
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:bringToTop()
    DT_BuildingActionModal.instance = modal
    return modal
end

return DT_BuildingActionModal
