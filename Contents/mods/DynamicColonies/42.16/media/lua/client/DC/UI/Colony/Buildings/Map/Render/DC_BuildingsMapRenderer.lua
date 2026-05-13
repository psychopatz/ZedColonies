require "DC/UI/Colony/Buildings/Utils/DC_BuildingsUIUtils"
require "DC/UI/Colony/Buildings/Map/Viewport/DC_BuildingsMapViewport"
require "DC/UI/Colony/Buildings/Map/Format/DC_BuildingsMapFormatter"

DC_BuildingsMapRenderer = DC_BuildingsMapRenderer or {}

local Renderer = DC_BuildingsMapRenderer

local function drawTile(panel, rect, selected, presentation)
    local color = presentation.color or DC_BuildingsUIUtils.Colors.empty
    local border = selected == true and DC_BuildingsUIUtils.Colors.selectedBorder or DC_BuildingsUIUtils.Colors.defaultBorder

    panel:drawRect(rect.x, rect.y, rect.width, rect.height, color.a, color.r, color.g, color.b)
    panel:drawRectBorder(rect.x, rect.y, rect.width, rect.height, border.a, border.r, border.g, border.b)

    local title = tostring(presentation.title or "")
    if title ~= "" then
        panel:drawTextCentre(title, rect.x + (rect.width / 2), rect.y + 4, 1, 1, 1, 1, UIFont.Small)
    end

    local imageX = rect.x + 10
    local imageY = rect.y + 20
    local imageW = rect.width - 20
    local imageH = rect.height - 42
    local texture = DC_BuildingsUIUtils.GetTexture(presentation.texturePath)
    if texture then
        panel:drawTextureScaledAspect(texture, imageX, imageY, imageW, imageH, 0.85, 1, 1, 1)
    end

    if presentation.projectOverlay and presentation.projectOverlay.mode == "stalled" then
        panel:drawRect(imageX, imageY, imageW, imageH, 0.42, 0.95, 0.78, 0.18)
        panel:drawRect(imageX, imageY + imageH - 12, imageW, 12, 0.58, 0.95, 0.72, 0.12)
    elseif presentation.projectOverlay and presentation.projectOverlay.mode == "progress" then
        local ratio = math.max(0, math.min(1, tonumber(presentation.projectOverlay.ratio) or 0))
        local fillHeight = math.floor(imageH * ratio)
        if fillHeight > 0 then
            local fillY = imageY + imageH - fillHeight
            panel:drawRect(imageX, fillY, imageW, fillHeight, 0.5, 0.18, 0.72, 0.22)
            local edgeY = fillY - 2
            if edgeY >= imageY then
                panel:drawRect(imageX, edgeY, imageW, 2, 0.82, 0.45, 1, 0.48)
            end
        end
    end

    if not texture and presentation.fallbackLabel then
        local fallbackColor = presentation.fallbackLabel == "Locked"
            and { 0.45, 0.45, 0.45, 1 }
            or { 0.92, 0.78, 0.62, 1 }
        panel:drawTextCentre(presentation.fallbackLabel, rect.x + (rect.width / 2), rect.y + (rect.height / 2) - 8, fallbackColor[1], fallbackColor[2], fallbackColor[3], fallbackColor[4], UIFont.Small)
    end

    if presentation.footerLabel then
        local footerColor = presentation.footerLabel == "Stalled"
            and { 0.26, 0.18, 0.05, 1 }
            or (string.find(presentation.footerLabel, "^Lv ", 1) and { 1, 1, 1, 1 } or { 0.2, 0.12, 0.05, 1 })
        panel:drawTextCentre(presentation.footerLabel, rect.x + (rect.width / 2), rect.y + rect.height - 22, footerColor[1], footerColor[2], footerColor[3], footerColor[4], UIFont.Small)
    end
end

function Renderer.DrawHeader(panel, territory, syncInfo)
    territory = territory or {}

    panel:drawText(tostring(DC_BuildingsMapFormatter.GetHeaderText()), 10, 8, 1, 1, 1, 1, UIFont.Medium)
    panel:drawText(DC_BuildingsMapFormatter.GetStatusText(territory), 150, 10, 0.76, 0.76, 0.76, 1, UIFont.Small)

    local syncText = DC_BuildingsMapFormatter.GetSyncStatusText(syncInfo)
    if syncText then
        panel:drawTextRight(syncText, panel.width - 10, 10, 0.9, 0.82, 0.5, 1, UIFont.Small)
    end
end

function Renderer.DrawTiles(panel, snapshot, viewportState, selectedPlotKey, syncInfo)
    local plots = snapshot and snapshot.map and snapshot.map.plots or {}
    local state = tostring(syncInfo and syncInfo.state or "idle")

    panel:drawRect(0, 0, panel.width, panel.height, 0.1, 1, 1, 1)
    panel:drawRectBorder(0, 0, panel.width, panel.height, 0.08, 1, 1, 1)

    for _, plot in ipairs(plots) do
        local rect = DC_BuildingsMapViewport.GetPlotRect(plot, viewportState, panel.width, panel.height)
        if DC_BuildingsMapViewport.IsRectVisible(rect, panel.width, panel.height) then
            local presentation = DC_BuildingsMapFormatter.BuildPlotPresentation(plot)
            drawTile(panel, rect, tostring(plot.key or "") == tostring(selectedPlotKey or ""), presentation)
        end
    end

    if #plots <= 0 and (state == "loading" or state == "partial") then
        panel:drawTextCentre("Loading colony map...", panel.width / 2, (panel.height / 2) - 10, 0.9, 0.9, 0.9, 1, UIFont.Medium)
        return
    end

    if #plots <= 0 and state == "error" then
        panel:drawTextCentre("Colony map sync failed.", panel.width / 2, (panel.height / 2) - 18, 0.92, 0.62, 0.62, 1, UIFont.Medium)
        panel:drawTextCentre(tostring(syncInfo and syncInfo.message or "Retrying..."), panel.width / 2, (panel.height / 2) + 4, 0.82, 0.82, 0.82, 1, UIFont.Small)
        return
    end

    if #plots <= 0 and state == "ready" then
        panel:drawTextCentre("No visible colony plots.", panel.width / 2, (panel.height / 2) - 10, 0.82, 0.82, 0.82, 1, UIFont.Medium)
        return
    end
end

function Renderer.Draw(panel, snapshot, viewportState, selectedPlotKey)
    local territory = snapshot and snapshot.map or {}

    Renderer.DrawHeader(panel, territory, snapshot and snapshot.sync or {})
    Renderer.DrawTiles(panel, snapshot, viewportState, selectedPlotKey, snapshot and snapshot.sync or {})
end

return Renderer
