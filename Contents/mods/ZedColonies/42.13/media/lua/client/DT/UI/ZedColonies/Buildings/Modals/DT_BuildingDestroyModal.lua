require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISRichTextPanel"

DT_BuildingDestroyModal = ISCollapsableWindow:derive("DT_BuildingDestroyModal")
DT_BuildingDestroyModal.instance = DT_BuildingDestroyModal.instance or nil

function DT_BuildingDestroyModal:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end

function DT_BuildingDestroyModal:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()

    self.textPanel = ISRichTextPanel:new(10, th + 10, self.width - 20, self.height - th - 58)
    self.textPanel:initialise()
    self.textPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textPanel.clip = true
    self.textPanel.autosetheight = false
    self.textPanel:setText(self.promptText or "")
    self.textPanel:paginate()
    self:addChild(self.textPanel)

    self.btnConfirm = ISButton:new(self.width - 200, self.height - 34, 90, 24, "Destroy", self, self.onConfirmClicked)
    self.btnConfirm:initialise()
    self.btnConfirm:setAnchorBottom(true)
    self.btnConfirm:setEnable(self.canConfirm == true)
    self:addChild(self.btnConfirm)

    self.btnCancel = ISButton:new(self.width - 100, self.height - 34, 90, 24, "Cancel", self, self.onCancelClicked)
    self.btnCancel:initialise()
    self.btnCancel:setAnchorBottom(true)
    self:addChild(self.btnCancel)
end

function DT_BuildingDestroyModal:onConfirmClicked()
    if self.canConfirm == true and self.onConfirmCallback then
        self.onConfirmCallback(self.plot)
    end
    self:close()
end

function DT_BuildingDestroyModal:onCancelClicked()
    self:close()
end

function DT_BuildingDestroyModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if DT_BuildingDestroyModal.instance == self then
        DT_BuildingDestroyModal.instance = nil
    end
end

function DT_BuildingDestroyModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function DT_BuildingDestroyModal.Open(args)
    args = args or {}
    if DT_BuildingDestroyModal.instance then
        DT_BuildingDestroyModal.instance:close()
    end

    local plot = args.plot or {}
    local building = plot.building or {}
    local canDestroy = building.canDestroy == true
    local title = tostring(building.displayName or building.buildingType or "Building")
    local promptText = ""
    promptText = promptText .. " <RGB:1,1,1> <SIZE:Medium> Destroy " .. title .. "? <LINE> "
    if canDestroy then
        promptText = promptText .. " <RGB:0.88,0.72,0.72> This will permanently remove the building from plot "
            .. tostring(plot.x or 0)
            .. ","
            .. tostring(plot.y or 0)
            .. ". <LINE> "
        promptText = promptText .. " <RGB:0.78,0.78,0.78> This action does not refund materials. <LINE> "
    else
        promptText = promptText .. " <RGB:0.72,0.62,0.62> "
            .. tostring(building.destroyReason or "This building cannot be destroyed right now.")
            .. " <LINE> "
    end

    local width = 430
    local height = 240
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local modal = DT_BuildingDestroyModal:new(x, y, width, height)
    modal.title = "Confirm Demolition"
    modal.plot = plot
    modal.canConfirm = canDestroy
    modal.promptText = promptText
    modal.onConfirmCallback = args.onConfirm
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:bringToTop()
    DT_BuildingDestroyModal.instance = modal
    return modal
end

return DT_BuildingDestroyModal
