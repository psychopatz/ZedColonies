require "ISUI/ISButton"
require "DC/UI/Colony/Buildings/Map/DC_BuildingsMapPanel"
require "DC/UI/Colony/Buildings/Details/DC_BuildingsDetailsPanel"
require "DC/UI/Colony/Buildings/Actions/DC_BuildingsWindowActions"

DC_BuildingsWindowLayout = DC_BuildingsWindowLayout or {}

local Layout = DC_BuildingsWindowLayout

function Layout.GetMetrics(window)
    local th = window:titleBarHeight()
    local pad = 10
    local contentY = th + pad
    local contentH = window.height - th - (pad * 2) - 40
    local mapW = math.floor(window.width * 0.62)
    local detailsW = window.width - mapW - (pad * 3)

    return {
        th = th,
        pad = pad,
        contentY = contentY,
        contentH = contentH,
        mapW = mapW,
        detailsW = detailsW
    }
end

function Layout.LayoutChildren(window)
    local metrics = Layout.GetMetrics(window)

    if window.mapPanel then
        window.mapPanel:setX(metrics.pad)
        window.mapPanel:setY(metrics.contentY)
        window.mapPanel:setWidth(metrics.mapW)
        window.mapPanel:setHeight(metrics.contentH)
    end

    if window.detailsPanel then
        window.detailsPanel:setX((metrics.pad * 2) + metrics.mapW)
        window.detailsPanel:setY(metrics.contentY)
        window.detailsPanel:setWidth(metrics.detailsW)
        window.detailsPanel:setHeight(metrics.contentH)
        if window.detailsPanel.relayout then
            window.detailsPanel:relayout()
        end
    end

    if window.btnRefresh then
        window.btnRefresh:setX(window.width - 100)
        window.btnRefresh:setY(window.height - 30)
        window.btnRefresh:setWidth(90)
        window.btnRefresh:setHeight(24)
    end
end

function Layout.CreateChildren(window)
    ISCollapsableWindow.createChildren(window)

    local metrics = Layout.GetMetrics(window)

    window.mapPanel = DC_BuildingsMapPanel:new(metrics.pad, metrics.contentY, metrics.mapW, metrics.contentH, function(plot)
        window:onPlotSelected(plot)
    end)
    window.mapPanel:initialise()
    window.mapPanel:setAnchorLeft(true)
    window.mapPanel:setAnchorRight(false)
    window.mapPanel:setAnchorTop(true)
    window.mapPanel:setAnchorBottom(true)
    window:addChild(window.mapPanel)

    window.detailsPanel = DC_BuildingsDetailsPanel:new(
        (metrics.pad * 2) + metrics.mapW,
        metrics.contentY,
        metrics.detailsW,
        metrics.contentH,
        window,
        DC_BuildingsWindowActions
    )
    window.detailsPanel:initialise()
    window.detailsPanel:createChildren()
    window.detailsPanel:setAnchorLeft(false)
    window.detailsPanel:setAnchorRight(true)
    window.detailsPanel:setAnchorTop(true)
    window.detailsPanel:setAnchorBottom(true)
    window:addChild(window.detailsPanel)

    window.btnRefresh = ISButton:new(window.width - 100, window.height - 30, 90, 24, "Refresh", window, window.onRefresh)
    window.btnRefresh:initialise()
    window.btnRefresh:setAnchorLeft(false)
    window.btnRefresh:setAnchorRight(true)
    window.btnRefresh:setAnchorTop(false)
    window.btnRefresh:setAnchorBottom(true)
    window:addChild(window.btnRefresh)

    Layout.LayoutChildren(window)
    window:requestSnapshot()
end

return Layout