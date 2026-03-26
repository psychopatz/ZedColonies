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
    local scavengeLoadout = ctx.scavengeLoadout
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
