DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function DC_SupplyWindow:relayout()
    local layout = Internal.getSupplyWindowLayoutMetrics(self)
    local supportPanelHeight = Internal.DETAIL_SUPPORT_PANEL_HEIGHT or 64
    local supportPanelGap = Internal.DETAIL_SUPPORT_PANEL_GAP or 6
    self.layout = layout

    self.playerSearch:setX(layout.leftX)
    self.playerSearch:setY(layout.searchY)
    self.playerSearch:setWidth(layout.leftWidth)
    self.playerSearch:setHeight(layout.searchH)

    self.workerSearch:setX(layout.rightX)
    self.workerSearch:setY(layout.searchY)
    self.workerSearch:setWidth(layout.rightWidth)
    self.workerSearch:setHeight(layout.searchH)

    local tabWidth = math.floor((layout.rightWidth - (layout.tabGap * 2)) / 3)
    self.btnTabProvisions:setX(layout.rightX)
    self.btnTabProvisions:setY(layout.tabsY)
    self.btnTabProvisions:setWidth(tabWidth)
    self.btnTabProvisions:setHeight(layout.tabH)

    self.btnTabOutput:setX(layout.rightX + tabWidth + layout.tabGap)
    self.btnTabOutput:setY(layout.tabsY)
    self.btnTabOutput:setWidth(tabWidth)
    self.btnTabOutput:setHeight(layout.tabH)

    self.btnTabEquipment:setX(layout.rightX + ((tabWidth + layout.tabGap) * 2))
    self.btnTabEquipment:setY(layout.tabsY)
    self.btnTabEquipment:setWidth(layout.rightWidth - ((tabWidth + layout.tabGap) * 2))
    self.btnTabEquipment:setHeight(layout.tabH)

    self.btnRefresh:setX(layout.controlX)
    self.btnRefresh:setY(layout.searchY)
    self.btnRefresh:setWidth(layout.controlWidth)
    self.btnRefresh:setHeight(layout.searchH)

    self.btnWithdrawSelected:setX(layout.controlX)
    self.btnWithdrawSelected:setY(layout.centerButtonsY)
    self.btnWithdrawSelected:setWidth(layout.controlWidth)

    self.btnWithdrawVisible:setX(layout.controlX)
    self.btnWithdrawVisible:setY(layout.centerButtonsY + 40)
    self.btnWithdrawVisible:setWidth(layout.controlWidth)

    self.btnDepositSelected:setX(layout.controlX)
    self.btnDepositSelected:setY(layout.centerButtonsY + 80)
    self.btnDepositSelected:setWidth(layout.controlWidth)

    self.btnDepositVisible:setX(layout.controlX)
    self.btnDepositVisible:setY(layout.centerButtonsY + 120)
    self.btnDepositVisible:setWidth(layout.controlWidth)

    if self.btnDropSelected then
        self.btnDropSelected:setX(layout.controlX)
        self.btnDropSelected:setY(layout.centerButtonsY + 160)
        self.btnDropSelected:setWidth(layout.controlWidth)
        self.btnDropSelected:setHeight(32)
    end

    if self.btnAutoEquipNow then
        self.btnAutoEquipNow:setX(layout.controlX)
        self.btnAutoEquipNow:setY(layout.centerButtonsY + 200)
        self.btnAutoEquipNow:setWidth(layout.controlWidth)
        self.btnAutoEquipNow:setHeight(32)
    end

    if self.btnAutoEquipToggle then
        self.btnAutoEquipToggle:setX(layout.controlX)
        self.btnAutoEquipToggle:setY(layout.centerButtonsY + 240)
        self.btnAutoEquipToggle:setWidth(layout.controlWidth)
        self.btnAutoEquipToggle:setHeight(32)
    end

    self.playerList:setX(layout.leftX)
    self.playerList:setY(layout.contentY)
    self.playerList:setWidth(layout.leftWidth)
    self.playerList:setHeight(layout.listH)
    self.playerList.width = layout.leftWidth
    self.playerList.height = layout.listH

    self.workerList:setX(layout.rightX)
    self.workerList:setY(layout.contentY)
    self.workerList:setWidth(layout.rightWidth)
    self.workerList:setHeight(layout.listH)
    self.workerList.width = layout.rightWidth
    self.workerList.height = layout.listH

    self.detailText:setX(layout.pad)
    self.detailText:setY(layout.detailY)
    self.detailText:setWidth(self.width - (layout.pad * 2))
    self.detailText:setHeight(layout.detailH - supportPanelHeight - supportPanelGap)

    if self.detailSupportPanel then
        self.detailSupportPanel:setX(layout.pad)
        self.detailSupportPanel:setY(layout.detailY + layout.detailH - supportPanelHeight)
        self.detailSupportPanel:setWidth(self.width - (layout.pad * 2))
        self.detailSupportPanel:setHeight(supportPanelHeight)
    end

    if self.detailText.vscroll then
        self.detailText.vscroll:setHeight(self.detailText:getHeight())
    end
    if self.refreshDetailSelection then
        self:refreshDetailSelection()
    end
    self:refreshTabButtons()
    self:updateTransferControls()
end

function DC_SupplyWindow:onResize()
    ISCollapsableWindow.onResize(self)
    self:relayout()
end
