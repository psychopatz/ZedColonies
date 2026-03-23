DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

function Internal.getSupplyWindowLayoutMetrics(window)
    local th = window:titleBarHeight()
    local pad = 12
    local gap = 12
    local controlWidth = 88
    local headerTextH = 34
    local tabH = 22
    local tabGap = 6
    local searchH = 24
    local detailH = math.max(120, math.min(184, math.floor(window.height * 0.24)))

    local headerY = th + pad
    local tabsY = headerY + headerTextH
    local searchY = tabsY + tabH + 6
    local contentY = searchY + searchH + 10
    local footerY = window.height - pad - detailH
    local listH = math.max(180, footerY - contentY - 10)
    local listAreaWidth = window.width - (pad * 2) - controlWidth - (gap * 2)
    local leftWidth = math.floor(listAreaWidth / 2)
    local rightWidth = listAreaWidth - leftWidth
    local leftX = pad
    local controlX = leftX + leftWidth + gap
    local rightX = controlX + controlWidth + gap
    local centerButtonsY = contentY + math.floor(math.max(0, listH - 192) / 2)
    local detailY = contentY + listH + 10

    return {
        pad = pad,
        gap = gap,
        headerY = headerY,
        tabsY = tabsY,
        searchY = searchY,
        contentY = contentY,
        detailY = detailY,
        leftX = leftX,
        leftWidth = leftWidth,
        rightX = rightX,
        rightWidth = rightWidth,
        controlX = controlX,
        controlWidth = controlWidth,
        tabH = tabH,
        tabGap = tabGap,
        searchH = searchH,
        detailH = detailH,
        listH = listH,
        centerButtonsY = centerButtonsY,
    }
end
