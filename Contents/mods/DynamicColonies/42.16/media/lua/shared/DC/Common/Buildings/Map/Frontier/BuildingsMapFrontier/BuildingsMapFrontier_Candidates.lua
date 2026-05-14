DC_Buildings = DC_Buildings or {}

local Buildings = DC_Buildings
Buildings.Internal = Buildings.Internal or {}

local Frontier = Buildings.Internal.Frontier or {}
Buildings.Internal.Frontier = Frontier

function Buildings.GetUnlockedPlotEntries(ownerUsername)
    local owner = Frontier.GetOwnerUsername(ownerUsername)
    local mapData = Buildings.GetMapDataForOwner(owner)
    local plots = {}

    if Buildings.NormalizeFrontierUnlocks and Buildings.NormalizeFrontierUnlocks(owner) then
        Buildings.Save()
    end

    for _, plot in pairs(mapData and mapData.plots or {}) do
        if plot and plot.unlocked == true then
            plots[#plots + 1] = Buildings.BuildVirtualPlot(plot.x, plot.y, true, plot.kind)
        end
    end

    Frontier.SortPlotsByPosition(plots)
    return plots
end

function Buildings.GetHeadquartersLevel(ownerUsername)
    local owner = Frontier.GetOwnerUsername(ownerUsername)
    local ownerData = Buildings.Internal
        and Buildings.Internal.GetOwnerDataIfNormalizing
        and Buildings.Internal.GetOwnerDataIfNormalizing(owner)
        or Buildings.EnsureOwner and Buildings.EnsureOwner(owner)
        or nil
    local highestLevel = 0

    for _, instance in ipairs(ownerData and ownerData.buildings or {}) do
        if tostring(instance and instance.buildingType or "") == "Headquarters" then
            highestLevel = math.max(highestLevel, math.floor(tonumber(instance and instance.level) or 0))
        end
    end

    return highestLevel
end

function Buildings.GetMaxActiveBarricades(ownerUsername)
    local owner = Frontier.GetOwnerUsername(ownerUsername)
    local config = Frontier.Config or Buildings.Config
    local frontierConfig = config and config.Frontier or nil
    local currentRing = Frontier.GetActiveFrontierRing(owner)
    if currentRing <= 0 then
        return 0
    end
    local ringCap = frontierConfig and frontierConfig.GetRingBarricadeCapacity and frontierConfig.GetRingBarricadeCapacity(currentRing) or 0
    return ringCap
end

function Buildings.GetActiveBarricadeCount(ownerUsername)
    local owner = Frontier.GetOwnerUsername(ownerUsername)
    local currentRing = Frontier.GetActiveFrontierRing(owner)
    if currentRing <= 0 then
        return 0
    end
    local count = 0

    for _, instance in ipairs(Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Barricade"
            and Buildings.GetPlotRing
            and Buildings.GetPlotRing(instance.plotX, instance.plotY) == currentRing
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            count = count + 1
        end
    end

    for _, project in pairs(Buildings.GetProjectsForOwner(owner) or {}) do
        if tostring(project and project.status or "") == "Active"
            and Buildings.GetPlotRing
            and Buildings.GetPlotRing(project.plotX, project.plotY) == currentRing
            and tostring(project and project.buildingType or "") == "Barricade" then
            count = count + 1
        end
    end

    return count
end

function Buildings.GetCompletedBarricadeCount(ownerUsername)
    local owner = Frontier.GetOwnerUsername(ownerUsername)
    local count = 0

    for _, instance in ipairs(Buildings.GetBuildingsForOwner(owner) or {}) do
        if tostring(instance and instance.buildingType or "") == "Barricade"
            and math.floor(tonumber(instance and instance.level) or 0) > 0 then
            count = count + 1
        end
    end

    return count
end

function Buildings.IsFrontierPlot(ownerUsername, plotX, plotY)
    local owner = Frontier.GetOwnerUsername(ownerUsername)
    local x = math.floor(tonumber(plotX) or 0)
    local y = math.floor(tonumber(plotY) or 0)
    local targetRing = Frontier.GetActiveFrontierRing(owner)
    if targetRing <= 0 then
        return false
    end
    local plot, state, building, project = Buildings.GetPlotWithState(owner, x, y)

    if not plot or tostring(plot.kind or "") ~= tostring(Buildings.MapConstants.PlotKinds.Standard) then
        return false
    end
    if Buildings.GetPlotRing and Buildings.GetPlotRing(x, y) ~= targetRing then
        return false
    end
    if tostring(state or "") ~= tostring(Buildings.MapConstants.PlotStates.Locked)
        and tostring(state or "") ~= tostring(Buildings.MapConstants.PlotStates.Empty) then
        return false
    end
    if building or project then
        return false
    end

    return Frontier.HasUnlockedSupportingNeighbor(owner, x, y)
end

function Buildings.GetFrontierCandidatePlots(ownerUsername)
    local owner = Frontier.GetOwnerUsername(ownerUsername)
    local targetRing = Frontier.GetActiveFrontierRing(owner)
    if targetRing <= 0 then
        return {}
    end
    local candidates = {}
    local seen = {}

    for _, plot in ipairs(Buildings.GetUnlockedPlotEntries(owner)) do
        for _, direction in ipairs(Frontier.GetCardinalDirections()) do
            local nextX = math.floor(tonumber(plot.x) or 0) + direction.x
            local nextY = math.floor(tonumber(plot.y) or 0) + direction.y
            local key = Buildings.GetPlotKey(nextX, nextY)
            if not seen[key]
                and Buildings.GetPlotRing
                and Buildings.GetPlotRing(nextX, nextY) == targetRing
                and Buildings.IsFrontierPlot(owner, nextX, nextY) then
                seen[key] = true
                local candidate = Buildings.BuildVisiblePlot(owner, nextX, nextY)
                candidate.frontierCandidate = true
                candidates[#candidates + 1] = candidate
            end
        end
    end

    Frontier.SortPlotsByPosition(candidates)
    return candidates
end

return Buildings
