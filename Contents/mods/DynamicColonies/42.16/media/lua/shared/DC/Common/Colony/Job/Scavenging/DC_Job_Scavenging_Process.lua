local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Output = DC_Colony.Output
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy
local Skills = DC_Colony.Skills

function Sim.ProcessScavengeJob(worker, ctx)
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
    local scavengeLoadout = ctx.jobLoadout
    local jobSkillEffects = ctx.jobSkillEffects
    
    local totalCaloriesAvailable, totalHydrationAvailable = Internal.getAvailableProvisionTotals(worker)
    local returnCaloriesThreshold, returnHydrationThreshold = Internal.getRequiredTravelReserve(worker, profile, 1)
    local outboundCaloriesThreshold, outboundHydrationThreshold = Internal.getRequiredTravelReserve(worker, profile, 2)
    local presenceState = Internal.getScavengePresenceState(worker)
    local didScavengeWork = false

    local scavengeBaseWorkPerHour = Config.GetScavengeBaseWorkPerHour and Config.GetScavengeBaseWorkPerHour() or 1.0

    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, presenceState, hasCalories, hasHydration)
    else
        if not worker.assignedSiteID and presenceState ~= Config.PresenceStates.Home then
            Internal.beginScavengeReturnHome(worker, currentHour, Config.ReturnReasons.MissingSite, worker.travelHoursRemaining)
            presenceState = Internal.getScavengePresenceState(worker)
        elseif not toolsReady and presenceState ~= Config.PresenceStates.Home then
            Internal.beginScavengeReturnHome(worker, currentHour, Config.ReturnReasons.MissingTool, worker.travelHoursRemaining)
            presenceState = Internal.getScavengePresenceState(worker)
        end

        if presenceState ~= Config.PresenceStates.Home and presenceState ~= Config.PresenceStates.AwayToHome then
            if totalHydrationAvailable < returnHydrationThreshold then
                Internal.beginScavengeReturnHome(worker, currentHour, Config.ReturnReasons.LowDrink)
                presenceState = Internal.getScavengePresenceState(worker)
            elseif totalCaloriesAvailable < returnCaloriesThreshold then
                Internal.beginScavengeReturnHome(worker, currentHour, Config.ReturnReasons.LowFood)
                presenceState = Internal.getScavengePresenceState(worker)
            elseif Energy.IsForcedRest(worker) then
                Internal.beginScavengeReturnHome(worker, currentHour, lowEnergyReason)
                presenceState = Internal.getScavengePresenceState(worker)
            end
        end

        if not worker.jobEnabled and presenceState ~= Config.PresenceStates.Home and presenceState ~= Config.PresenceStates.AwayToHome then
            Internal.beginScavengeReturnHome(
                worker,
                currentHour,
                Config.ReturnReasons.Manual,
                presenceState == Config.PresenceStates.AwayToSite and worker.travelHoursRemaining or nil
            )
            presenceState = Internal.getScavengePresenceState(worker)
        end

        if worker.jobEnabled
            and presenceState == Config.PresenceStates.Home
            and worker.assignedSiteID
            and toolsReady
            and (tonumber(worker.haulCount) or 0) <= 0
            and Internal.hasWarehouseCapacityForScavenge(worker)
            and hasCalories
            and hasHydration
            and not forcedRest
            and totalCaloriesAvailable >= outboundCaloriesThreshold
            and totalHydrationAvailable >= outboundHydrationThreshold then
            Internal.startScavengeOutbound(worker, currentHour)
            presenceState = Internal.getScavengePresenceState(worker)
        end

        if presenceState == Config.PresenceStates.AwayToSite or presenceState == Config.PresenceStates.AwayToHome then
            Internal.progressScavengeTravel(worker, currentHour, deltaHours)
            presenceState = Internal.getScavengePresenceState(worker)
        end

        if presenceState == Config.PresenceStates.Scavenging and worker.jobEnabled and toolsReady and hasCalories and hasHydration and not forcedRest then
            local effectiveWorkPerHour = math.max(0.01, tonumber(scavengeBaseWorkPerHour) or 1) * math.max(0.01, tonumber(speedMultiplier) or 1)
            worker.state = Config.States.Working
            worker.workProgress = Internal.clampHours(worker.workProgress) + (workableHours * effectiveWorkPerHour)
            didScavengeWork = workableHours > 0
            while worker.workProgress >= cycleHours do
                worker.workProgress = worker.workProgress - cycleHours

                local scavengeRun = Output.GenerateScavengeRun and Output.GenerateScavengeRun(worker) or { entries = {} }
                Sim.ApplyWearForScavengeTools(worker, currentHour, 1)
                worker.scavengeBonusRareRolls = scavengeRun.bonusRareRolls or 0
                worker.scavengeRareFinds = scavengeRun.rareFinds or 0
                worker.scavengeBotchedRolls = scavengeRun.botchedRolls or 0
                worker.scavengeQualityCounts = scavengeRun.qualityCounts or nil
                for _, entry in ipairs(scavengeRun.entries or {}) do
                    Registry.AddHaulEntry(worker, entry)
                end
                Internal.logJobCycleOutcome(worker, currentHour, scavengeRun.totalQuantity, Internal.getScavengeLocationLabel(worker, scavengeRun), scavengeRun.entries)
                if scavengeRun.success then
                    Sim.grantWorkerJobXP(worker, currentHour, scavengeRun.skillEffects or jobSkillEffects, scavengeRun.totalQuantity)
                end

                if Internal.shouldReturnForFullHaul(worker, scavengeLoadout) then
                    Internal.beginScavengeReturnHome(worker, currentHour, Config.ReturnReasons.FullHaul)
                    break
                end
            end
        end

        presenceState = Internal.getScavengePresenceState(worker)
        worker.dumpCooldownHours = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
        if Energy and deltaHours > 0 then
            if didScavengeWork and workableHours > 0 then
                Energy.ApplyWorkDrain(worker, workableHours, profile)
            elseif presenceState == Config.PresenceStates.Home then
                Energy.ApplyHomeRecovery(worker, deltaHours, profile)
            elseif presenceState == Config.PresenceStates.AwayToSite or presenceState == Config.PresenceStates.AwayToHome then
                Energy.ApplyTravelDrain(worker, deltaHours, profile)
            end

            forcedRest = Energy.IsForcedRest(worker)
            if forcedRest then
                Energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
            elseif Energy.IsDepleted(worker) then
                forcedRest = true
                Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, presenceState == Config.PresenceStates.Home and "Too tired to keep working. Resting at home." or nil)
                if presenceState ~= Config.PresenceStates.Home and presenceState ~= Config.PresenceStates.AwayToHome then
                    Internal.beginScavengeReturnHome(worker, currentHour, lowEnergyReason)
                end
            end
            presenceState = Internal.getScavengePresenceState(worker)
            forcedRest = Energy.IsForcedRest(worker)
        end

        if hp <= 0 then
            Internal.markWorkerDead(worker, currentHour, normalizedJobType, presenceState, hasCalories, hasHydration)
        elseif not hasHydration then
            worker.state = Config.States.Dehydrated
        elseif not hasCalories then
            worker.state = Config.States.Starving
        elseif forcedRest and presenceState == Config.PresenceStates.Home then
            worker.state = Config.States.Resting
        elseif presenceState == Config.PresenceStates.Home and (tonumber(worker.haulCount) or 0) > 0 then
            worker.state = Config.States.StorageFull
        elseif presenceState == Config.PresenceStates.Home
            and worker.jobEnabled
            and worker.assignedSiteID
            and not Internal.hasWarehouseCapacityForScavenge(worker) then
            worker.state = Config.States.StorageFull
        elseif presenceState == Config.PresenceStates.Home
            and worker.jobEnabled
            and worker.assignedSiteID
            and (totalCaloriesAvailable < outboundCaloriesThreshold
                or totalHydrationAvailable < outboundHydrationThreshold) then
            worker.state = Config.States.WarehouseShortage
        elseif presenceState == Config.PresenceStates.Scavenging and worker.jobEnabled and toolsReady and not forcedRest then
            worker.state = Config.States.Working
        elseif presenceState == Config.PresenceStates.Home and worker.jobEnabled and not worker.assignedSiteID then
            worker.state = Config.States.MissingSite
        elseif presenceState == Config.PresenceStates.Home and worker.jobEnabled and not toolsReady then
            worker.state = Config.States.MissingTool
        else
            worker.state = Config.States.Idle
        end
    end
end

if DC_Colony.Config.JobProfiles and DC_Colony.Config.JobProfiles.Scavenge then
    DC_Colony.Config.JobProfiles.Scavenge.processHandler = Sim.ProcessScavengeJob
    DC_Colony.Config.JobProfiles.Scavenge.hooks.initPresence = function(worker, currentHour)
        Internal.ensureWorkerHome(worker)
        worker.presenceState = Internal.getScavengePresenceState(worker)
        if worker.presenceState == DC_Colony.Config.PresenceStates.Home and worker.haulLedger and #worker.haulLedger > 0 then
            Internal.completeScavengeReturnHome(worker, currentHour)
        end
        worker.dumpCooldownHours = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
    end
    DC_Colony.Config.JobProfiles.Scavenge.hooks.prepareLoadout = function(worker, speedMultiplier)
        if not DC_Colony.Config.GetScavengeLoadout then return speedMultiplier, nil end
        local loadout = DC_Colony.Config.GetScavengeLoadout(worker)
        worker.scavengeTier = loadout.tier or 0
        worker.scavengeTierLabel = DC_Colony.Config.GetScavengeTierLabel and DC_Colony.Config.GetScavengeTierLabel(loadout.tier) or nil
        worker.scavengePoolRolls = loadout.poolRolls or 0
        worker.scavengeFailureWeight = loadout.failureWeight or 0
        worker.scavengeSearchSpeedMultiplier = loadout.searchSpeedMultiplier or 1
        worker.scavengeCapabilities = loadout.capabilityList or {}
        return speedMultiplier * (tonumber(loadout.searchSpeedMultiplier) or 1), loadout
    end
    DC_Colony.Config.JobProfiles.Scavenge.hooks.getCanWork = function(worker, defaultCanWork, forcedRest)
        return defaultCanWork and worker.presenceState == DC_Colony.Config.PresenceStates.Scavenging
    end
    DC_Colony.Config.JobProfiles.Scavenge.hooks.getProgressDescriptor = function(worker, profile)
        local Cfg = DC_Colony.Config
        local Inter = DC_Colony.Interaction
        local presenceState = tostring(worker.presenceState or "")
        local states = Cfg.PresenceStates or {}

        if presenceState == tostring(states.AwayToSite or "AwayToSite")
            or presenceState == tostring(states.AwayToHome or "AwayToHome") then
            local travelTemplate = presenceState == tostring(states.AwayToSite or "AwayToSite")
                and Inter.getInteractionEntry("Progress", "Common.TravelToSite")
                or Inter.getInteractionEntry("Progress", "Common.TravelToHome")
            if type(travelTemplate) == "table" then
                local totalHours = Inter.getTravelTotalHours()
                local remainingWorldHours = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
                local progressHours = math.max(0, totalHours - remainingWorldHours)
                local tokens = Inter.buildProgressTokens(worker, progressHours, totalHours, remainingWorldHours)
                return {
                    label = DynamicTrading.FormatInteractionString(travelTemplate.activeText, tokens),
                    displayText = DynamicTrading.FormatInteractionString(travelTemplate.activeText, tokens),
                    fillRatio = math.max(0, math.min(1, progressHours / totalHours)),
                    captionText = DynamicTrading.FormatInteractionString(travelTemplate.captionText, tokens),
                    summaryText = Inter.formatDecimal(progressHours, 1) .. " / " .. Inter.formatDecimal(totalHours, 1) .. "h",
                    progressHours = progressHours,
                    cycleHours = totalHours,
                    remainingWorldHours = remainingWorldHours,
                    color = travelTemplate.color
                }
            end
        end

        local workingState = tostring((Cfg.States or {}).Working or "Working")
        if tostring(worker.state or "") ~= workingState or worker.jobEnabled ~= true then
            return nil
        end

        local template = Inter.getInteractionEntry("Progress", "Scavenge.Active")
        if type(template) ~= "table" then return nil end

        local workTarget = math.max(1,
            tonumber(worker.workTarget)
                or tonumber(Cfg.GetEffectiveWorkTarget and Cfg.GetEffectiveWorkTarget(worker, profile))
                or tonumber(Cfg.GetEffectiveCycleHours and Cfg.GetEffectiveCycleHours(worker, profile))
                or tonumber(profile and profile.cycleHours) or 1
        )
        local progressAmount = math.max(0, tonumber(worker.workProgress) or 0)
        if progressAmount > workTarget then progressAmount = progressAmount % workTarget end

        local baseSpeed = math.max(0.01,
            tonumber(worker.baseWorkSpeedMultiplier)
                or tonumber(Cfg.GetBaseWorkSpeedMultiplier and Cfg.GetBaseWorkSpeedMultiplier(worker, profile))
                or 1
        )
        local Skills = DC_Colony.Skills
        local skillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, profile) or nil
        local skillSpeed = math.max(0.01, tonumber(skillEffects and skillEffects.speedMultiplier or worker.jobSkillSpeedMultiplier or 1) or 1)
        local equipmentSpeed = math.max(0.01, tonumber(worker.scavengeSearchSpeedMultiplier) or 1)
        local effectiveSpeed = baseSpeed * skillSpeed * equipmentSpeed
        local baseWorkPerHour = math.max(0.01,
            tonumber(Cfg.GetScavengeBaseWorkPerHour and Cfg.GetScavengeBaseWorkPerHour()) or 1
        )
        local effectiveWorkPerHour = baseWorkPerHour * effectiveSpeed
        local remainingWorkAmount = math.max(0, workTarget - progressAmount)
        local remainingWorldHours = effectiveWorkPerHour > 0 and (remainingWorkAmount / effectiveWorkPerHour) or nil
        local tokens = {
            place = Inter.GetPlaceLabel(worker),
            count = tostring(math.max(0, tonumber(worker.outputCount) or 0)),
            eta = Inter.formatDurationHours(remainingWorldHours),
            progress = Inter.formatWholeAmount(progressAmount),
            total = Inter.formatWholeAmount(workTarget)
        }
        return {
            label = DynamicTrading.FormatInteractionString(template.activeText, tokens),
            displayText = DynamicTrading.FormatInteractionString(template.activeText, tokens),
            fillRatio = math.max(0, math.min(1, progressAmount / workTarget)),
            captionText = DynamicTrading.FormatInteractionString(template.captionText, tokens),
            summaryText = Inter.formatWholeAmount(progressAmount)
                .. " / " .. Inter.formatWholeAmount(workTarget)
                .. " work | Speed x" .. Inter.formatDecimal(effectiveSpeed, 2),
            progressAmount = progressAmount,
            workTarget = workTarget,
            progressHours = progressAmount,
            cycleHours = workTarget,
            remainingWorldHours = remainingWorldHours,
            baseSpeedMultiplier = baseSpeed,
            skillSpeedMultiplier = skillSpeed,
            equipmentSpeedMultiplier = equipmentSpeed,
            effectiveSpeedMultiplier = effectiveSpeed,
            effectiveWorkPerHour = effectiveWorkPerHour,
            color = template.color
        }
    end
end
