DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

local DetailSupportIconPanel = ISPanel:derive("DT_SupplyWindowDetailSupportIconPanel")

function DetailSupportIconPanel:prerender()
    ISPanel.prerender(self)
end

function DetailSupportIconPanel:render()
    local title = tostring(self.title or "")
    local entries = self.entries or {}
    if title == "" and #entries <= 0 then
        return
    end

    self:drawText(title, 0, 0, 0.82, 0.82, 0.82, 1, UIFont.Small)

    local size = Internal.DETAIL_SUPPORT_ICON_SIZE or 24
    local gap = 6
    local x = 0
    local y = 18
    local maxX = self.width - size

    for _, entry in ipairs(entries) do
        local tex = entry and entry.texture or nil
        if x > maxX then
            break
        end

        self:drawRectBorder(x - 1, y - 1, size + 2, size + 2, 0.2, 1, 1, 1)
        if tex then
            self:drawTextureScaled(tex, x, y, size, size, 1, 1, 1, 1)
        else
            self:drawTextCentre("?", x + (size / 2), y + 4, 0.85, 0.85, 0.85, 1, UIFont.Small)
        end

        x = x + size + gap
    end
end

function DetailSupportIconPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.entries = {}
    o.title = ""
    return o
end

function DT_SupplyWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    local layout = Internal.getSupplyWindowLayoutMetrics(self)
    local supportPanelHeight = Internal.DETAIL_SUPPORT_PANEL_HEIGHT or 56

    self.playerSearch = ISTextEntryBox:new("", layout.leftX, layout.searchY, layout.leftWidth, layout.searchH)
    self.playerSearch:initialise()
    self:addChild(self.playerSearch)

    self.workerSearch = ISTextEntryBox:new("", layout.rightX, layout.searchY, layout.rightWidth, layout.searchH)
    self.workerSearch:initialise()
    self:addChild(self.workerSearch)

    self.btnTabProvisions = ISButton:new(layout.rightX, layout.tabsY, 80, layout.tabH, "Provisions", self, self.onSelectProvisionsTab)
    self.btnTabProvisions:initialise()
    self:addChild(self.btnTabProvisions)

    self.btnTabOutput = ISButton:new(layout.rightX, layout.tabsY, 80, layout.tabH, "Merchandise", self, self.onSelectOutputTab)
    self.btnTabOutput:initialise()
    self:addChild(self.btnTabOutput)

    self.btnTabEquipment = ISButton:new(layout.rightX, layout.tabsY, 80, layout.tabH, "Equipment", self, self.onSelectEquipmentTab)
    self.btnTabEquipment:initialise()
    self:addChild(self.btnTabEquipment)

    self.btnRefresh = ISButton:new(layout.controlX, layout.searchY, layout.controlWidth, layout.searchH, "Sync", self, self.onRefresh)
    self.btnRefresh:initialise()
    self:addChild(self.btnRefresh)

    self.btnWithdrawSelected = ISButton:new(layout.controlX, layout.centerButtonsY, layout.controlWidth, 32, "<", self, self.onWithdrawSelected)
    self.btnWithdrawSelected:initialise()
    self:addChild(self.btnWithdrawSelected)

    self.btnWithdrawVisible = ISButton:new(layout.controlX, layout.centerButtonsY + 40, layout.controlWidth, 32, "<<", self, self.onWithdrawVisible)
    self.btnWithdrawVisible:initialise()
    self:addChild(self.btnWithdrawVisible)

    self.btnDepositSelected = ISButton:new(layout.controlX, layout.centerButtonsY + 80, layout.controlWidth, 32, ">", self, self.onDepositSelected)
    self.btnDepositSelected:initialise()
    self:addChild(self.btnDepositSelected)

    self.btnDepositVisible = ISButton:new(layout.controlX, layout.centerButtonsY + 120, layout.controlWidth, 32, ">>", self, self.onDepositVisible)
    self.btnDepositVisible:initialise()
    self:addChild(self.btnDepositVisible)

    self.btnDropSelected = ISButton:new(layout.controlX, layout.centerButtonsY + 160, layout.controlWidth, 32, "Drop", self, self.onDropSelected)
    self.btnDropSelected:initialise()
    self:addChild(self.btnDropSelected)

    self.playerList = Internal.LabourSupplyList:new(layout.leftX, layout.contentY, layout.leftWidth, layout.listH, "player")
    self.playerList:initialise()
    self.playerList:instantiate()
    self.playerList.target = self
    self.playerList.onmousedown = DT_SupplyWindow.onPlayerListMouseDown
    self.playerList.drawBorder = true
    self:addChild(self.playerList)

    self.workerList = Internal.LabourSupplyList:new(layout.rightX, layout.contentY, layout.rightWidth, layout.listH, "worker")
    self.workerList:initialise()
    self.workerList:instantiate()
    self.workerList.target = self
    self.workerList.onmousedown = DT_SupplyWindow.onWorkerListMouseDown
    self.workerList.drawBorder = true
    self:addChild(self.workerList)

    self.detailText = ISRichTextPanel:new(layout.pad, layout.detailY, self.width - (layout.pad * 2), layout.detailH - supportPanelHeight)
    self.detailText:initialise()
    self.detailText.backgroundColor = { r = 0, g = 0, b = 0, a = 0.26 }
    self.detailText.borderColor = { r = 1, g = 1, b = 1, a = 0.12 }
    self.detailText:addScrollBars()
    self:addChild(self.detailText)

    self.detailSupportPanel = DetailSupportIconPanel:new(
        layout.pad + 4,
        layout.detailY + layout.detailH - supportPanelHeight + 4,
        self.width - (layout.pad * 2) - 8,
        supportPanelHeight - 8
    )
    self.detailSupportPanel:initialise()
    self.detailSupportPanel:setVisible(false)
    self:addChild(self.detailSupportPanel)

    self:relayout()
    self:refreshTabButtons()
    self:updateTransferControls()
    self:updateItemDetail(nil, nil)
end
