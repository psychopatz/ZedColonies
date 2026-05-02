local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Sites = DC_Colony.Sites
local Interaction = DC_Colony.Interaction
local Warehouse = DC_Colony.Warehouse
local Output = DC_Colony.Output
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy
local Resources = DC_Colony.Resources
local Companion = DC_Colony.Companion

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
    local isUnemployedJob = normalizedJobType == (Config.JobTypes and Config.JobTypes.Unemployed)
    local cycleHours = Config.GetEffectiveWorkTarget and Config.GetEffectiveWorkTarget(worker, profile)
        or (Config.GetEffectiveCycleHours and Config.GetEffectiveCycleHours(worker, profile))
        or (profile.cycleHours or 24)
    local baseWorkSpeedMultiplier = Config.GetBaseWorkSpeedMultiplier and Config.GetBaseWorkSpeedMultiplier(worker, profile) or 1.0
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

    local canTakeJob = true
    local jobCapabilityReason = nil
    if Config.CanWorkerTakeJob then
        canTakeJob, jobCapabilityReason = Config.CanWorkerTakeJob(worker, normalizedJobType)
    end
    if canTakeJob == false then
        if worker.jobCapabilityReason ~= jobCapabilityReason or worker.jobEnabled == true then
            Internal.appendWorkerLog(
                worker,
                tostring(jobCapabilityReason or "This worker can no longer perform the assigned job."),
                currentHour,
                "jobs"
            )
        end
        worker.jobCapabilityReason = jobCapabilityReason
        worker.jobEnabled = false
        worker.state = Config.States.Idle
        worker.workProgress = 0
        if profile and profile.hooks and profile.hooks.onJobBlocked then
            profile.hooks.onJobBlocked(worker)
        end
        if deltaHours > 0 then
            worker.lastSimHour = currentHour
        end
        Registry.RecalculateWorker(worker)
        return
    end
    worker.jobCapabilityReason = nil

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
    if isUnemployedJob then
        worker.jobEnabled = false
        worker.state = Config.States.Idle
        worker.workProgress = 0
        worker.workTarget = nil
        worker.workCycleHours = nil
        worker.jobSkillID = nil
        worker.jobSkillLabel = nil
        worker.jobSkillLevel = 0
        worker.jobSkillSpeedMultiplier = 1
        worker.jobSkillYieldMultiplier = 1
        worker.jobSkillBotchMultiplier = 1
        if deltaHours > 0 then
            worker.lastSimHour = currentHour
        end
        Registry.RecalculateWorker(worker)
        return
    end
    -- Allow the job to override cycleHours (e.g. Builder reads project work points).
    if profile and profile.hooks and profile.hooks.getCycleHours then
        cycleHours = profile.hooks.getCycleHours(worker, cycleHours) or cycleHours
    end
    worker.workTarget = cycleHours
    worker.workCycleHours = cycleHours

    -- Allow the job to initialize presence state (e.g. Scavenge, Gatherer travel loop).
    if profile and profile.hooks and profile.hooks.initPresence then
        profile.hooks.initPresence(worker, currentHour)
    end

    local dailyCaloriesNeed = Config.GetEffectiveDailyCaloriesNeed(worker, profile)
    local dailyHydrationNeed = Config.GetEffectiveDailyHydrationNeed(worker, profile)

    if worker.presenceState == Config.PresenceStates.Home and Warehouse and Warehouse.DepositWorkerOutput then
        Warehouse.DepositWorkerOutput(worker)
    end

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

    -- Allow the active job to prepare its loadout and adjust speedMultiplier.
    -- Other profiles clear their own stale fields via clearStaleFields.
    local jobLoadout = nil
    if profile and profile.hooks and profile.hooks.prepareLoadout then
        speedMultiplier, jobLoadout = profile.hooks.prepareLoadout(worker, speedMultiplier)
    end
    for _, p in pairs(Config.JobProfiles or {}) do
        if p.jobType ~= normalizedJobType and p.hooks and p.hooks.clearStaleFields then
            p.hooks.clearStaleFields(worker)
        end
    end

    worker.siteState = worker.siteState or "Deferred"
    worker.toolState = toolsReady and "Ready" or "Missing"
    if profile and profile.hooks and profile.hooks.getToolState then
        local ts = profile.hooks.getToolState(worker)
        if ts then worker.toolState = ts end
    end

    local forcedRest = Energy and Energy.IsForcedRest and Energy.IsForcedRest(worker) or false
    local canWork = worker.jobEnabled and toolsReady and not forcedRest
    if profile and profile.hooks and profile.hooks.getCanWork then
        canWork = profile.hooks.getCanWork(worker, canWork, forcedRest)
    end

    local ctx = {
        currentHour = currentHour,
        profile = profile,
        normalizedJobType = normalizedJobType,
        speedMultiplier = speedMultiplier,
        cycleHours = cycleHours,
        toolsReady = toolsReady,
        hp = nil,
        hasCalories = false,
        hasHydration = false,
        forcedRest = forcedRest,
        canWork = canWork,
        workableHours = 0,
        supportedHours = 0,
        dailyCaloriesNeed = dailyCaloriesNeed,
        dailyHydrationNeed = dailyHydrationNeed,
        deltaHours = deltaHours,
        lowEnergyReason = lowEnergyReason,
        jobLoadout = jobLoadout,
        jobSkillEffects = jobSkillEffects
    }

    Sim.RunWorkerLifeCycle(worker, ctx)

    local handler = profile and profile.processHandler
    if handler then
        handler(worker, ctx)
    else
        Sim.ProcessGenericJob(worker, ctx)
    end

    if worker.presenceState == Config.PresenceStates.Home and Warehouse and Warehouse.DepositWorkerOutput then
        Warehouse.DepositWorkerOutput(worker)
    end

    if deltaHours > 0 then
        worker.lastSimHour = currentHour
    end
    Registry.RecalculateWorker(worker)
end

function Sim.ProcessAllWorkers(currentHour)
    currentHour = currentHour or (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()

    if Resources and Resources.ProcessAllOwners then
        Resources.ProcessAllOwners(currentHour)
    end

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
