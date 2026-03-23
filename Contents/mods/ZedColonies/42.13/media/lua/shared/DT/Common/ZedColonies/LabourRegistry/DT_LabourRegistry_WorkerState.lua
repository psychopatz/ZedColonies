DT_Labour = DT_Labour or {}
DT_Labour.Registry = DT_Labour.Registry or {}
DT_Labour.Registry.Internal = DT_Labour.Registry.Internal or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry
local Internal = Registry.Internal
local Tiredness = DT_Labour.Tiredness
local Skills = DT_Labour.Skills

local function clampAmount(value)
    return math.max(0, tonumber(value) or 0)
end

local function getReserveCaps(worker)
    local profile = Config.GetJobProfile(worker and worker.jobType)
    local dailyCaloriesNeed = Config.GetEffectiveDailyCaloriesNeed and Config.GetEffectiveDailyCaloriesNeed(worker, profile)
        or tonumber(worker and worker.dailyCaloriesNeed)
        or tonumber(profile and profile.dailyCaloriesNeed)
        or 0
    local dailyHydrationNeed = Config.GetEffectiveDailyHydrationNeed and Config.GetEffectiveDailyHydrationNeed(worker, profile)
        or tonumber(worker and worker.dailyHydrationNeed)
        or tonumber(profile and profile.dailyHydrationNeed)
        or 0
    return clampAmount(dailyCaloriesNeed), clampAmount(dailyHydrationNeed)
end

local function normalizeLedgerEntry(entry)
    if DT_Labour and DT_Labour.Nutrition and DT_Labour.Nutrition.SanitizeLedgerEntry then
        return DT_Labour.Nutrition.SanitizeLedgerEntry(entry)
    end

    if not entry then
        return 0, 0
    end
    local calories = clampAmount(entry.caloriesRemaining)
    local hydration = clampAmount(entry.hydrationRemaining)
    if hydration > 0 and hydration < 25 then
        hydration = hydration * (Config.HYDRATION_POINTS_PER_THIRST or 1000)
    end

    entry.caloriesRemaining = calories
    entry.hydrationRemaining = hydration
    return calories, hydration
end

local function getLedgerTotals(worker)
    local calories = 0
    local hydration = 0
    for _, entry in ipairs(worker and worker.nutritionLedger or {}) do
        local entryCalories, entryHydration = normalizeLedgerEntry(entry)
        calories = calories + entryCalories
        hydration = hydration + entryHydration
    end
    return calories, hydration
end

local function migrateLegacyNutritionModel(worker)
    local currentVersion = tonumber(worker and worker.nutritionModelVersion) or 0
    local targetVersion = tonumber(Config.NUTRITION_MODEL_VERSION) or 3
    if not worker or currentVersion >= targetVersion then
        return
    end

    worker.nutritionLedger = Internal.EnsureArray(worker.nutritionLedger)
    worker.caloriesOverflow = clampAmount(worker.caloriesOverflow)
    worker.hydrationOverflow = clampAmount(worker.hydrationOverflow)

    local onBodyCalories = clampAmount(worker.caloriesCached) + worker.caloriesOverflow
    local onBodyHydration = clampAmount(worker.hydrationCached) + worker.hydrationOverflow
    for index = #worker.nutritionLedger, 1, -1 do
        local entry = worker.nutritionLedger[index]
        if DT_Labour and DT_Labour.Nutrition and DT_Labour.Nutrition.IsSyntheticReserveEntry and DT_Labour.Nutrition.IsSyntheticReserveEntry(entry) then
            local calories, hydration = normalizeLedgerEntry(entry)
            onBodyCalories = onBodyCalories + calories
            onBodyHydration = onBodyHydration + hydration
            table.remove(worker.nutritionLedger, index)
        end
    end

    local caloriesCap, hydrationCap = getReserveCaps(worker)
    if DT_Labour and DT_Labour.Nutrition and DT_Labour.Nutrition.SetOnBodyTotals then
        DT_Labour.Nutrition.SetOnBodyTotals(worker, onBodyCalories, onBodyHydration, caloriesCap, hydrationCap)
    else
        worker.caloriesCached = onBodyCalories
        worker.hydrationCached = onBodyHydration
    end
    worker.nutritionModelVersion = targetVersion
    worker.nutritionCacheDirty = true
end

function Registry.RecalculateWorker(worker)
    if not worker then return end

    worker.nutritionLedger = Internal.EnsureArray(worker.nutritionLedger)
    worker.toolLedger = Internal.EnsureArray(worker.toolLedger)
    worker.haulLedger = Internal.EnsureArray(worker.haulLedger)
    worker.outputLedger = Internal.EnsureArray(worker.outputLedger)
    Internal.EnsureActivityLog(worker)
    Internal.EnsureWorkerCacheState(worker)
    worker.moneyStored = math.max(0, math.floor(tonumber(worker.moneyStored) or 0))
    worker.jobType = Config.NormalizeJobType(worker.jobType or worker.profession)
    worker.archetypeID = Config.NormalizeArchetypeID(worker.archetypeID or worker.profession)
    worker.profession = worker.profession or worker.jobType
    worker.baseCarryWeightOverride = tonumber(worker.baseCarryWeightOverride) or nil
    worker.homeX = tonumber(worker.homeX) and math.floor(worker.homeX) or nil
    worker.homeY = tonumber(worker.homeY) and math.floor(worker.homeY) or nil
    worker.homeZ = math.floor(tonumber(worker.homeZ) or 0)
    worker.presenceState = worker.presenceState or Config.PresenceStates.Home
    worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
    worker.returnReason = worker.returnReason or nil
    worker.deathCause = tostring(worker.deathCause or "")
    worker.baseCarryWeight = Config.GetWorkerBaseCarryWeight and Config.GetWorkerBaseCarryWeight(worker)
        or (Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight())
        or math.max(0, tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT) or 8)
    if (tonumber(worker.dailyHydrationNeed) or 0) > 0 and (tonumber(worker.dailyHydrationNeed) or 0) < 25 then
        worker.dailyHydrationNeed = (tonumber(worker.dailyHydrationNeed) or 0) * (Config.HYDRATION_POINTS_PER_THIRST or 1000)
    end
    worker.maxHp = math.max(1, tonumber(worker.maxHp) or tonumber(worker.healthMax) or Config.DEFAULT_WORKER_MAX_HP or 100)
    worker.hp = math.max(0, math.min(worker.maxHp, tonumber(worker.hp) or tonumber(worker.health) or worker.maxHp))
    if Skills and Skills.EnsureWorkerSkills then
        Skills.EnsureWorkerSkills(worker)
    end
    if Tiredness and Tiredness.EnsureWorkerTiredness then
        Tiredness.EnsureWorkerTiredness(worker)
    end
    worker.lastNutritionCheckpoint = math.max(
        0,
        math.floor(tonumber(worker.lastNutritionCheckpoint) or Config.GetMealCheckpointCountAtHour(worker.lastSimHour or 0))
    )
    migrateLegacyNutritionModel(worker)
    worker.caloriesCached = clampAmount(worker.caloriesCached)
    worker.hydrationCached = clampAmount(worker.hydrationCached)
    worker.caloriesOverflow = clampAmount(worker.caloriesOverflow)
    worker.hydrationOverflow = clampAmount(worker.hydrationOverflow)
    local caloriesCap, hydrationCap = getReserveCaps(worker)
    if DT_Labour and DT_Labour.Nutrition and DT_Labour.Nutrition.NormalizeOnBodyReserve then
        DT_Labour.Nutrition.NormalizeOnBodyReserve(worker, caloriesCap, hydrationCap)
    end

    local storedCalories = clampAmount(worker.storedCalories)
    local storedHydration = clampAmount(worker.storedHydration)
    local outputCount = 0
    local outputWeight = 0
    local tags = type(worker.assignedToolTags) == "table" and worker.assignedToolTags or {}

    if worker.nutritionCacheDirty then
        storedCalories = 0
        storedHydration = 0
        for i = #worker.nutritionLedger, 1, -1 do
            local entry = worker.nutritionLedger[i]
            local entryCalories, entryHydration = normalizeLedgerEntry(entry)

            if entryCalories <= 0 and entryHydration <= 0 then
                table.remove(worker.nutritionLedger, i)
            else
                storedCalories = storedCalories + entryCalories
                storedHydration = storedHydration + entryHydration
            end
        end
        worker.storedCalories = storedCalories
        worker.storedHydration = storedHydration
        worker.nutritionCacheDirty = false
    end

    if worker.toolCacheDirty then
        tags = {}
        for i = #worker.toolLedger, 1, -1 do
            local entry = worker.toolLedger[i]
            if not entry or not entry.fullType then
                table.remove(worker.toolLedger, i)
            else
                entry.tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(entry.fullType)) or entry.tags or {}
                for _, tag in ipairs(entry.tags or {}) do
                    tags[tag] = true
                end
            end
        end
        worker.assignedToolTags = tags
        worker.toolCacheDirty = false
    end

    for i = #worker.outputLedger, 1, -1 do
        local entry = worker.outputLedger[i]
        if not entry or not entry.fullType then
            table.remove(worker.outputLedger, i)
        else
            local qty = math.max(1, tonumber(entry.qty) or 1)
            outputCount = outputCount + qty
            outputWeight = outputWeight + (Config.GetItemWeight(entry.fullType) * qty)
        end
    end
    worker.outputCount = outputCount
    worker.outputWeight = outputWeight
    worker.outputCacheDirty = false

    local haulCount = 0
    local haulRawWeight = 0
    for i = #worker.haulLedger, 1, -1 do
        local entry = worker.haulLedger[i]
        if not entry or not entry.fullType then
            table.remove(worker.haulLedger, i)
        else
            local qty = math.max(1, tonumber(entry.qty) or 1)
            haulCount = haulCount + qty
            haulRawWeight = haulRawWeight + (Config.GetItemWeight(entry.fullType) * qty)
        end
    end

    local carryProfile = Config.GetScavengeCarryProfile and Config.GetScavengeCarryProfile(worker) or nil
    local haulEffectiveWeight = Config.CalculateEffectiveCarryWeight and Config.CalculateEffectiveCarryWeight(haulRawWeight, carryProfile) or haulRawWeight

    worker.storedCalories = storedCalories
    worker.storedHydration = storedHydration
    worker.currentCaloriesBuffer = clampAmount(worker.caloriesCached)
    worker.currentHydrationBuffer = clampAmount(worker.hydrationCached)
    worker.carryoverCalories = clampAmount(worker.caloriesOverflow)
    worker.carryoverHydration = clampAmount(worker.hydrationOverflow)
    worker.bufferCaloriesTotal = worker.currentCaloriesBuffer + worker.carryoverCalories
    worker.bufferHydrationTotal = worker.currentHydrationBuffer + worker.carryoverHydration
    worker.provisionCaloriesReserve = storedCalories
    worker.provisionHydrationReserve = storedHydration
    worker.combinedCaloriesTotal = worker.bufferCaloriesTotal + storedCalories
    worker.combinedHydrationTotal = worker.bufferHydrationTotal + storedHydration

    worker.caloriesOverflow = worker.carryoverCalories
    worker.hydrationOverflow = worker.carryoverHydration
    worker.reserveCaloriesTotal = worker.bufferCaloriesTotal
    worker.reserveHydrationTotal = worker.bufferHydrationTotal
    worker.totalCaloriesAvailable = worker.combinedCaloriesTotal
    worker.totalHydrationAvailable = worker.combinedHydrationTotal
    worker.outputCount = outputCount
    worker.outputWeight = outputWeight
    worker.haulCount = haulCount
    worker.haulRawWeight = haulRawWeight
    worker.haulEffectiveWeight = haulEffectiveWeight
    worker.effectiveCarryLimit = carryProfile and carryProfile.effectiveCarryLimit or worker.baseCarryWeight
    worker.maxCarryWeight = carryProfile and carryProfile.maxCarryWeight or worker.baseCarryWeight
    worker.rawCarryAllowance = carryProfile and carryProfile.rawAllowance or worker.maxCarryWeight
    worker.carryContainerCount = #(carryProfile and carryProfile.containers or {})
    worker.dumpCooldownHours = math.max(0, tonumber(worker.dumpCooldownHours) or 0)
    worker.dumpTrips = math.max(0, tonumber(worker.dumpTrips) or 0)
    worker.assignedToolTags = tags
    if DT_Buildings and DT_Buildings.ApplyWorkerState then
        DT_Buildings.ApplyWorkerState(worker)
    end
    if Tiredness and Tiredness.ApplyPresentationFields then
        Tiredness.ApplyPresentationFields(worker)
    end
end

function Registry.WorkerHasRequiredTools(worker)
    local profile = Config.GetJobProfile(worker and worker.jobType)
    Registry.RecalculateWorker(worker)
    local tagMap = worker and worker.assignedToolTags or {}

    for _, requiredTag in ipairs(profile.requiredToolTags or {}) do
        local matched = false
        for itemTag, enabled in pairs(tagMap or {}) do
            if enabled and Config.TagMatches(itemTag, requiredTag) then
                matched = true
                break
            end
        end
        if not matched then
            return false
        end
    end

    return true
end

return Registry
