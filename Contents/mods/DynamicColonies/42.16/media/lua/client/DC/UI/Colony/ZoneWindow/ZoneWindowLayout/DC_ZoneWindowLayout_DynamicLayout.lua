-- ============================================================================
-- DC_ZoneWindowLayout_DynamicLayout.lua — Dynamic resize logic
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}

local ZoneWindowLayout = DC_ZoneWindow.Internal.ZoneWindowLayout or {}
DC_ZoneWindow.Internal.ZoneWindowLayout = ZoneWindowLayout


local function applyWindowLayout(window)
    if not window then return end

    local L = ZoneWindowLayout
    local th  = window:titleBarHeight()
    local pad = 10

    -- Vertical anchors
    local headerY   = th + pad + L.WINDOW_HEADER_CLEARANCE
    local toolbarY  = headerY + L.HEADER_HEIGHT + 4
    local contentY  = toolbarY + L.TOOLBAR_HEIGHT + pad
    local footerH   = L.BUTTON_BAR_HEIGHT
    local contentH  = window.height - contentY - footerH - pad

    -- Horizontal split: list (left) | detail (right)
    local listWidth  = math.max(L.LIST_MIN_WIDTH, math.floor(window.width * 0.35))
    local rightX     = listWidth + (pad * 2)
    local rightWidth = math.max(100, window.width - rightX - pad)

    -- Right side vertical split: detail (top) | rect list (bottom)
    local splitGap   = 8
    local detailH    = math.max(L.DETAIL_MIN_HEIGHT, math.floor(contentH * 0.45))
    local rectListY  = contentY + detailH + splitGap
    local rectListH  = math.max(L.RECT_LIST_MIN_HEIGHT, contentH - detailH - splitGap)

    -- Header panel
    if window.headerPanel then
        window.headerPanel:setX(0)
        window.headerPanel:setY(th)
        window.headerPanel:setWidth(window.width)
        window.headerPanel:setHeight(L.HEADER_HEIGHT)
    end

    -- Toolbar
    if window.toolbar then
        window.toolbar:setX(pad)
        window.toolbar:setY(toolbarY)
        window.toolbar:setWidth(window.width - pad * 2)
        window.toolbar:setHeight(L.TOOLBAR_HEIGHT)
    end

    -- Zone list (left side)
    if window.zoneList then
        window.zoneList:setX(pad)
        window.zoneList:setY(contentY)
        window.zoneList:setWidth(listWidth)
        window.zoneList:setHeight(contentH)
    end

    -- Detail panel (right top)
    if window.detailPanel then
        window.detailPanel:setX(rightX)
        window.detailPanel:setY(contentY)
        window.detailPanel:setWidth(rightWidth)
        window.detailPanel:setHeight(detailH)
    end

    -- Rect list (right bottom)
    if window.rectList then
        window.rectList:setX(rightX)
        window.rectList:setY(rectListY)
        window.rectList:setWidth(rightWidth)
        window.rectList:setHeight(rectListH)
    end

    -- Rect toolbar buttons (inside rectList footer area)
    if window.rectToolbar then
        window.rectToolbar:setX(rightX)
        window.rectToolbar:setY(rectListY + rectListH + 4)
        window.rectToolbar:setWidth(rightWidth)
        window.rectToolbar:setHeight(L.TOOLBAR_HEIGHT)
    end
end


ZoneWindowLayout.applyWindowLayout = applyWindowLayout
DC_ZoneWindow.applyDynamicLayout = applyWindowLayout


function DC_ZoneWindow:onResize()
    ISCollapsableWindow.onResize(self)
    applyWindowLayout(self)
end
