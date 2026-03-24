DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal

function Registry.CreateWorker(ownerUsername, template)
    template = template or {}
    local owner = Config.GetOwnerUsername(ownerUsername)
    local ownerData = Registry.EnsureOwner(owner)
    local archetypeID = Config.NormalizeArchetypeID(template.archetypeID or template.profession)
    local jobType = Config.NormalizeJobType(template.jobType or template.profession or Config.GetDefaultJobForArchetype(archetypeID))
    local profile = Config.GetJobProfile(jobType)
    local data = Registry.GetData()
    local workerID = template.workerID or ("worker_" .. tostring(Registry.NextID("worker")))
    local currentHour = (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()
    local starterCalories, starterHydration = Internal.GetStarterReserveTotals(template)

    local worker = {
        ownerUsername = owner,
        workerID = workerID,
        name = template.name or (jobType .. " Worker " .. tostring(data.Counters.worker)),
        profession = template.profession or jobType,
        jobType = jobType,
        archetypeID = archetypeID,
        state = template.state or Config.States.Idle,
        assignedSiteID = template.assignedSiteID,
        homeX = template.homeX,
        homeY = template.homeY,
        homeZ = template.homeZ or 0,
        workX = template.workX,
        workY = template.workY,
        workZ = template.workZ or 0,
        radius = template.radius or Config.DEFAULT_SITE_RADIUS,
        toolState = template.toolState or "Missing",
        siteState = template.siteState or "Deferred",
        presenceState = template.presenceState or Config.PresenceStates.Home,
        travelHoursRemaining = tonumber(template.travelHoursRemaining) or 0,
        returnReason = template.returnReason,
        jobEnabled = template.jobEnabled ~= false,
        autoRepeatJob = template.autoRepeatJob == true or template.autoRepeatScavenge == true,
        autoRepeatScavenge = template.autoRepeatScavenge == true,
        nutritionModelVersion = tonumber(template.nutritionModelVersion) or Config.NUTRITION_MODEL_VERSION,
        lastSimHour = template.lastSimHour or currentHour,
        lastNutritionCheckpoint = tonumber(template.lastNutritionCheckpoint) or Config.GetMealCheckpointCountAtHour(template.lastSimHour or currentHour),
        workProgress = tonumber(template.workProgress) or 0,
        workTarget = tonumber(template.workTarget) or nil,
        caloriesCached = starterCalories,
        hydrationCached = starterHydration,
        caloriesOverflow = tonumber(template.caloriesOverflow) or 0,
        hydrationOverflow = tonumber(template.hydrationOverflow) or 0,
        dailyCaloriesNeed = tonumber(template.dailyCaloriesNeed) or profile.dailyCaloriesNeed,
        dailyHydrationNeed = tonumber(template.dailyHydrationNeed) or profile.dailyHydrationNeed,
        maxHp = math.max(1, tonumber(template.maxHp) or tonumber(template.healthMax) or Config.DEFAULT_WORKER_MAX_HP or 100),
        hp = tonumber(template.hp) or tonumber(template.health),
        starvationHours = tonumber(template.starvationHours) or 0,
        dehydrationHours = tonumber(template.dehydrationHours) or 0,
        nutritionLedger = Internal.BuildStarterNutritionLedger(template),
        toolLedger = Internal.CopyShallow(template.toolLedger),
        baseCarryWeightOverride = tonumber(template.baseCarryWeightOverride) or tonumber(template.baseCarryWeight) or tonumber(template.maxCarryWeight) or nil,
        haulLedger = Internal.CopyShallow(template.haulLedger),
        outputLedger = Internal.CopyShallow(template.outputLedger),
        dumpCooldownHours = tonumber(template.dumpCooldownHours) or 0,
        dumpTrips = tonumber(template.dumpTrips) or 0,
        moneyStored = math.max(0, math.floor(tonumber(template.moneyStored) or 0)),
        deathCause = template.deathCause,
        energy = Internal.CopyShallow(template.energy or template.tiredness),
        tiredness = Internal.CopyShallow(template.energy or template.tiredness), -- Compatibility
        statusFlags = Internal.CopyShallow(template.statusFlags),
        activityLog = Internal.CopyShallow(template.activityLog),
        skills = Internal.CopyDeep(template.skills),
        skillModelVersion = tonumber(template.skillModelVersion),
        isFemale = template.isFemale,
        identitySeed = template.identitySeed,
        visualID = template.visualID,
        sourceNPCID = template.sourceNPCID,
        sourceNPCType = template.sourceNPCType
    }

    if worker.isFemale == nil then
        worker.isFemale = ZombRand(2) == 0
    end
    if not worker.identitySeed then
        worker.identitySeed = ZombRand(1000) + 1
    end
    if not worker.visualID then
        worker.visualID = ZombRand(1000000)
    end
    if worker.hp == nil then
        worker.hp = worker.maxHp
    end
    Internal.EnsureActivityLog(worker)

    Registry.RecalculateWorker(worker)
    data.Workers[workerID] = worker

    local exists = false
    for _, existingID in ipairs(ownerData.workerIDs) do
        if existingID == workerID then
            exists = true
            break
        end
    end
    if not exists then
        table.insert(ownerData.workerIDs, workerID)
    end

    Registry.Save()
    return worker
end

function Registry.GetWorkerRaw(workerID)
    local data = Registry.GetData()
    return data.Workers[workerID]
end

function Registry.GetWorker(workerID)
    local worker = Registry.GetWorkerRaw(workerID)
    if worker then
        Registry.RecalculateWorker(worker)
    end
    return worker
end

function Registry.GetWorkerForOwnerRaw(ownerUsername, workerID)
    local worker = Registry.GetWorkerRaw(workerID)
    if not worker then return nil end
    if worker.ownerUsername ~= Config.GetOwnerUsername(ownerUsername) then
        return nil
    end
    return worker
end

function Registry.GetWorkerForOwner(ownerUsername, workerID)
    local worker = Registry.GetWorker(workerID)
    if not worker then return nil end
    if worker.ownerUsername ~= Config.GetOwnerUsername(ownerUsername) then
        return nil
    end
    return worker
end

function Registry.GetWorkersForOwnerRaw(ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local ownerData = Registry.EnsureOwner(owner)
    local workers = {}

    for _, workerID in ipairs(ownerData.workerIDs or {}) do
        local worker = Registry.GetWorkerRaw(workerID)
        if worker then
            workers[#workers + 1] = worker
        end
    end

    table.sort(workers, function(a, b)
        return tostring(a.name or a.workerID) < tostring(b.name or b.workerID)
    end)

    return workers
end

function Registry.GetWorkersForOwner(ownerUsername)
    local workers = {}

    for _, worker in ipairs(Registry.GetWorkersForOwnerRaw(ownerUsername)) do
        Registry.RecalculateWorker(worker)
        if worker then
            workers[#workers + 1] = worker
        end
    end

    return workers
end

function Registry.RemoveWorkerForOwner(ownerUsername, workerID)
    if not workerID then
        return false
    end

    local owner = Config.GetOwnerUsername(ownerUsername)
    local ownerData = Registry.EnsureOwner(owner)
    local data = Registry.GetData()
    local worker = data.Workers[workerID]
    if not worker or worker.ownerUsername ~= owner then
        return false
    end

    data.Workers[workerID] = nil

    for index = #ownerData.workerIDs, 1, -1 do
        if ownerData.workerIDs[index] == workerID then
            table.remove(ownerData.workerIDs, index)
        end
    end

    Registry.Save()
    return true
end

return Registry
