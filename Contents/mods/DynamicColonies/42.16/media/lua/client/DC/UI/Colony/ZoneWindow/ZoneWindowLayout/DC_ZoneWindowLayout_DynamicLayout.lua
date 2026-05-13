-- ============================================================================
-- DC_ZoneWindowLayout_DynamicLayout.lua — Dynamic resize logic
-- ============================================================================

DC_ZoneWindow = DC_ZoneWindow or {}
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}
require "DC/UI/Colony/ZoneWindow/ZoneWindowState/DC_ZoneWindowState"

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
    local tabBarY   = toolbarY + L.TOOLBAR_HEIGHT + 2
    local tabBarH   = L.TAB_BAR_HEIGHT or 30
    local contentY  = tabBarY + tabBarH + pad
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

    -- Tab bar
    if window.tabBar then
        window.tabBar:setX(pad)
        window.tabBar:setY(tabBarY)
        window.tabBar:setWidth(window.width - pad * 2)
        window.tabBar:setHeight(tabBarH)
    end

    -- ===== ZONES TAB PANELS =====
    local isZonesTab = (window.activeTab == "TAB_ZONES")

    -- Zone list (left side)
    if window.zoneList then
        window.zoneList:setX(pad)
        window.zoneList:setY(contentY)
        window.zoneList:setWidth(listWidth)
        window.zoneList:setHeight(contentH)
        window.zoneList:setVisible(isZonesTab)
    end

    -- Detail panel (right top)
    if window.detailPanel then
        window.detailPanel:setX(rightX)
        window.detailPanel:setY(contentY)
        window.detailPanel:setWidth(rightWidth)
        window.detailPanel:setHeight(detailH)
        window.detailPanel:setVisible(isZonesTab)
    end

    -- Rect list (right bottom)
    if window.rectList then
        window.rectList:setX(rightX)
        window.rectList:setY(rectListY)
        window.rectList:setWidth(rightWidth)
        window.rectList:setHeight(rectListH)
        window.rectList:setVisible(isZonesTab)
    end

    -- Rect toolbar buttons
    if window.rectToolbar then
        window.rectToolbar:setX(rightX)
        window.rectToolbar:setY(rectListY + rectListH + 4)
        window.rectToolbar:setWidth(rightWidth)
        window.rectToolbar:setHeight(L.TOOLBAR_HEIGHT)
        window.rectToolbar:setVisible(isZonesTab)
    end

    -- ===== MAP TAB PANEL =====
    local isMapTab = (window.activeTab == "TAB_MAP")

    if window.mapPanel then
        window.mapPanel:setX(pad)
        window.mapPanel:setY(contentY)
        window.mapPanel:setWidth(window.width - pad * 2)
        window.mapPanel:setHeight(contentH)
        window.mapPanel:setVisible(isMapTab)
    end
end


ZoneWindowLayout.applyWindowLayout = applyWindowLayout
DC_ZoneWindow.applyDynamicLayout = applyWindowLayout


function DC_ZoneWindow:onResize()
    ISCollapsableWindow.onResize(self)
    applyWindowLayout(self)
end


--- Tab switching handler
function DC_ZoneWindow:onSwitchTab(button)
    if not button or not button.internal then return end
    self.activeTab = button.internal

    -- Update tab button styling
    local activeStyle = { r = 0.2, g = 0.2, b = 0.2, a = 1 }
    local activeBorder = { r = 0.6, g = 0.8, b = 1.0, a = 0.6 }
    local inactiveStyle = { r = 0, g = 0, b = 0, a = 0.5 }
    local inactiveBorder = { r = 1, g = 1, b = 1, a = 0.2 }

    if self.btnTabZones then
        if self.activeTab == "TAB_ZONES" then
            self.btnTabZones.backgroundColor = activeStyle
            self.btnTabZones.borderColor = activeBorder
        else
            self.btnTabZones.backgroundColor = inactiveStyle
            self.btnTabZones.borderColor = inactiveBorder
        end
    end

    if self.btnTabMap then
        if self.activeTab == "TAB_MAP" then
            self.btnTabMap.backgroundColor = activeStyle
            self.btnTabMap.borderColor = activeBorder
        else
            self.btnTabMap.backgroundColor = inactiveStyle
            self.btnTabMap.borderColor = inactiveBorder
        end
    end

    -- Re-feed zones to map overlay when switching to map
    if self.activeTab == "TAB_MAP" and self.mapPanel and self.mapPanel.refreshZones then
        self.mapPanel:refreshZones(
            DC_ZoneWindowState.GetZones(self),
            DC_ZoneWindowState.GetSelectedZone(self),
            DC_ZoneWindowState.GetSelectedRect(self)
        )
    end

    applyWindowLayout(self)
end
