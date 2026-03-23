local Config = DT_Labour.Config
local Interaction = DT_Labour.Interaction
local Warehouse = DT_Labour.Warehouse
local Nutrition = DT_Labour.Nutrition
local Registry = DT_Labour.Registry
local Internal = DT_Labour.Sim.Internal

Internal.getScavengePresenceState = function(worker)
    local presenceState = worker and worker.presenceState or nil
    local states = Config.PresenceStates or {}
    if presenceState == states.AwayToSite
        or presenceState == states.Scavenging
        or presenceState == states.AwayToHome then
        return presenceState
    end
    return states.Home
end

Internal.getScavengeTravelHours = function()
    return math.max(
        0,
        tonumber(Config.GetScavengeTravelHours and Config.GetScavengeTravelHours())
            or tonumber(Config.DEFAULT_SCAVENGE_TRAVEL_HOURS)
            or 0
    )
end

Internal.ensureWorkerHome = function(worker)
    if not worker then
        return
    end

    if worker.homeX == nil or worker.homeY == nil then
        if worker.workX ~= nil and worker.workY ~= nil then
            worker.homeX = math.floor(tonumber(worker.workX) or 0)
            worker.homeY = math.floor(tonumber(worker.workY) or 0)
            worker.homeZ = math.floor(tonumber(worker.workZ) or 0)
        end
    end
end

Internal.getAvailableProvisionTotals = function(worker)
    local activeCalories, activeHydration = Nutrition.GetOnBodyTotals(worker)
    return math.max(0, tonumber(activeCalories) or 0) + math.max(0, tonumber(worker and worker.storedCalories) or 0),
        math.max(0, tonumber(activeHydration) or 0) + math.max(0, tonumber(worker and worker.storedHydration) or 0)
end

Internal.getRequiredTravelReserve = function(worker, profile, multiplier)
    local factor = math.max(0, tonumber(multiplier) or 1)
    local travelHours = Internal.getScavengeTravelHours()
    return math.max(0, tonumber(Config.GetEffectiveHourlyCaloriesNeed(worker, profile)) or 0) * travelHours * factor,
        math.max(0, tonumber(Config.GetEffectiveHourlyHydrationNeed(worker, profile)) or 0) * travelHours * factor
end

Internal.getReturnHomeMessage = function(reason)
    return Interaction.BuildReturnReasonMessage(reason)
end

Internal.getDeathFlavorText = function(worker, normalizedJobType, presenceState, hasCalories, hasHydration)
    local isScavenge = normalizedJobType == Config.JobTypes.Scavenge
    local away = presenceState == Config.PresenceStates.AwayToSite
        or presenceState == Config.PresenceStates.Scavenging
        or presenceState == Config.PresenceStates.AwayToHome

    if not hasCalories and not hasHydration then
        if isScavenge and away then
            return "Never made it back from the run. Hunger and thirst finally took them."
        end
        return "Succumbed to starvation and dehydration."
    end

    if not hasHydration then
        if isScavenge and away then
            return "Collapsed on the road, dried out and delirious."
        end
        return "Collapsed from severe dehydration."
    end

    if not hasCalories then
        if isScavenge and away then
            return "Ran themselves hollow on the job and never made it home."
        end
        return "Succumbed to starvation."
    end

    if isScavenge and away then
        return "Never made it back from the run. Their injuries finally caught up."
    end

    return "Succumbed to their injuries."
end

Internal.markWorkerDead = function(worker, currentHour, normalizedJobType, presenceState, hasCalories, hasHydration)
    if not worker then
        return
    end

    local deathCause = tostring(worker.deathCause or "")
    if deathCause == "" then
        deathCause = Internal.getDeathFlavorText(worker, normalizedJobType, presenceState, hasCalories, hasHydration)
        worker.deathCause = deathCause
        Internal.appendWorkerLog(worker, deathCause, currentHour, "death")
    end

    worker.state = Config.States.Dead
    worker.jobEnabled = false
    worker.presenceState = Config.PresenceStates.Home
    worker.travelHoursRemaining = 0
    worker.returnReason = nil
end

Internal.startScavengeOutbound = function(worker, currentHour)
    if not worker then
        return
    end

    worker.presenceState = Config.PresenceStates.AwayToSite
    worker.travelHoursRemaining = Internal.getScavengeTravelHours()
    worker.returnReason = nil
    Internal.appendWorkerLog(
        worker,
        Interaction.BuildOutcomeMessage(worker, Config.JobTypes.Scavenge, "TravelStarted", {
            place = Interaction.GetPlaceLabel(worker)
        }) or ("Set out for " .. Internal.getScavengeLocationLabel(worker) .. "."),
        currentHour,
        "travel"
    )
end

Internal.beginScavengeReturnHome = function(worker, currentHour, reason, travelHours)
    if not worker then
        return false
    end

    local presenceState = Internal.getScavengePresenceState(worker)
    if presenceState == Config.PresenceStates.Home or presenceState == Config.PresenceStates.AwayToHome then
        return false
    end

    if reason == Config.ReturnReasons.Manual then
        worker.jobEnabled = false
    end
    worker.presenceState = Config.PresenceStates.AwayToHome
    worker.travelHoursRemaining = math.max(0, tonumber(travelHours) or Internal.getScavengeTravelHours())
    worker.returnReason = reason or Config.ReturnReasons.Manual
    Internal.appendWorkerLog(worker, Internal.getReturnHomeMessage(worker.returnReason), currentHour, "travel")
    return true
end

Internal.completeScavengeReturnHome = function(worker, currentHour)
    if not worker then
        return
    end

    worker.presenceState = Config.PresenceStates.Home
    worker.travelHoursRemaining = 0
    worker.dumpCooldownHours = 0

    if not Internal.isAutoRepeatEnabled(worker) then
        worker.jobEnabled = false
    end

    local movedStacks, movedCount, movedRawWeight, leftoverCount = Warehouse.DepositWorkerHaul(worker)
    if movedStacks > 0 then
        worker.dumpTrips = math.max(0, tonumber(worker.dumpTrips) or 0) + 1
        Internal.appendWorkerLog(
            worker,
            Interaction.BuildOutcomeMessage(worker, Config.JobTypes.Scavenge, "ReturnedHomeWithItems", {
                count = tostring(movedCount),
                item_word = movedCount == 1 and "item" or "items",
                place = Interaction.GetPlaceLabel(worker)
            }) or ("Returned home and stowed " .. tostring(movedCount) .. " items."),
            currentHour,
            "haul"
        )
        if leftoverCount <= 0 then
            return
        end
        Internal.appendWorkerLog(
            worker,
            "Warehouse is full. " .. tostring(leftoverCount) .. " carried item" .. (leftoverCount == 1 and "" or "s") .. " could not be unloaded.",
            currentHour,
            "warehouse"
        )
        return
    end

    if leftoverCount > 0 then
        Internal.appendWorkerLog(
            worker,
            "Warehouse is full. " .. tostring(leftoverCount) .. " carried item" .. (leftoverCount == 1 and "" or "s") .. " could not be unloaded.",
            currentHour,
            "warehouse"
        )
        return
    end

    Internal.appendWorkerLog(
        worker,
        Interaction.BuildOutcomeMessage(worker, Config.JobTypes.Scavenge, "ReturnedHome", {
            place = Interaction.GetPlaceLabel(worker)
        }) or "Returned home.",
        currentHour,
        "travel"
    )
end

Internal.progressScavengeTravel = function(worker, currentHour, deltaHours)
    if not worker or deltaHours <= 0 then
        return
    end

    local presenceState = Internal.getScavengePresenceState(worker)
    if presenceState ~= Config.PresenceStates.AwayToSite and presenceState ~= Config.PresenceStates.AwayToHome then
        return
    end

    worker.travelHoursRemaining = math.max(0, Internal.clampHours(worker.travelHoursRemaining) - deltaHours)
    if worker.travelHoursRemaining > 0 then
        return
    end

    if presenceState == Config.PresenceStates.AwayToSite then
        worker.presenceState = Config.PresenceStates.Scavenging
        Internal.appendWorkerLog(
            worker,
            Interaction.BuildOutcomeMessage(worker, Config.JobTypes.Scavenge, "ArrivedAtSite", {
                place = Interaction.GetPlaceLabel(worker)
            }) or ("Arrived at " .. Internal.getScavengeLocationLabel(worker) .. "."),
            currentHour,
            "travel"
        )
        return
    end

    Internal.completeScavengeReturnHome(worker, currentHour)
end

Internal.shouldReturnForFullHaul = function(worker, loadout)
    if not worker then
        return false
    end

    local haulMetrics = Registry.GetHaulMetrics and Registry.GetHaulMetrics(worker) or nil
    local effectiveCarryLimit = tonumber(loadout and loadout.effectiveCarryLimit)
        or tonumber((haulMetrics and haulMetrics.effectiveCarryLimit))
        or tonumber(worker.effectiveCarryLimit)
        or (Config.GetWorkerBaseCarryWeight and Config.GetWorkerBaseCarryWeight(worker))
        or (Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight())
        or tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT)
        or 8
    return haulMetrics ~= nil and (tonumber(haulMetrics.effectiveWeight) or 0) >= effectiveCarryLimit
end
