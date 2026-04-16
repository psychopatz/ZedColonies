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
    local colonyID = ownerData.colonyID
    local colonyData = Registry.GetColonyData(colonyID, true)
    local workersData = Registry.GetWorkersData(colonyID, true)
    local archetypeID = Config.NormalizeArchetypeID(template.archetypeID or template.profession)
    local jobType = Config.NormalizeJobType(template.jobType or template.profession or Config.GetDefaultJobForArchetype(archetypeID))
    local profile = Config.GetJobProfile(jobType)
    local workerID = template.workerID or Registry.NextID("worker", colonyID)
    local currentHour = (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()
    local starterCalories, starterHydration = Internal.GetStarterReserveTotals(template)

    local sourceLoadout = Internal.NormalizeSourceLoadout and Internal.NormalizeSourceLoadout(template.sourceLoadout or template.loadout)
        or (template.sourceLoadout or template.loadout)
    local templateToolLedger = Internal.CopyShallow(template.toolLedger)
    if #templateToolLedger <= 0 then
        templateToolLedger = Internal.BuildToolLedgerFromLoadout and Internal.BuildToolLedgerFromLoadout(sourceLoadout) or {}
    end

    local worker = {
        colonyID = colonyID,
        ownerUsername = owner,
        workerID = workerID,
        name = template.name or (jobType .. " Worker " .. tostring(workerID)),
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
        toolLedger = templateToolLedger,
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
        sourceNPCType = template.sourceNPCType,
        sourceLoadout = Internal.CopyShallow(sourceLoadout),
        sourceLoadoutSeeded = template.sourceLoadoutSeeded == true or #templateToolLedger > 0,
        detailVersion = tonumber(template.detailVersion) or 1
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
    local persistedWorker = Registry.GetWorkerData(colonyID, workerID)
    for key, value in pairs(worker) do
        persistedWorker[key] = value
    end
    ownerData.workers[workerID] = persistedWorker

    local exists = false
    for _, existingID in ipairs(workersData.workerIDs) do
        if existingID == workerID then
            exists = true
            break
        end
    end
    if not exists then
        table.insert(workersData.workerIDs, workerID)
    end

    if Registry.GetWorkerSummary then
        workersData.summaries[workerID] = Registry.GetWorkerSummary(persistedWorker)
    end

    Registry.Internal.Runtime.workerToColonyID[workerID] = colonyID
    if persistedWorker.sourceNPCID ~= nil and tostring(persistedWorker.sourceNPCID or "") ~= "" then
        Registry.Internal.Runtime.sourceNPCToWorkerID[tostring(persistedWorker.sourceNPCID)] = workerID
    end
    colonyData.versions.colony = colonyData.versions.colony + 1
    Registry.TouchWorkersVersion(colonyID)

    Registry.Save()
    return persistedWorker
end

function Registry.GetWorkerRaw(workerID)
    local colonyID = Registry.GetWorkerColonyID(workerID)
    if not colonyID then
        return nil
    end

    return Registry.GetWorkerData(colonyID, workerID)
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
    local colonyID = Registry.GetColonyIDForOwner(owner, false)
    if not colonyID then
        return {}
    end
    local workersData = Registry.GetWorkersData(colonyID, false)
    local workers = {}

    for _, workerID in ipairs(workersData and workersData.workerIDs or {}) do
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
    local colonyID = Registry.GetColonyIDForOwner(owner, false)
    if not colonyID then
        return false
    end

    local ownerData = Registry.EnsureOwner(owner)
    local colonyData = Registry.GetColonyData(colonyID, false)
    local workersData = Registry.GetWorkersData(colonyID, false)
    local worker = ownerData.workers[workerID]
    if not worker or worker.ownerUsername ~= owner then
        return false
    end

    workersData.summaries[workerID] = nil
    for index = #workersData.workerIDs, 1, -1 do
        if workersData.workerIDs[index] == workerID then
            table.remove(workersData.workerIDs, index)
        end
    end

    if worker.sourceNPCID ~= nil and tostring(worker.sourceNPCID or "") ~= "" then
        Registry.Internal.Runtime.sourceNPCToWorkerID[tostring(worker.sourceNPCID)] = nil
    end
    Registry.RemoveWorkerShard(colonyID, workerID)
    colonyData.versions.colony = colonyData.versions.colony + 1
    Registry.TouchWorkersVersion(colonyID)

    Registry.Save()
    return true
end

return Registry
