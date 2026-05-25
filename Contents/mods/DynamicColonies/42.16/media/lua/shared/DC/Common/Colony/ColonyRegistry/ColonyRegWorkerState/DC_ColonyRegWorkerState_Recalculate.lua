DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Energy = DC_Colony.Energy
local Skills = DC_Colony.Skills
local Data = Internal.ColonyRegWorkerState or {}

function Registry.RecalculateWorker(worker, options)
    if not worker then
        return
    end
    options = type(options) == "table" and options or {}

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
    if (worker.jobType == (Config.JobTypes and Config.JobTypes.Gatherer) or type(worker.gathererConfig) == "table")
        and DC_Colony and DC_Colony.Gatherer and DC_Colony.Gatherer.NormalizeConfig then
        worker.gathererConfig = DC_Colony.Gatherer.NormalizeConfig(worker)
    end
    worker.baseCarryWeightOverride = tonumber(worker.baseCarryWeightOverride) or nil
    worker.homeX = tonumber(worker.homeX) and math.floor(worker.homeX) or nil
    worker.homeY = tonumber(worker.homeY) and math.floor(worker.homeY) or nil
    worker.homeZ = math.floor(tonumber(worker.homeZ) or 0)
    worker.presenceState = worker.presenceState or Config.PresenceStates.Home
    worker.travelHoursRemaining = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
    worker.returnReason = worker.returnReason or nil
    Data.suspendUnsupportedCompanion(worker)
    worker.deathCause = tostring(worker.deathCause or "")
    worker.baseCarryWeight = Config.GetWorkerBaseCarryWeight and Config.GetWorkerBaseCarryWeight(worker)
        or (Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight())
        or math.max(0, tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT) or 8)
    if (tonumber(worker.dailyHydrationNeed) or 0) > 0 and (tonumber(worker.dailyHydrationNeed) or 0) < 25 then
        worker.dailyHydrationNeed = (tonumber(worker.dailyHydrationNeed) or 0) * (Config.HYDRATION_POINTS_PER_THIRST or 1000)
    end
    if Skills and Skills.EnsureWorkerSkills then
        Skills.EnsureWorkerSkills(worker)
    end
    worker.maxHp = math.max(
        1,
        tonumber(Config.GetHealthMax and Config.GetHealthMax(worker))
            or tonumber(worker.maxHp)
            or tonumber(worker.healthMax)
            or Config.DEFAULT_WORKER_MAX_HP
            or 100
    )
    worker.hp = math.max(0, math.min(worker.maxHp, tonumber(worker.hp) or tonumber(worker.health) or worker.maxHp))
    if Energy and Energy.EnsureWorkerEnergy then
        Energy.EnsureWorkerEnergy(worker)
    end
    worker.lastNutritionCheckpoint = math.max(
        0,
        math.floor(tonumber(worker.lastNutritionCheckpoint) or Config.GetMealCheckpointCountAtHour(worker.lastSimHour or 0))
    )
    Data.migrateLegacyNutritionModel(worker)
    worker.caloriesCached = Data.clampAmount(worker.caloriesCached)
    worker.hydrationCached = Data.clampAmount(worker.hydrationCached)
    worker.caloriesOverflow = Data.clampAmount(worker.caloriesOverflow)
    worker.hydrationOverflow = Data.clampAmount(worker.hydrationOverflow)
    local caloriesCap, hydrationCap = Data.getReserveCaps(worker)
    if DC_Colony and DC_Colony.Nutrition and DC_Colony.Nutrition.NormalizeOnBodyReserve then
        DC_Colony.Nutrition.NormalizeOnBodyReserve(worker, caloriesCap, hydrationCap)
    end

    local storedCalories = Data.clampAmount(worker.storedCalories)
    local storedHydration = Data.clampAmount(worker.storedHydration)
    local outputCount = 0
    local outputWeight = 0
    local tags = type(worker.assignedToolTags) == "table" and worker.assignedToolTags or {}

    if worker.sourceLoadoutSeeded == nil then
        worker.sourceLoadoutSeeded = #(worker.toolLedger or {}) > 0
    end

    if (#(worker.toolLedger or {}) <= 0)
        and worker.sourceLoadoutSeeded ~= true
        and type(worker.sourceLoadout) == "table"
        and Internal.BuildToolLedgerFromLoadout then
        local seededTools = Internal.BuildToolLedgerFromLoadout(worker.sourceLoadout)
        worker.sourceLoadoutSeeded = true
        if #seededTools > 0 then
            worker.toolLedger = seededTools
            worker.toolCacheDirty = true
        end
    end

    if worker.nutritionCacheDirty then
        storedCalories = 0
        storedHydration = 0
        for i = #worker.nutritionLedger, 1, -1 do
            local entry = worker.nutritionLedger[i]
            local entryCalories, entryHydration = Data.normalizeLedgerEntry(entry)

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
            local normalized = Internal.NormalizeEquipmentEntry and Internal.NormalizeEquipmentEntry(entry) or nil
            if not normalized or not normalized.fullType then
                table.remove(worker.toolLedger, i)
            else
                worker.toolLedger[i] = normalized
                if not (Internal.IsEquipmentEntryUsable and not Internal.IsEquipmentEntryUsable(normalized)) then
                    for _, tag in ipairs(normalized.tags or {}) do
                        tags[tag] = true
                    end
                end
            end
        end
        worker.assignedToolTags = tags
        worker.toolCacheDirty = false
    end

    for i = #worker.outputLedger, 1, -1 do
        local entry = worker.outputLedger[i]
        local normalized = Internal.NormalizeOutputEntry and Internal.NormalizeOutputEntry(entry) or nil
        if not normalized or not normalized.fullType then
            table.remove(worker.outputLedger, i)
        else
            worker.outputLedger[i] = normalized
            local qty = math.max(1, tonumber(normalized.qty) or 1)
            outputCount = outputCount + qty
            outputWeight = outputWeight + (Config.GetItemWeight(normalized.fullType) * qty)
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

    local carryProfile = Config.GetWorkerCarryProfile and Config.GetWorkerCarryProfile(worker)
        or (Config.GetScavengeCarryProfile and Config.GetScavengeCarryProfile(worker))
        or nil
    local haulEffectiveWeight = Config.CalculateEffectiveCarryWeight and Config.CalculateEffectiveCarryWeight(haulRawWeight, carryProfile) or haulRawWeight

    worker.storedCalories = storedCalories
    worker.storedHydration = storedHydration
    worker.currentCaloriesBuffer = Data.clampAmount(worker.caloriesCached)
    worker.currentHydrationBuffer = Data.clampAmount(worker.hydrationCached)
    worker.carryoverCalories = Data.clampAmount(worker.caloriesOverflow)
    worker.carryoverHydration = Data.clampAmount(worker.hydrationOverflow)
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
    worker.inventoryProvisionWeight = Data.getInventoryLedgerWeight(worker.nutritionLedger)
    worker.inventoryEquipmentWeight = Data.getInventoryLedgerWeight(worker.toolLedger)
    worker.inventoryOutputWeight = Data.getInventoryLedgerWeight(worker.outputLedger)
    worker.inventoryUsedWeight = worker.inventoryProvisionWeight + worker.inventoryEquipmentWeight + worker.inventoryOutputWeight
    worker.inventoryMaxWeight = math.max(0, tonumber(worker.maxCarryWeight) or tonumber(worker.baseCarryWeight) or 0)
    worker.inventoryRemainingWeight = math.max(0, worker.inventoryMaxWeight - worker.inventoryUsedWeight)
    worker.dumpCooldownHours = math.max(0, tonumber(worker.dumpCooldownHours) or 0)
    worker.dumpTrips = math.max(0, tonumber(worker.dumpTrips) or 0)
    worker.gathererWaterCarryAmount = math.max(0, tonumber(worker.gathererWaterCarryAmount) or 0)
    worker.assignedToolTags = tags

    Data.applyGathererPresentation(worker)

    if DC_Buildings and DC_Buildings.ApplyWorkerState then
        DC_Buildings.ApplyWorkerState(worker, options)
    end
    if Energy and Energy.ApplyPresentationFields then
        Energy.ApplyPresentationFields(worker)
    end
end

return Data
