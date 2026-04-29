DC_Colony = DC_Colony or {}
DC_Colony.Interaction = DC_Colony.Interaction or {}

local Config = DC_Colony.Config
local Interaction = DC_Colony.Interaction

Interaction.getInteractionEntry = function(partID, keyPath)
    return DynamicTrading.ResolveInteractionString("DynamicColonies", partID, keyPath)
end

local function getBuilderProjectLabel(worker)
    local buildingType = tostring(worker and worker.assignedProjectBuildingType or "")
    if buildingType == "" then
        return "Project"
    end

    local displayName = buildingType
    local definition = DC_Buildings and DC_Buildings.Config and DC_Buildings.Config.GetDefinition
        and DC_Buildings.Config.GetDefinition(buildingType)
        or nil
    if definition and tostring(definition.displayName or "") ~= "" then
        displayName = tostring(definition.displayName)
    elseif Interaction.prettifyContextLabel then
        displayName = tostring(Interaction.prettifyContextLabel(buildingType) or buildingType)
    end

    local targetLevel = math.max(0, math.floor(tonumber(worker and worker.assignedProjectTargetLevel) or 0))
    if targetLevel > 0 then
        return displayName .. " L" .. tostring(targetLevel)
    end

    return displayName
end

Interaction.getJobKey = function(worker)
    return tostring(Config.NormalizeJobType and Config.NormalizeJobType(worker and worker.jobType) or worker and worker.jobType or "")
end

Interaction.getTravelTotalHours = function()
    return math.max(
        0.01,
        tonumber(Config.GetScavengeTravelHours and Config.GetScavengeTravelHours())
            or tonumber(Config.DEFAULT_SCAVENGE_TRAVEL_HOURS)
            or 2
    )
end

Interaction.buildProgressTokens = function(worker, progressHours, cycleHours, remainingWorldHours)
    local place = Interaction.GetPlaceLabel(worker)
    return {
        place = place,
        count = tostring(math.max(0, tonumber(worker and worker.outputCount) or 0)),
        eta = Interaction.formatDurationHours(remainingWorldHours),
        progress = Interaction.formatDecimal(progressHours or 0, 1),
        total = Interaction.formatDecimal(cycleHours or 0, 1),
        project = getBuilderProjectLabel(worker),
        building = tostring(worker and worker.assignedProjectBuildingType or ""),
        level = tostring(math.max(0, math.floor(tonumber(worker and worker.assignedProjectTargetLevel) or 0))),
        current_level = tostring(math.max(0, math.floor(tonumber(worker and worker.housingBuildingLevel) or 0)))
    }
end

return DC_Colony.Interaction
