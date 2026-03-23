DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal
Internal.MainWindowLayout = Internal.MainWindowLayout or {}

local MainWindowLayout = Internal.MainWindowLayout

MainWindowLayout.AUTO_REFRESH_FRAMES = 60
MainWindowLayout.OWNED_FACTION_REFRESH_FRAMES = 300
MainWindowLayout.DETAIL_PANEL_MIN_HEIGHT = 120
MainWindowLayout.ACTIVITY_PANEL_MIN_HEIGHT = 150
MainWindowLayout.PANEL_INNER_PAD = 6
MainWindowLayout.PANEL_HEADER_HEIGHT = 24
MainWindowLayout.WINDOW_HEADER_CLEARANCE = 24

function MainWindowLayout.getRichTextPanelScroll(panel)
    if not panel then
        return 0
    end

    if panel.getYScroll then
        local ok, value = pcall(panel.getYScroll, panel)
        if ok and tonumber(value) then
            return tonumber(value)
        end
    end

    return tonumber(panel.yScroll) or 0
end

function MainWindowLayout.getRichTextContentHeight(panel)
    if not panel then
        return 0
    end

    local directHeight = tonumber(panel.textHeight) or tonumber(panel.contentHeight)
    if directHeight and directHeight > 0 then
        return directHeight
    end

    local getter = panel.getScrollHeight or panel.getTextHeight
    if getter then
        local ok, value = pcall(getter, panel)
        if ok and tonumber(value) and tonumber(value) > 0 then
            return tonumber(value)
        end
    end

    return 0
end

function MainWindowLayout.setRichTextPanelScroll(panel, scrollY)
    if not panel then
        return
    end

    local contentHeight = MainWindowLayout.getRichTextContentHeight(panel)
    local viewportHeight = math.max(0, tonumber(panel.getHeight and panel:getHeight()) or tonumber(panel.height) or 0)
    local maxScroll = math.max(0, contentHeight - viewportHeight)
    local minScroll = -maxScroll
    local clampedScroll = math.max(minScroll, math.min(0, tonumber(scrollY) or 0))

    if panel.setYScroll then
        panel:setYScroll(clampedScroll)
    else
        panel.yScroll = clampedScroll
    end
end

function MainWindowLayout.refreshRichTextPanel(panel, scrollY)
    if not panel then
        return
    end

    local targetScroll = scrollY
    if targetScroll == nil then
        targetScroll = MainWindowLayout.getRichTextPanelScroll(panel)
    end

    panel.textDirty = true
    panel:paginate()
    if panel.recalcSize then
        panel:recalcSize()
    end
    if panel.vscroll then
        panel.vscroll:setX(panel:getWidth() - 16)
        panel.vscroll:setY(0)
        panel.vscroll:setHeight(panel:getHeight())
    end
    MainWindowLayout.setRichTextPanelScroll(panel, targetScroll)
end
