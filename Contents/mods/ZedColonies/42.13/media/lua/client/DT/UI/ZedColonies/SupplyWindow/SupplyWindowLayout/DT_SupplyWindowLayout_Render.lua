DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

function DT_SupplyWindow:render()
    ISCollapsableWindow.render(self)

    local layout = self.layout or {}
    local playerVisible = self.playerList and self.playerList.items and #self.playerList.items or 0
    local playerTotal = #(self.playerEntries or {})
    local rightHeader = Internal.getWorkerHeaderTitle(self)
    local rightSummary = Internal.getActiveWorkerTabLabel(self) .. " | " .. Internal.getWorkerTabSummary(self, self.workerEntries)

    self:drawRectBorder(layout.leftX, layout.contentY, layout.leftWidth, layout.listH, 0.25, 1, 1, 1)
    self:drawRectBorder(layout.rightX, layout.contentY, layout.rightWidth, layout.listH, 0.25, 1, 1, 1)
    self:drawRectBorder(layout.pad, layout.detailY, self.width - (layout.pad * 2), layout.detailH, 0.22, 1, 1, 1)

    self:drawText("Player Inventory", layout.leftX or 12, layout.headerY or 36, 0.94, 0.96, 1, 1, UIFont.Medium)
    self:drawText(
        self.scanning and ("Scanning " .. tostring(self.scanProcessed or 0) .. " items...")
            or (tostring(playerVisible) .. " visible / " .. tostring(playerTotal) .. " cached"),
        layout.leftX or 12,
        (layout.headerY or 36) + 18,
        0.7,
        0.7,
        0.7,
        1,
        UIFont.Small
    )

    self:drawText("Transfer", (layout.controlX or 0) + 16, layout.headerY or 36, 0.9, 0.9, 0.9, 1, UIFont.Small)

    self:drawText(rightHeader, layout.rightX or 12, layout.headerY or 36, 0.94, 0.96, 1, 1, UIFont.Medium)
    self:drawText(
        rightSummary,
        layout.rightX or 12,
        (layout.headerY or 36) + 18,
        0.7,
        0.7,
        0.7,
        1,
        UIFont.Small
    )
end

function DT_SupplyWindow:updateStatus(text)
    self.lastStatusMessage = tostring(text or "")
end
