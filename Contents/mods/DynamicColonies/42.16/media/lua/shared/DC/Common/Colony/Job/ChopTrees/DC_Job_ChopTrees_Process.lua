local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Warehouse = DC_Colony.Warehouse
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy
local Interaction = DC_Colony.Interaction
local Woodcut = DC_Colony.Woodcut

local LOG_LABEL = "woodcut goods"

local function getPresenceState(worker)
    local states = Config.PresenceStates or {}
    local presenceState = worker and worker.presenceState or nil
    if presenceState == states.AwayToSite
        or presenceState == states.Gathering
        or presenceState == states.AwayToHome then
        return presenceState
    end
    return states.Home
end

local function getWorkZone(worker)
    if not worker or not DC_ZoneRealBase or not DC_ZoneRealBase.ResolveChopTreesTarget then
        return nil
    end
    if DC_ZoneRealBase.GetZonesForOwner and DC_ZoneRealBase.FindJobTypeZone then
        local zones = DC_ZoneRealBase.GetZonesForOwner(worker.ownerUsername) or {}
        return DC_ZoneRealBase.FindJobTypeZone(zones, "ChopTrees")
    end
    return nil
end

local function hasWorkZone(worker)
    return getWorkZone(worker) ~= nil
end

local function getTravelTarget(worker)
    if not worker or not DC_ZoneRealBase or not DC_ZoneRealBase.ResolveChopTreesTarget then
        return nil
    end
    return DC_ZoneRealBase.ResolveChopTreesTarget(worker)
end

local function getTravelHours(worker)
    local travelTarget = getTravelTarget(worker)
    if Internal.getWorkerTravelHours and travelTarget then
        return Internal.getWorkerTravelHours(worker, travelTarget, {
            baseHours = Internal.getScavengeTravelHours and Internal.getScavengeTravelHours() or nil,
            baselineDistanceTiles = 450,
            minHours = 0.10,
            maxHours = 8,
            roundToMinutes = true,
        })
    end
    if Internal.getScavengeTravelHours then
        return Internal.getScavengeTravelHours()
    end
    return math.max(0, tonumber(Config.DEFAULT_SCAVENGE_TRAVEL_HOURS) or 0)
end

local function refreshWoodcutZone(worker, force)
    local zone = getWorkZone(worker)
    if not zone or not Woodcut or not Woodcut.RefreshLoadedScan then
        return zone, nil
    end
    local state = Woodcut.RefreshLoadedScan(worker.ownerUsername, zone, {
        force = force == true,
    })
    return zone, state
end

local function zoneHasAvailableTrees(worker)
    local zone, zoneState = refreshWoodcutZone(worker, false)
    if not zone then
        return false, nil, nil
    end
    if not zoneState then
        return true, zone, nil
    end
    if math.max(0, tonumber(zoneState.remainingKnownTreeCount) or 0) > 0 then
        return true, zone, zoneState
    end
    if math.max(0, tonumber(zoneState.unresolvedTileCount) or 0) > 0 then
        return true, zone, zoneState
    end
    if math.max(0, tonumber(zoneState.lastScanAt) or 0) <= 0 then
        return true, zone, zoneState
    end
    return false, zone, zoneState
end

local function getPlaceLabel(worker)
    local label = Interaction and Interaction.GetPlaceLabel and Interaction.GetPlaceLabel(worker) or nil
    if label and tostring(label) ~= "" then
        return tostring(label)
    end
    return "woodcut zone"
end

local function startOutbound(worker, currentHour)
    worker.presenceState = Config.PresenceStates.AwayToSite
    worker.travelHoursRemaining = getTravelHours(worker)
    worker.returnReason = nil
    Internal.appendWorkerLog(worker, "Set out for the " .. getPlaceLabel(worker) .. ".", currentHour, "travel")
end

local function beginReturnHome(worker, currentHour, reason, travelHours)
    local presenceState = getPresenceState(worker)
    if presenceState == Config.PresenceStates.Home or presenceState == Config.PresenceStates.AwayToHome then
        return false
    end

    if reason == Config.ReturnReasons.Manual then
        worker.jobEnabled = false
    end

    worker.presenceState = Config.PresenceStates.AwayToHome
    worker.travelHoursRemaining = math.max(0, tonumber(travelHours) or getTravelHours(worker))
    worker.returnReason = reason or Config.ReturnReasons.Manual
    if Internal.getReturnHomeMessage then
        Internal.appendWorkerLog(worker, Internal.getReturnHomeMessage(worker.returnReason), currentHour, "travel")
    else
        Internal.appendWorkerLog(worker, "Heading home.", currentHour, "travel")
    end
    return true
end

local function completeReturnHome(worker, currentHour)
    worker.presenceState = Config.PresenceStates.Home
    worker.travelHoursRemaining = 0
    worker.returnReason = nil

    local movedStacks, movedCount, _movedWeight, leftoverCount = Warehouse.DepositWorkerOutput(worker)
    if movedStacks > 0 then
        Internal.appendWorkerLog(
            worker,
            "Returned home and unloaded " .. tostring(movedCount) .. " " .. LOG_LABEL .. " into the warehouse.",
            currentHour,
            "haul"
        )
    elseif leftoverCount <= 0 then
        Internal.appendWorkerLog(worker, "Returned home.", currentHour, "travel")
    end

    if leftoverCount > 0 then
        Internal.appendWorkerLog(
            worker,
            "Warehouse is full. " .. tostring(leftoverCount) .. " carried " .. LOG_LABEL .. " could not be unloaded.",
            currentHour,
            "warehouse"
        )
    end
end

local function progressTravel(worker, currentHour, deltaHours)
    if not worker or deltaHours <= 0 then
        return
    end

    local presenceState = getPresenceState(worker)
    if presenceState ~= Config.PresenceStates.AwayToSite and presenceState ~= Config.PresenceStates.AwayToHome then
        return
    end

    worker.travelHoursRemaining = math.max(0, Internal.clampHours(worker.travelHoursRemaining) - deltaHours)
    if worker.travelHoursRemaining > 0 then
        return
    end

    if presenceState == Config.PresenceStates.AwayToSite then
        worker.presenceState = Config.PresenceStates.Gathering
        Internal.appendWorkerLog(worker, "Reached the " .. getPlaceLabel(worker) .. ".", currentHour, "travel")
        return
    end

    completeReturnHome(worker, currentHour)
end

local function syncWorkerOutputs(worker)
    if not worker or not Registry then
        return
    end
    if Registry.RecalculateWorker then
        Registry.RecalculateWorker(worker)
    end
    if Registry.Save then
        Registry.Save()
    end
end

local function formatBundleSummary(bundle)
    local parts = {}
    for _, entry in ipairs(bundle or {}) do
        if type(entry) == "table" and entry.fullType then
            local displayName = tostring(entry.displayName or entry.fullType)
            parts[#parts + 1] = tostring(entry.qty or 1) .. " " .. displayName
        end
    end
    return #parts > 0 and table.concat(parts, ", ") or "wood"
end

local function addBundleToWorker(worker, bundle)
    local storedTotal = 0
    local storedAny = false
    local blocked = false
    local registry = Registry
    if not registry or not registry.AddOutputEntry then
        return 0, false, true
    end

    for _, entry in ipairs(bundle or {}) do
        local requestedQty = math.max(1, math.floor(tonumber(entry and entry.qty) or 1))
        local storedQty = registry.AddOutputEntry(worker, {
            fullType = tostring(entry.fullType),
            displayName = entry.displayName and tostring(entry.displayName) or nil,
            qty = requestedQty,
        })
        if storedQty > 0 then
            storedAny = true
            storedTotal = storedTotal + storedQty
        end
        if storedQty < requestedQty then
            blocked = true
        end
    end

    return storedTotal, storedAny, blocked
end

local function hasLogCapacity(worker)
    if not Registry or not Registry.GetFittingInventoryQuantity then
        return true
    end
    return math.max(0, tonumber(Registry.GetFittingInventoryQuantity(worker, "Base.Log", 1)) or 0) > 0
end

local function isLiveWoodcutActive(worker)
    if not worker or tostring(worker.residentSoulUUID or "") == "" then
        return false
    end
    if not DTNPCServerCore or not DTNPCServerCore.GetNPCDataByUUID then
        return false
    end

    local zombie, npcData = DTNPCServerCore.GetNPCDataByUUID(tostring(worker.residentSoulUUID))
    if not zombie or not npcData then
        return false
    end

    local desiredState = DTNPCColonyRuntime and DTNPCColonyRuntime.GetBehaviorState and DTNPCColonyRuntime.GetBehaviorState(npcData) or nil
    local liveState = tostring(npcData.state or npcData.dcBehaviorState or "")
    if desiredState ~= "ColonyChopTrees" and liveState ~= "ColonyChopTrees" then
        return false
    end

    local homeX = tonumber(worker.homeX)
    local homeY = tonumber(worker.homeY)
    local homeZ = tonumber(worker.homeZ) or 0
    if homeX ~= nil and homeY ~= nil then
        local dx = (tonumber(zombie:getX()) or homeX) - homeX
        local dy = (tonumber(zombie:getY()) or homeY) - homeY
        local dz = math.abs((tonumber(zombie:getZ()) or homeZ) - homeZ)
        if dz <= 1 and (dx * dx) + (dy * dy) <= 64 then
            return false
        end
    end

    return true
end

local function buildTravelProgressDescriptor(worker)
    local travelTemplate = worker.presenceState == Config.PresenceStates.AwayToSite
        and Interaction.getInteractionEntry and Interaction.getInteractionEntry("Progress", "Common.TravelToSite")
        or Interaction.getInteractionEntry and Interaction.getInteractionEntry("Progress", "Common.TravelToHome")
    if type(travelTemplate) ~= "table" then
        return nil
    end

    local totalHours = Interaction.getTravelTotalHours and Interaction.getTravelTotalHours() or getTravelHours(worker)
    totalHours = math.max(0.01, tonumber(totalHours) or getTravelHours(worker))
    local remainingWorldHours = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
    local progressHours = math.max(0, totalHours - remainingWorldHours)
    local tokens = Interaction.buildProgressTokens and Interaction.buildProgressTokens(worker, progressHours, totalHours, remainingWorldHours) or {
        eta = Interaction.formatDurationHours and Interaction.formatDurationHours(remainingWorldHours) or tostring(remainingWorldHours),
        place = getPlaceLabel(worker),
    }

    return {
        label = DynamicTrading.FormatInteractionString(travelTemplate.activeText, tokens),
        displayText = DynamicTrading.FormatInteractionString(travelTemplate.activeText, tokens),
        fillRatio = math.max(0, math.min(1, progressHours / totalHours)),
        captionText = DynamicTrading.FormatInteractionString(travelTemplate.captionText, tokens),
        summaryText = (Interaction.formatDecimal and Interaction.formatDecimal(progressHours, 1) or tostring(progressHours))
            .. " / "
            .. (Interaction.formatDecimal and Interaction.formatDecimal(totalHours, 1) or tostring(totalHours))
            .. "h",
        progressHours = progressHours,
        cycleHours = totalHours,
        remainingWorldHours = remainingWorldHours,
        color = travelTemplate.color,
    }
end

local function buildActiveProgressDescriptor(worker, profile)
    local template = Interaction.getInteractionEntry and Interaction.getInteractionEntry("Progress", "ChopTrees.Active") or nil
    local gameTime = getGameTime and getGameTime() or nil
    local workTarget = math.max(
        0.01,
        tonumber(worker.workTarget)
            or tonumber(worker.chopTreesLiveCycleHours)
            or tonumber(profile and profile.cycleHours)
            or 1
    )
    local baseSpeed = math.max(
        0.01,
        tonumber(worker.baseWorkSpeedMultiplier)
            or tonumber(Config.GetBaseWorkSpeedMultiplier and Config.GetBaseWorkSpeedMultiplier(worker, profile))
            or 1
    )
    local skillSpeed = math.max(
        0.01,
        tonumber(worker.jobSkillSpeedMultiplier)
            or 1
    )
    local effectiveSpeed = baseSpeed * skillSpeed
    local progressAmount = math.max(0, tonumber(worker.workProgress) or 0)
    if tostring(worker.chopTreesMode or "") == "live"
        and tostring(worker.chopTreesClaimKey or "") ~= ""
        and gameTime
        and tonumber(worker.chopTreesLiveStartedAtHour) then
        local elapsedWorldHours = math.max(
            0,
            (tonumber(gameTime.getWorldAgeHours and gameTime:getWorldAgeHours()) or 0)
                - (tonumber(worker.chopTreesLiveStartedAtHour) or 0)
        )
        progressAmount = math.min(workTarget, elapsedWorldHours * effectiveSpeed)
    end
    if progressAmount > workTarget then
        progressAmount = progressAmount % workTarget
    end

    local remainingWorkAmount = math.max(0, workTarget - progressAmount)
    local remainingWorldHours = effectiveSpeed > 0 and (remainingWorkAmount / effectiveSpeed) or nil
    local tokens = {
        place = getPlaceLabel(worker),
        eta = Interaction.formatDurationHours and Interaction.formatDurationHours(remainingWorldHours) or tostring(remainingWorldHours or 0),
        progress = Interaction.formatDecimal and Interaction.formatDecimal(progressAmount, 1) or tostring(progressAmount),
        total = Interaction.formatDecimal and Interaction.formatDecimal(workTarget, 1) or tostring(workTarget),
        tree = "tree",
    }

    return {
        label = type(template) == "table"
            and DynamicTrading.FormatInteractionString(template.activeText, tokens)
            or ("Cutting a tree at " .. getPlaceLabel(worker)),
        displayText = type(template) == "table"
            and DynamicTrading.FormatInteractionString(template.activeText, tokens)
            or ("Cutting a tree at " .. getPlaceLabel(worker)),
        fillRatio = math.max(0, math.min(1, progressAmount / workTarget)),
        captionText = type(template) == "table"
            and DynamicTrading.FormatInteractionString(template.captionText, tokens)
            or ("Ready in " .. tostring(tokens.eta)),
        summaryText = (Interaction.formatDecimal and Interaction.formatDecimal(progressAmount, 1) or tostring(progressAmount))
            .. " / "
            .. (Interaction.formatDecimal and Interaction.formatDecimal(workTarget, 1) or tostring(workTarget))
            .. "h | Speed x"
            .. (Interaction.formatDecimal and Interaction.formatDecimal(effectiveSpeed, 2) or tostring(effectiveSpeed)),
        progressHours = progressAmount,
        workTarget = workTarget,
        cycleHours = workTarget,
        remainingWorldHours = remainingWorldHours,
        effectiveSpeedMultiplier = effectiveSpeed,
        color = type(template) == "table" and template.color or { r = 0.46, g = 0.72, b = 0.28, a = 1 },
    }
end

local function finalizeState(worker, ctx, didWorkThisTick)
    local currentHour = ctx.currentHour
    local normalizedJobType = ctx.normalizedJobType
    local profile = ctx.profile
    local hp = ctx.hp
    local hasCalories = ctx.hasCalories
    local hasHydration = ctx.hasHydration
    local deltaHours = ctx.deltaHours
    local lowEnergyReason = ctx.lowEnergyReason
    local workableHours = ctx.workableHours

    local presenceState = getPresenceState(worker)

    if Energy and deltaHours > 0 and hp > 0 then
        if didWorkThisTick and workableHours > 0 then
            Energy.ApplyWorkDrain(worker, workableHours, profile)
        elseif presenceState == Config.PresenceStates.Home then
            Energy.ApplyHomeRecovery(worker, deltaHours, profile)
        else
            Energy.ApplyTravelDrain(worker, deltaHours, profile)
        end

        local forcedRest = Energy.IsForcedRest(worker)
        if forcedRest then
            Energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
        elseif Energy.IsDepleted(worker) then
            Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, presenceState == Config.PresenceStates.Home and "Too tired to keep chopping. Resting at home." or nil)
            if presenceState ~= Config.PresenceStates.Home and presenceState ~= Config.PresenceStates.AwayToHome then
                beginReturnHome(worker, currentHour, lowEnergyReason)
                presenceState = getPresenceState(worker)
            end
        end
    end

    local forcedRest = Energy and Energy.IsForcedRest and Energy.IsForcedRest(worker) or false
    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, presenceState, hasCalories, hasHydration)
    elseif not hasHydration then
        worker.state = Config.States.Dehydrated
    elseif not hasCalories then
        worker.state = Config.States.Starving
    elseif forcedRest and presenceState == Config.PresenceStates.Home then
        worker.state = Config.States.Resting
    elseif presenceState == Config.PresenceStates.Gathering and worker.jobEnabled then
        worker.state = Config.States.Working
    elseif presenceState == Config.PresenceStates.Home
        and worker.jobEnabled
        and (worker.chopTreesZoneReady ~= true or worker.chopTreesTreesAvailable ~= true) then
        worker.state = Config.States.MissingSite
    elseif presenceState == Config.PresenceStates.Home and worker.jobEnabled and not ctx.toolsReady then
        worker.state = Config.States.MissingTool
    elseif presenceState == Config.PresenceStates.Home and worker.jobEnabled and #(worker.outputLedger or {}) > 0 then
        worker.state = Config.States.StorageFull
    else
        worker.state = Config.States.Idle
    end
end

function Sim.ProcessChopTreesJob(worker, ctx)
    local currentHour = ctx.currentHour
    local profile = ctx.profile
    local normalizedJobType = ctx.normalizedJobType
    local speedMultiplier = ctx.speedMultiplier
    local cycleHours = ctx.cycleHours
    local toolsReady = ctx.toolsReady
    local hp = ctx.hp
    local hasCalories = ctx.hasCalories
    local hasHydration = ctx.hasHydration
    local forcedRest = ctx.forcedRest
    local workableHours = ctx.workableHours
    local deltaHours = ctx.deltaHours
    local lowEnergyReason = ctx.lowEnergyReason
    local jobSkillEffects = ctx.jobSkillEffects
    local didWorkThisTick = false

    if Internal.ensureWorkerHome then
        Internal.ensureWorkerHome(worker)
    end

    local treeSupplyReady, workZone, zoneState = zoneHasAvailableTrees(worker)
    local workZoneReady = workZone ~= nil
    worker.chopTreesZoneReady = workZoneReady == true
    worker.chopTreesTreesAvailable = treeSupplyReady == true
    worker.chopTreesCoverageText = zoneState and Woodcut and Woodcut.GetCoverageText and Woodcut.GetCoverageText(zoneState) or "Trees ?"
    if not workZoneReady then
        worker.siteState = "Set Chop Trees Zone"
    elseif treeSupplyReady then
        worker.siteState = worker.chopTreesCoverageText or "Woodcut Zone Ready"
    else
        worker.siteState = "Woodcut Zone Cleared"
    end

    local presenceState = getPresenceState(worker)
    local totalCaloriesAvailable = 0
    local totalHydrationAvailable = 0
    local returnCaloriesThreshold = 0
    local returnHydrationThreshold = 0
    local outboundCaloriesThreshold = 0
    local outboundHydrationThreshold = 0

    if Internal.getAvailableProvisionTotals then
        totalCaloriesAvailable, totalHydrationAvailable = Internal.getAvailableProvisionTotals(worker)
    end
    local travelHours = getTravelHours(worker)
    if Internal.getRequiredTravelReserveForHours then
        returnCaloriesThreshold, returnHydrationThreshold =
            Internal.getRequiredTravelReserveForHours(worker, profile, travelHours, 1)
        outboundCaloriesThreshold, outboundHydrationThreshold =
            Internal.getRequiredTravelReserveForHours(worker, profile, travelHours, 2)
    elseif Internal.getRequiredTravelReserve then
        returnCaloriesThreshold, returnHydrationThreshold = Internal.getRequiredTravelReserve(worker, profile, 1)
        outboundCaloriesThreshold, outboundHydrationThreshold = Internal.getRequiredTravelReserve(worker, profile, 2)
    end

    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, presenceState, hasCalories, hasHydration)
        return
    end

    if (not workZoneReady or not treeSupplyReady) and presenceState ~= Config.PresenceStates.Home then
        beginReturnHome(worker, currentHour, Config.ReturnReasons.MissingSite, worker.travelHoursRemaining)
        presenceState = getPresenceState(worker)
    elseif not toolsReady and presenceState ~= Config.PresenceStates.Home then
        beginReturnHome(worker, currentHour, Config.ReturnReasons.MissingTool, worker.travelHoursRemaining)
        presenceState = getPresenceState(worker)
    end

    if presenceState ~= Config.PresenceStates.Home and presenceState ~= Config.PresenceStates.AwayToHome then
        if totalHydrationAvailable < returnHydrationThreshold then
            beginReturnHome(worker, currentHour, Config.ReturnReasons.LowDrink)
            presenceState = getPresenceState(worker)
        elseif totalCaloriesAvailable < returnCaloriesThreshold then
            beginReturnHome(worker, currentHour, Config.ReturnReasons.LowFood)
            presenceState = getPresenceState(worker)
        elseif forcedRest then
            beginReturnHome(worker, currentHour, lowEnergyReason)
            presenceState = getPresenceState(worker)
        end
    end

    if not worker.jobEnabled and presenceState ~= Config.PresenceStates.Home and presenceState ~= Config.PresenceStates.AwayToHome then
        beginReturnHome(
            worker,
            currentHour,
            Config.ReturnReasons.Manual,
            presenceState == Config.PresenceStates.AwayToSite and worker.travelHoursRemaining or nil
        )
        presenceState = getPresenceState(worker)
    end

    if worker.jobEnabled
        and presenceState == Config.PresenceStates.Home
        and workZoneReady
        and treeSupplyReady
        and toolsReady
        and #(worker.outputLedger or {}) <= 0
        and hasCalories
        and hasHydration
        and not forcedRest
        and totalCaloriesAvailable >= outboundCaloriesThreshold
        and totalHydrationAvailable >= outboundHydrationThreshold then
        startOutbound(worker, currentHour)
        presenceState = getPresenceState(worker)
    end

    if presenceState == Config.PresenceStates.AwayToSite or presenceState == Config.PresenceStates.AwayToHome then
        progressTravel(worker, currentHour, deltaHours)
        presenceState = getPresenceState(worker)
    end

    if presenceState == Config.PresenceStates.Gathering and worker.jobEnabled and toolsReady and hasCalories and hasHydration and not forcedRest then
        worker.state = Config.States.Working

        local liveMode = isLiveWoodcutActive(worker)
        worker.chopTreesMode = liveMode and "live" or "abstract"

        if liveMode then
            local liveCycleHours = math.max(0.01, tonumber(worker.chopTreesLiveCycleHours) or tonumber(worker.workTarget) or cycleHours)
            worker.workTarget = liveCycleHours
            worker.workCycleHours = liveCycleHours
            if tostring(worker.chopTreesClaimKey or "") ~= "" then
                worker.workProgress = math.min(
                    liveCycleHours,
                    Internal.clampHours(worker.workProgress) + (workableHours * math.max(0.01, tonumber(speedMultiplier) or 1))
                )
                worker.chopTreesLiveReady = (worker.workProgress + 0.0001) >= liveCycleHours
                didWorkThisTick = workableHours > 0
            else
                worker.workProgress = 0
                worker.chopTreesLiveReady = false
            end
            if #(worker.outputLedger or {}) > 0 and hasLogCapacity(worker) ~= true then
                beginReturnHome(worker, currentHour, Config.ReturnReasons.FullHaul)
            end
        else
            worker.chopTreesLiveReady = false
            worker.chopTreesLiveCycleHours = nil
            worker.workProgress = Internal.clampHours(worker.workProgress) + (workableHours * math.max(0.01, tonumber(speedMultiplier) or 1))
            didWorkThisTick = workableHours > 0
            while worker.workProgress >= cycleHours do
                worker.workProgress = worker.workProgress - cycleHours
                Sim.ApplyWearForRequiredTools(worker, profile, currentHour, 1)

                local claim = Woodcut and Woodcut.ClaimNextTree and Woodcut.ClaimNextTree(worker, {
                    zone = workZone,
                    sourceMode = "abstract",
                }) or nil
                if not claim or type(claim.tree) ~= "table" then
                    worker.chopTreesTreesAvailable = false
                    worker.siteState = "Woodcut Zone Cleared"
                    beginReturnHome(worker, currentHour, Config.ReturnReasons.MissingSite)
                    break
                end

                local bundle = Woodcut.BuildAbstractBundle and Woodcut.BuildAbstractBundle(claim.zoneState, claim.tree, worker) or {}
                local storedQty, storedAny, blocked = addBundleToWorker(worker, bundle)
                if storedAny then
                    syncWorkerOutputs(worker)
                    Internal.appendWorkerLog(
                        worker,
                        "Finished cutting a tree and packed " .. formatBundleSummary(bundle) .. ".",
                        currentHour,
                        "output"
                    )
                    Sim.grantWorkerJobXP(worker, currentHour, jobSkillEffects, storedQty)
                end

                if Woodcut.MarkCollected then
                    Woodcut.MarkCollected(claim.zoneState, claim.treeKey, bundle, "abstract")
                end
                worker.chopTreesClaimKey = nil

                if blocked or hasLogCapacity(worker) ~= true then
                    beginReturnHome(worker, currentHour, Config.ReturnReasons.FullHaul)
                    break
                end
            end
        end
    end

    finalizeState(worker, ctx, didWorkThisTick)
end

if DC_Colony.Config.JobProfiles and DC_Colony.Config.JobProfiles.ChopTrees then
    DC_Colony.Config.JobProfiles.ChopTrees.processHandler = Sim.ProcessChopTreesJob
    DC_Colony.Config.JobProfiles.ChopTrees.hooks.getCycleHours = function(worker, cycleHours)
        if worker and tostring(worker.chopTreesMode or "") == "live" and tonumber(worker.chopTreesLiveCycleHours) then
            return math.max(0.01, tonumber(worker.chopTreesLiveCycleHours) or cycleHours)
        end
        return cycleHours
    end
    DC_Colony.Config.JobProfiles.ChopTrees.hooks.initPresence = function(worker, currentHour)
        if Internal.ensureWorkerHome then
            Internal.ensureWorkerHome(worker)
        end
        worker.presenceState = getPresenceState(worker)
        if worker.presenceState == DC_Colony.Config.PresenceStates.AwayToHome
            and (tonumber(worker.travelHoursRemaining) or 0) <= 0 then
            completeReturnHome(worker, currentHour)
            worker.presenceState = getPresenceState(worker)
        end
    end
    DC_Colony.Config.JobProfiles.ChopTrees.hooks.getCanWork = function(worker, defaultCanWork, forcedRestValue)
        return defaultCanWork and forcedRestValue ~= true and getPresenceState(worker) == DC_Colony.Config.PresenceStates.Gathering
    end
    DC_Colony.Config.JobProfiles.ChopTrees.hooks.getProgressDescriptor = function(worker, profile)
        local states = Config.PresenceStates or {}
        local presenceState = tostring(worker.presenceState or "")
        if presenceState == tostring(states.AwayToSite or "AwayToSite")
            or presenceState == tostring(states.AwayToHome or "AwayToHome") then
            return buildTravelProgressDescriptor(worker)
        end

        local workingState = tostring((Config.States or {}).Working or "Working")
        if tostring(worker.state or "") ~= workingState or worker.jobEnabled ~= true then
            return nil
        end

        if tostring(worker.chopTreesMode or "") == "live" and tostring(worker.chopTreesClaimKey or "") == "" then
            return nil
        end

        return buildActiveProgressDescriptor(worker, profile)
    end
end
