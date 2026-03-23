local Config = DT_Labour.Config
local Interaction = DT_Labour.Interaction
local Internal = DT_Labour.Sim.Internal

Internal.getScavengeToolSummary = function(worker)
    local names = {}
    local seen = {}
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        local name = tostring(entry and entry.displayName or entry and entry.fullType or "")
        if name ~= "" and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end

    if #names <= 0 then
        return "bare hands"
    end

    return Internal.formatNaturalList(names)
end

Internal.getScavengeLocationLabel = function(worker, run)
    local livePlace = Interaction and Interaction.GetPlaceLabel and Interaction.GetPlaceLabel(worker) or nil
    if livePlace and tostring(livePlace) ~= "" then
        return tostring(livePlace)
    end

    local siteProfile = run and run.siteProfile or nil
    local displayName = siteProfile and siteProfile.displayName or worker and worker.scavengeSiteProfileLabel or worker and worker.scavengeSiteRoomName or nil
    if displayName and tostring(displayName) ~= "" then
        return tostring(displayName)
    end
    return "the outskirts"
end

Internal.getOutcomeTokens = function(worker, count, placeLabel)
    local safeCount = math.max(0, tonumber(count) or 0)
    return {
        count = tostring(safeCount),
        item_word = safeCount == 1 and "item" or "items",
        place = tostring(placeLabel or Interaction.GetPlaceLabel(worker) or "Work Site")
    }
end

Internal.logJobCycleOutcome = function(worker, currentHour, count, placeLabel, entries)
    if not worker then
        return
    end

    local jobType = Config.NormalizeJobType(worker.jobType)
    local totalCount = math.max(0, tonumber(count) or 0)
    local outcomeKey = totalCount > 0 and "Recovered" or "Empty"
    local message = Interaction.BuildOutcomeMessage(worker, jobType, outcomeKey, Internal.getOutcomeTokens(worker, totalCount, placeLabel))
    local foundItems = Internal.buildFoundItemsClause(entries)

    if message and message ~= "" then
        if foundItems ~= "" and totalCount > 0 then
            message = message .. " Found: " .. foundItems .. "."
        end
        Internal.appendWorkerLog(worker, message, currentHour, "output")
    end
end
