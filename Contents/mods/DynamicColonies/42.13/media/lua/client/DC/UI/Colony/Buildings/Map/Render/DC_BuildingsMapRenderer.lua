require "DC/UI/Colony/Buildings/Utils/DC_BuildingsUIUtils"
require "DC/UI/Colony/Buildings/Map/Viewport/DC_BuildingsMapViewport"

DC_BuildingsMapRenderer = DC_BuildingsMapRenderer or {}

local Renderer = DC_BuildingsMapRenderer

local function drawTile(panel, plot, rect, selected)
    local color = DC_BuildingsUIUtils.GetPlotColor(plot)
    local border = selected == true and DC_BuildingsUIUtils.Colors.selectedBorder or DC_BuildingsUIUtils.Colors.defaultBorder

    panel:drawRect(rect.x, rect.y, rect.width, rect.height, color.a, color.r, color.g, color.b)
    panel:drawRectBorder(rect.x, rect.y, rect.width, rect.height, border.a, border.r, border.g, border.b)

    local title = tostring(DC_BuildingsUIUtils.GetPlotTitle(plot) or "")
    if title ~= "" then
        panel:drawTextCentre(title, rect.x + (rect.width / 2), rect.y + 4, 1, 1, 1, 1, UIFont.Small)
    end

    local imageX = rect.x + 10
    local imageY = rect.y + 20
    local imageW = rect.width - 20
    local imageH = rect.height - 42
    local texturePath = DC_BuildingsUIUtils.GetPlotTexturePath(plot)
    local texture = DC_BuildingsUIUtils.GetTexture(texturePath)
    if texture then
        panel:drawTextureScaledAspect(texture, imageX, imageY, imageW, imageH, 0.85, 1, 1, 1)
    end

    if plot.project and tostring(plot.project.materialState or "") == "Stalled" then
        panel:drawRect(imageX, imageY, imageW, imageH, 0.42, 0.95, 0.78, 0.18)
        panel:drawRect(imageX, imageY + imageH - 12, imageW, 12, 0.58, 0.95, 0.72, 0.12)
    elseif plot.project then
        local ratio = math.max(0, math.min(1, tonumber(plot.project.progressRatio) or 0))
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

    if not texture and plot.kind == "HQOnly" and not plot.building and not plot.project then
        panel:drawTextCentre("HQ Lot", rect.x + (rect.width / 2), rect.y + (rect.height / 2) - 8, 1, 0.92, 0.55, 1, UIFont.Small)
    elseif not texture and plot.frontierCandidate == true then
        panel:drawTextCentre("Claim", rect.x + (rect.width / 2), rect.y + (rect.height / 2) - 8, 0.92, 0.78, 0.62, 1, UIFont.Small)
    elseif not texture and plot.state == "Locked" then
        panel:drawTextCentre("Locked", rect.x + (rect.width / 2), rect.y + (rect.height / 2) - 8, 0.45, 0.45, 0.45, 1, UIFont.Small)
    end

    if plot.project then
        if tostring(plot.project.materialState or "") == "Stalled" then
            panel:drawTextCentre("Stalled", rect.x + (rect.width / 2), rect.y + rect.height - 22, 0.26, 0.18, 0.05, 1, UIFont.Small)
        else
            local ratio = math.max(0, math.min(1, tonumber(plot.project.progressRatio) or 0))
            local percent = math.floor((ratio * 100) + 0.5)
            panel:drawTextCentre(tostring(percent) .. "%", rect.x + (rect.width / 2), rect.y + rect.height - 22, 0.2, 0.12, 0.05, 1, UIFont.Small)
        end
    elseif plot.building and plot.building.level then
        panel:drawTextCentre("Lv " .. tostring(plot.building.level), rect.x + (rect.width / 2), rect.y + rect.height - 22, 1, 1, 1, 1, UIFont.Small)
    end
end

function Renderer.Draw(panel, snapshot, viewportState, selectedPlotKey)
    local plots = snapshot and snapshot.map and snapshot.map.plots or {}
    local territory = snapshot and snapshot.map or {}

    panel:drawText(tostring(DC_BuildingsUIUtils.GetColonyDisplayName()), 10, 8, 1, 1, 1, 1, UIFont.Medium)
    panel:drawText(
        "Unlocked " .. tostring(territory.unlockedPlotCount or 0)
            .. " | Ring "
            .. tostring(territory.currentFrontierRing or 1)
            .. " Barricades "
            .. tostring(territory.activeBarricadeCount or 0)
            .. "/"
            .. tostring(territory.maxActiveBarricades or 0),
        150,
        10,
        0.76,
        0.76,
        0.76,
        1,
        UIFont.Small
    )

    for _, plot in ipairs(plots) do
        local rect = DC_BuildingsMapViewport.GetPlotRect(plot, viewportState, panel.width, panel.height)
        if DC_BuildingsMapViewport.IsRectVisible(rect, panel.width, panel.height) then
            drawTile(panel, plot, rect, tostring(plot.key or "") == tostring(selectedPlotKey or ""))
        end
    end
end

return Renderer
