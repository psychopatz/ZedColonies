DC_BuildingsUIUtils = DC_BuildingsUIUtils or {}

DC_BuildingsUIUtils.Colors = {
    locked = { r = 0.12, g = 0.12, b = 0.12, a = 0.9 },
    frontierLocked = { r = 0.18, g = 0.1, b = 0.1, a = 0.92 },
    empty = { r = 0.18, g = 0.18, b = 0.18, a = 0.9 },
    queuedProject = { r = 0.22, g = 0.22, b = 0.22, a = 0.94 },
    reserved = { r = 0.85, g = 0.72, b = 0.15, a = 0.95 },
    built = { r = 0.26, g = 0.36, b = 0.24, a = 0.95 },
    selectedBorder = { r = 1, g = 0.95, b = 0.45, a = 0.95 },
    defaultBorder = { r = 0.85, g = 0.85, b = 0.85, a = 0.2 }
}

function DC_BuildingsUIUtils.IsProjectStarted(plot)
    local project = plot and plot.project or nil
    if not project then
        return false
    end

    local progressWorkPoints = math.max(0, tonumber(project.progressWorkPoints) or 0)
    local progressRatio = math.max(0, tonumber(project.progressRatio) or 0)
    return progressWorkPoints > 0 or progressRatio > 0
end

function DC_BuildingsUIUtils.GetPlotColor(plot)
    local colors = DC_BuildingsUIUtils.Colors
    if not plot then
        return colors.locked
    end
    if plot.state == "Locked" and plot.frontierCandidate == true then
        return colors.frontierLocked
    end
    if plot.state == "Locked" then
        return colors.locked
    end
    if plot.project then
        if DC_BuildingsUIUtils.IsProjectStarted(plot) then
            return colors.reserved
        end
        return colors.queuedProject
    end
    if plot.state == "Reserved" then
        return colors.reserved
    end
    if plot.state == "Built" then
        return colors.built
    end
    return colors.empty
end

function DC_BuildingsUIUtils.GetPlotTitle(plot)
    if not plot then
        return ""
    end
    if plot.building then
        return tostring(plot.building.displayName or plot.building.buildingType or "Building")
    end
    if plot.project then
        return tostring(plot.project.displayName or plot.project.buildingType or "Building")
    end
    if plot.frontierCandidate == true then
        return "Unsafe Zone"
    end
    if plot.kind == "HQOnly" then
        return "HQ"
    end
    return ""
end

function DC_BuildingsUIUtils.GetPlotTexturePath(plot)
    if not plot then
        return nil
    end
    if plot.building and plot.building.iconPath then
        return plot.building.iconPath
    end
    if plot.project and plot.project.iconPath then
        return plot.project.iconPath
    end
    if plot.kind == "HQOnly" then
        return "media/ui/Buildings/DC_Headquarters.png"
    end
    return nil
end

function DC_BuildingsUIUtils.BuildRecipeLines(recipeEntries)
    local lines = {}
    for _, entry in ipairs(recipeEntries or {}) do
        local ready = entry.satisfied == true
        local availableToSupply = math.max(0, tonumber(entry.available) or 0)
        local remainingToSupply = math.max(0, tonumber(entry.remaining) or 0)
        local canSupplyNow = ready ~= true and remainingToSupply > 0 and availableToSupply > 0
        local color = ready and "<RGB:0.76,0.92,0.76>" or (canSupplyNow and "<RGB:0.92,0.84,0.45>" or "<RGB:0.95,0.62,0.62>")
        local line = color
            .. tostring(entry.count or 0)
            .. " x "
            .. tostring(entry.displayName or entry.fullType or "Item")
        if entry.supplied ~= nil or entry.remaining ~= nil then
            line = line
                .. " <RGB:0.72,0.72,0.72>("
                .. tostring(entry.supplied or 0)
                .. " supplied, "
                .. tostring(availableToSupply)
                .. " available to supply"
            if remainingToSupply <= 0 then
                line = line .. ", fully supplied)"
            elseif availableToSupply > 0 then
                line = line .. ", " .. tostring(remainingToSupply) .. " still needs supplying)"
            else
                line = line .. ", " .. tostring(remainingToSupply) .. " missing)"
            end
        else
            line = line
                .. " <RGB:0.72,0.72,0.72>("
                .. tostring(entry.available or 0)
                .. " available)"
        end
        lines[#lines + 1] = line
    end
    if #lines <= 0 then
        lines[1] = "<RGB:0.65,0.65,0.65>No materials required."
    end
    return lines
end

function DC_BuildingsUIUtils.GetTexture(path)
    if not path or not getTexture then
        return nil
    end
    return getTexture(path)
end

function DC_BuildingsUIUtils.GetOptionStatusLabel(option)
    option = option or {}
    if option.enabled == true then
        return "Available"
    end

    local reason = string.lower(tostring(option.disabledReason or ""))
    if reason == "" then
        return "Unavailable"
    end
    if string.find(reason, "placeholder", 1, true) or string.find(reason, "not available yet", 1, true) then
        return "Coming Soon"
    end
    if string.find(reason, "locked", 1, true) then
        return "Locked"
    end
    if string.find(reason, "center plot", 1, true) then
        return "Center Plot Only"
    end
    if string.find(reason, "ring already has a warehouse", 1, true) then
        return "One Per Ring"
    end
    if string.find(reason, "active project", 1, true) then
        return "Project Active"
    end
    if string.find(reason, "not empty", 1, true) then
        return "Plot Occupied"
    end

    return "Unavailable"
end

function DC_BuildingsUIUtils.BuildOptionDetailText(option)
    option = option or {}
    local preview = option.preview or {}
    local text = ""
    local statusLabel = DC_BuildingsUIUtils.GetOptionStatusLabel(option)

    text = text .. " <RGB:1,1,1> <SIZE:Medium> " .. tostring(option.displayName or option.buildingType or "Building") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Status: <RGB:1,1,1> "
        .. tostring(statusLabel)
        .. " <LINE> "
    if preview.mode == "install" then
        text = text .. " <RGB:0.72,0.72,0.72> Building Level: <RGB:1,1,1>  " .. tostring(preview.targetLevel or 0) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Installed: <RGB:1,1,1> "
            .. tostring(option.currentCount or preview.currentInstallCount or 0)
            .. " / "
            .. tostring(option.maxCount or preview.maxInstallCount or 0)
            .. " <LINE> "
    else
        text = text .. " <RGB:0.72,0.72,0.72> Target Level: <RGB:1,1,1>  " .. tostring(preview.targetLevel or 0) .. " <LINE> "
    end
    text = text .. " <RGB:0.72,0.72,0.72> Work Points: <RGB:1,1,1>  " .. tostring(preview.workPoints or 0) .. " <LINE> "

    if option.description and option.description ~= "" then
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Role <LINE> "
        text = text .. " <RGB:0.84,0.84,0.84> " .. tostring(option.description) .. " <LINE> "
    end

    if option.effectLines and #option.effectLines > 0 then
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Effects <LINE> "
        for _, line in ipairs(option.effectLines or {}) do
            text = text .. " <RGB:0.82,0.82,0.82> - " .. tostring(line) .. " <LINE> "
        end
    end

    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Materials <LINE> "
    for _, line in ipairs(DC_BuildingsUIUtils.BuildRecipeLines(preview.recipeAvailability and preview.recipeAvailability.entries or {})) do
        text = text .. " " .. line .. " <LINE> "
    end
    if option.enabled == true and preview.canStart ~= true then
        text = text .. " <RGB:0.92,0.84,0.45> Can be queued now, but it will stay stalled until all materials are supplied. <LINE> "
    end

    if option.enabled ~= true then
        text = text .. " <LINE> <RGB:0.95,0.62,0.62> " .. tostring(option.disabledReason or "Unavailable.") .. " <LINE> "
    end

    return text
end

return DC_BuildingsUIUtils
