DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function DC_SupplyWindow:render()
    ISCollapsableWindow.render(self)

    local layout = self.layout or {}
    local rightHeader = Internal.getWorkerHeaderTitle(self)
    local rightSummary = Internal.getActiveWorkerTabLabel(self) .. " | " .. Internal.getWorkerTabSummary(self, self.workerEntries)

    self:drawRectBorder(layout.leftX, layout.contentY, layout.leftWidth, layout.listH, 0.25, 1, 1, 1)
    self:drawRectBorder(layout.rightX, layout.contentY, layout.rightWidth, layout.listH, 0.25, 1, 1, 1)
    self:drawRectBorder(layout.pad, layout.detailY, self.width - (layout.pad * 2), layout.detailH, 0.22, 1, 1, 1)

    self:drawText("Player Inventory", layout.leftX or 12, layout.headerY or 36, 0.94, 0.96, 1, 1, UIFont.Medium)
    self:drawText(
        self.scanning and "Scanning inventory..." or "",
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

function DC_SupplyWindow:updateStatus(text)
    self.lastStatusMessage = tostring(text or "")
end
