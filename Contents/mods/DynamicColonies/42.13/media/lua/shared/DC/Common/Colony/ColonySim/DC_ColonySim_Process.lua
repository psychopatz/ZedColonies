local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Sites = DC_Colony.Sites
local Interaction = DC_Colony.Interaction
local Warehouse = DC_Colony.Warehouse
local Output = DC_Colony.Output
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy
local Skills = DC_Colony.Skills
local Health = DC_Colony.Health
local Medical = DC_Colony.Medical
local Nutrition = DC_Colony.Nutrition

local function buildXPAmount(totalQuantity)
    return math.max(10, 20 + math.min(20, math.floor(tonumber(totalQuantity) or 0) * 3))
end

local function grantWorkerJobXP(worker, currentHour, skillEffects, totalQuantity)
    if not Skills or not Skills.GrantXP or not skillEffects or not skillEffects.skillID then
        return
    end

    local result = Skills.GrantXP(worker, skillEffects.skillID, buildXPAmount(totalQuantity))
    if not result or (tonumber(result.granted) or 0) <= 0 then
        return
    end

    local message = "Earned " .. tostring(math.floor((tonumber(result.granted) or 0) + 0.5)) .. " " .. tostring(skillEffects.skillLabel or skillEffects.skillID or "Skill") .. " XP."

    if (tonumber(result.leveledUp) or 0) > 0 then
        message = message .. " " .. tostring(skillEffects.skillLabel or skillEffects.skillID or "Skill")
            .. " increased to level "
            .. tostring(result.newLevel)
            .. "."
    end

    Internal.appendWorkerLog(
        worker,
        message,
        currentHour,
        "skills"
    )
end

local function getBuildings()
    return DC_Buildings or nil
end

local function getOwnerKey(ownerUsername)
    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

-- Removed inline medical/HP logic in favor of ColonyHealth and ColonyMedical submodules

function Sim.ProcessWorker(worker, currentHour)
    if not worker then return end

    Registry.RecalculateWorker(worker)
    worker.sleepHealingRate = 0
    worker.sleepHealingSource = "None"
    worker.medicalSupplyBlocked = false

    local profile = Config.GetJobProfile(worker.jobType)
    local normalizedJobType = Config.NormalizeJobType(worker.jobType)
    local isBuilderJob = normalizedJobType == (Config.JobTypes and Config.JobTypes.Builder)
    local isDoctorJob = normalizedJobType == (Config.JobTypes and Config.JobTypes.Doctor)
    local scavengeLoadout = nil
    local cycleHours = Config.GetEffectiveWorkTarget and Config.GetEffectiveWorkTarget(worker, profile)
        or (Config.GetEffectiveCycleHours and Config.GetEffectiveCycleHours(worker, profile))
        or (profile.cycleHours or 24)
    local baseWorkSpeedMultiplier = Config.GetBaseWorkSpeedMultiplier and Config.GetBaseWorkSpeedMultiplier(worker, profile) or 1.0
    local scavengeBaseWorkPerHour = Config.GetScavengeBaseWorkPerHour and Config.GetScavengeBaseWorkPerHour() or 1.0
    local lastHour = tonumber(worker.lastSimHour) or tonumber(currentHour) or 0
    local deltaHours = math.max(0, currentHour - lastHour)
    local lowEnergyReason = (Config.ReturnReasons and (Config.ReturnReasons.LowEnergy or Config.ReturnReasons.LowTiredness)) or "LowEnergy"

    if worker.state == Config.States.Dead then
        worker.jobEnabled = false
        worker.lastNutritionCheckpoint = Config.GetMealCheckpointCountAtHour(currentHour)
        if deltaHours > 0 then
            worker.lastSimHour = currentHour
        end
        Registry.RecalculateWorker(worker)
        return
    end

    if Energy and Energy.IsDepleted and Energy.IsDepleted(worker) and not Energy.IsForcedRest(worker) then
        Energy.SetForcedRest(worker, true, lowEnergyReason, currentHour)
    end

    Sites.RefreshWorkerSite(worker)
    local jobSkillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, profile) or {
        speedMultiplier = 1,
        yieldMultiplier = 1,
        botchChanceMultiplier = 1,
        level = 0
    }
    local speedMultiplier = math.max(0.01, tonumber(jobSkillEffects.speedMultiplier) or 1) * (tonumber(baseWorkSpeedMultiplier) or 1)
    worker.workTarget = cycleHours
    worker.workCycleHours = cycleHours
    worker.baseWorkSpeedMultiplier = baseWorkSpeedMultiplier
    worker.jobSkillID = jobSkillEffects.skillID
    worker.jobSkillLabel = jobSkillEffects.skillLabel
    worker.jobSkillLevel = jobSkillEffects.level
    worker.jobSkillSpeedMultiplier = jobSkillEffects.speedMultiplier
    worker.jobSkillYieldMultiplier = jobSkillEffects.yieldMultiplier
    worker.jobSkillBotchMultiplier = jobSkillEffects.botchChanceMultiplier
    if isBuilderJob and DC_Buildings and DC_Buildings.GetProjectForWorker then
        local builderProject = DC_Buildings.GetProjectForWorker(worker)
        if builderProject then
            cycleHours = math.max(1, tonumber(builderProject.requiredWorkPoints) or cycleHours)
            worker.workTarget = cycleHours
            worker.workCycleHours = cycleHours
        end
    end

    if normalizedJobType == Config.JobTypes.Scavenge then
        Internal.ensureWorkerHome(worker)
        worker.presenceState = Internal.getScavengePresenceState(worker)
        if worker.presenceState == Config.PresenceStates.Home and worker.haulLedger and #worker.haulLedger > 0 then
            Internal.completeScavengeReturnHome(worker, currentHour)
        end
        worker.dumpCooldownHours = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
    end

    local dailyCaloriesNeed = Config.GetEffectiveDailyCaloriesNeed(worker, profile)
    local dailyHydrationNeed = Config.GetEffectiveDailyHydrationNeed(worker, profile)

    if worker.presenceState == Config.PresenceStates.Home and Warehouse and Warehouse.RestockWorker then
        local restock = Warehouse.RestockWorker(worker, dailyCaloriesNeed, dailyHydrationNeed)
        if restock and (tonumber(restock.provisionCount) or 0) > 0 then
            local provisionClause = Internal.buildWarehouseProvisionClause(
                restock.provisionSampleNames,
                restock.provisionHiddenCount
            )
            local message = "Restocked " .. tostring(restock.provisionCount) .. " provision"
                .. ((tonumber(restock.provisionCount) or 0) == 1 and "" or "s")
                .. " from warehouse"
            if provisionClause ~= "" then
                message = message .. ": " .. provisionClause .. "."
            else
                message = message .. "."
            end
            Internal.appendWorkerLog(worker, message, currentHour, "warehouse")
        end
    end

    Registry.RecalculateWorker(worker)
    local toolsReady = Registry.WorkerHasRequiredTools(worker)

    if normalizedJobType == Config.JobTypes.Scavenge and Config.GetScavengeLoadout then
        scavengeLoadout = Config.GetScavengeLoadout(worker)
        worker.scavengeTier = scavengeLoadout.tier or 0
        worker.scavengeTierLabel = Config.GetScavengeTierLabel and Config.GetScavengeTierLabel(scavengeLoadout.tier) or nil
        worker.scavengePoolRolls = scavengeLoadout.poolRolls or 0
        worker.scavengeFailureWeight = scavengeLoadout.failureWeight or 0
        worker.scavengeSearchSpeedMultiplier = scavengeLoadout.searchSpeedMultiplier or 1
        worker.scavengeCapabilities = scavengeLoadout.capabilityList or {}
        speedMultiplier = speedMultiplier * (tonumber(scavengeLoadout.searchSpeedMultiplier) or 1)
    else
        worker.scavengeTier = nil
        worker.scavengeTierLabel = nil
        worker.scavengePoolRolls = nil
        worker.scavengeFailureWeight = nil
        worker.scavengeSearchSpeedMultiplier = nil
        worker.scavengeCapabilities = nil
    end

    worker.siteState = worker.siteState or "Deferred"
    worker.toolState = toolsReady and "Ready" or "Missing"

    local forcedRest = Energy and Energy.IsForcedRest and Energy.IsForcedRest(worker) or false
    local canWork = worker.jobEnabled and toolsReady and not forcedRest
    if normalizedJobType == Config.JobTypes.Scavenge then
        canWork = canWork and worker.presenceState == Config.PresenceStates.Scavenging
    end
    local nutritionResult = Nutrition and Nutrition.ProcessWorkerNutrition and Nutrition.ProcessWorkerNutrition(
        worker,
        currentHour,
        dailyCaloriesNeed,
        dailyHydrationNeed,
        canWork
    )
    local workableHours = math.max(0, tonumber(nutritionResult and nutritionResult.workableHours) or 0)
    local supportedHours = math.max(0, tonumber(nutritionResult and nutritionResult.supportedHours) or 0)
    local hasCalories = nutritionResult and nutritionResult.hasCalories == true or false
    local hasHydration = nutritionResult and nutritionResult.hasHydration == true or false
    local hp = Health and Health.GetCurrent(worker) or 100

    if Health and Health.ApplySleepHealing then
        hp = select(1, Health.ApplySleepHealing(worker, forcedRest, supportedHours))
    end

    worker.starvationHours = 0
    worker.dehydrationHours = 0

    local ctx = {
        currentHour = currentHour,
        profile = profile,
        normalizedJobType = normalizedJobType,
        speedMultiplier = speedMultiplier,
        cycleHours = cycleHours,
        toolsReady = toolsReady,
        hp = hp,
        hasCalories = hasCalories,
        hasHydration = hasHydration,
        forcedRest = forcedRest,
        workableHours = workableHours,
        supportedHours = supportedHours,
        deltaHours = deltaHours,
        lowEnergyReason = lowEnergyReason,
        scavengeLoadout = scavengeLoadout,
        jobSkillEffects = jobSkillEffects
    }

    if normalizedJobType == Config.JobTypes.Scavenge then
        Sim.ProcessScavengeJob(worker, ctx)
    elseif isBuilderJob then
        Sim.ProcessBuilderJob(worker, ctx)
    elseif isDoctorJob then
        Sim.ProcessDoctorJob(worker, ctx)
    elseif normalizedJobType == Config.JobTypes.Fish then
        Sim.ProcessFishingJob(worker, ctx)
    else
        Sim.ProcessGenericJob(worker, ctx)
    end

    if deltaHours > 0 then
        worker.lastSimHour = currentHour
    end
    Registry.RecalculateWorker(worker)
end

function Sim.ProcessAllWorkers(currentHour)
    currentHour = currentHour or (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()

    if Medical and Medical.SetPlansCache and Medical.BuildAllOwnerPlans then
        Medical.SetPlansCache(Medical.BuildAllOwnerPlans())
    end

    for _, ownerUsername in ipairs(Registry.GetOwnerUsernames and Registry.GetOwnerUsernames() or {}) do
        local orderedWorkers = Registry.GetWorkersForOwnerRaw(ownerUsername)
        local ownerKey = getOwnerKey(ownerUsername)

        table.sort(orderedWorkers, function(a, b)
            local plan = Medical and Medical.GetOwnerPlan and Medical.GetOwnerPlan(ownerKey) or nil
            local priorityA = plan and plan.priorityIndex and plan.priorityIndex[tostring(a and a.workerID or "")] or 1000000
            local priorityB = plan and plan.priorityIndex and plan.priorityIndex[tostring(b and b.workerID or "")] or 1000000
            if priorityA ~= priorityB then
                return priorityA < priorityB
            end

            return tostring(a and a.workerID or "") < tostring(b and b.workerID or "")
        end)

        for _, worker in ipairs(orderedWorkers) do
            if Internal.freezeWorkerForOfflineOwner(worker, currentHour) then
                Registry.RecalculateWorker(worker)
            else
                Sim.ProcessWorker(worker, currentHour)
            end
        end

        if Medical and Medical.GetOwnerPlan then
            local plan = Medical.GetOwnerPlan(ownerKey)
            local usedHours = math.max(0, tonumber(plan and plan.usedTreatmentHours) or 0)
            if usedHours > 0 and Warehouse and Warehouse.ConsumeMedicalProvisionHours then
                Warehouse.ConsumeMedicalProvisionHours(ownerKey, usedHours)
            end
        end
    end

    if Medical and Medical.ClearPlansCache then
        Medical.ClearPlansCache()
    end
    Registry.Save()
end

function Sim.OnTick()
    Sim.tickCounter = Sim.tickCounter + 1
    if Sim.tickCounter < Config.SIM_TICK_RATE then
        return
    end

    Sim.tickCounter = 0
    local currentHour = (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()
    local stepHours = math.max(0.05, tonumber(Config.SIM_TIME_STEP_HOURS) or 0.25)
    if Sim.lastProcessedHour >= 0 and (currentHour - Sim.lastProcessedHour) < stepHours then
        return
    end

    Sim.lastProcessedHour = currentHour
    Sim.ProcessAllWorkers(currentHour)
end
