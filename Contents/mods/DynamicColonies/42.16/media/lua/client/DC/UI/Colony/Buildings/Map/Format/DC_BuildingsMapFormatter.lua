require "DC/UI/Colony/Buildings/Utils/DC_BuildingsUIUtils"

DC_BuildingsMapFormatter = DC_BuildingsMapFormatter or {}

local Formatter = DC_BuildingsMapFormatter

function Formatter.GetHeaderText()
    return tostring(DC_BuildingsUIUtils.GetColonyDisplayName())
end

function Formatter.GetStatusText(territory)
    if territory and territory.frontierExpansionAvailable == true then
        return "Unlocked "
            .. tostring(territory.unlockedPlotCount or 0)
            .. " | Ring "
            .. tostring(territory.currentFrontierRing or 1)
            .. " Barricades "
            .. tostring(territory.activeBarricadeCount or 0)
            .. "/"
            .. tostring(territory.maxActiveBarricades or 0)
    end

    return "Unlocked "
        .. tostring(territory and territory.unlockedPlotCount or 0)
        .. " | Next Ring "
        .. tostring((territory and territory.nextFrontierRing) or (territory and territory.currentFrontierRing) or 1)
        .. " requires HQ Lv "
        .. tostring((territory and territory.frontierRequiredHQLevel) or (territory and territory.nextFrontierRing) or (territory and territory.currentFrontierRing) or 1)
end

local function getFallbackLabel(plot)
    if not plot then
        return nil
    end

    if plot.kind == "HQOnly" and not plot.building and not plot.project then
        return "HQ Lot"
    end

    if plot.frontierCandidate == true then
        if plot.state == "Locked" then
            return "Locked"
        end
        return "Claim"
    end

    if plot.state == "Locked" then
        return "Locked"
    end

    return nil
end

local function getFooterLabel(plot)
    if not plot then
        return nil
    end

    if plot.project then
        if tostring(plot.project.materialState or "") == "Stalled" then
            return "Stalled"
        end

        local ratio = math.max(0, math.min(1, tonumber(plot.project.progressRatio) or 0))
        local percent = math.floor((ratio * 100) + 0.5)
        return tostring(percent) .. "%"
    end

    if plot.building and plot.building.level then
        return "Lv " .. tostring(plot.building.level)
    end

    return nil
end

local function getProjectOverlay(plot)
    if not plot or not plot.project then
        return nil
    end

    if tostring(plot.project.materialState or "") == "Stalled" then
        return {
            mode = "stalled"
        }
    end

    return {
        mode = "progress",
        ratio = math.max(0, math.min(1, tonumber(plot.project.progressRatio) or 0))
    }
end

function Formatter.BuildPlotPresentation(plot)
    return {
        color = DC_BuildingsUIUtils.GetPlotColor(plot),
        title = tostring(DC_BuildingsUIUtils.GetPlotTitle(plot) or ""),
        texturePath = DC_BuildingsUIUtils.GetPlotTexturePath(plot),
        fallbackLabel = getFallbackLabel(plot),
        footerLabel = getFooterLabel(plot),
        projectOverlay = getProjectOverlay(plot)
    }
end

return Formatter