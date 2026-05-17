DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Skills = DC_Colony.Skills
local Internal = Registry.Internal

local function copyShallow(source)
    local copied = {}
    for key, value in pairs(source or {}) do
        copied[key] = value
    end
    return copied
end

local function copyLedgerEntries(entries)
    local copied = {}
    for index, entry in ipairs(entries or {}) do
        copied[index] = Internal and Internal.CopyDeep and Internal.CopyDeep(entry) or entry
    end
    return copied
end

local function normalizeWarehouseLedgerMask(includeWarehouseLedgers)
    if includeWarehouseLedgers == true then
        return {
            provisions = true,
            equipment = true,
            output = true,
        }
    end

    if type(includeWarehouseLedgers) ~= "table" then
        return nil
    end

    local normalized = {}
    if includeWarehouseLedgers.provisions == true then
        normalized.provisions = true
    end
    if includeWarehouseLedgers.equipment == true then
        normalized.equipment = true
    end
    if includeWarehouseLedgers.output == true then
        normalized.output = true
    end

    for _key, _value in pairs(normalized) do
        return normalized
    end

    return nil
end

local function copyWarehouseDetail(warehouse, includeWarehouseLedgers)
    if type(warehouse) ~= "table" then
        return warehouse
    end

    local copied = Internal and Internal.CopyShallow and Internal.CopyShallow(warehouse) or copyShallow(warehouse)
    local ledgerMask = normalizeWarehouseLedgerMask(includeWarehouseLedgers)

    if not ledgerMask then
        copied.ledgers = nil
        return copied
    end

    local sourceLedgers = type(warehouse.ledgers) == "table" and warehouse.ledgers or {}
    copied.ledgers = {}
    if ledgerMask.provisions == true then
        copied.ledgers.provisions = copyLedgerEntries(sourceLedgers.provisions)
    end
    if ledgerMask.equipment == true then
        copied.ledgers.equipment = copyLedgerEntries(sourceLedgers.equipment)
    end
    if ledgerMask.output == true then
        copied.ledgers.output = copyLedgerEntries(sourceLedgers.output)
    end
    return copied
end

local function getCompanionMedicalSupplies(worker)
    local supplies = {}
    for _, entry in ipairs(worker and worker.nutritionLedger or {}) do
        local useKind = tostring(entry and entry.medicalUse or "")
        local units = math.max(0, math.floor((tonumber(entry and entry.treatmentUnitsRemaining) or 0) + 0.5))
        if Config.IsMedicalProvisionEntry
            and Config.IsMedicalProvisionEntry(entry)
            and units > 0
            and (useKind == "" or useKind == "bandage") then
            supplies[#supplies + 1] = {
                fullType = entry.fullType,
                displayName = entry.displayName,
                treatmentUnitsRemaining = units,
                medicalUse = useKind ~= "" and useKind or "bandage",
            }
        end
    end
    return supplies
end

function Registry.GetWorkerSummary(worker)
    local companionData = type(worker.companion) == "table" and worker.companion or {}
    local commanderUsername = tostring(companionData.commanderUsername or "")
    local commandInvalid = companionData.commandInvalidSinceMs ~= nil
    local profile = Config.GetJobProfile(worker.jobType)
    local workTarget = Config.GetEffectiveWorkTarget and Config.GetEffectiveWorkTarget(worker, profile)
        or (Config.GetEffectiveCycleHours and Config.GetEffectiveCycleHours(worker, profile))
        or (profile and profile.cycleHours)
        or 0
    local baseWorkSpeedMultiplier = Config.GetBaseWorkSpeedMultiplier and Config.GetBaseWorkSpeedMultiplier(worker, profile) or 1.0
    local jobSkillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, profile) or nil
    local skillSnapshot = Skills and Skills.BuildClientSkillSnapshotForWorker and Skills.BuildClientSkillSnapshotForWorker(worker) or nil
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    local warehouseSummary = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(worker.ownerUsername) or nil
    local resolvedJobSkillID = (jobSkillEffects and jobSkillEffects.skillID) or worker.jobSkillID
    local resolvedJobSkillLabel = (jobSkillEffects and jobSkillEffects.skillLabel) or worker.jobSkillLabel
    local resolvedJobSkillLevel = tonumber(jobSkillEffects and jobSkillEffects.level)
    if resolvedJobSkillLevel == nil then
        resolvedJobSkillLevel = tonumber(worker.jobSkillLevel)
    end
    local resolvedJobSkillSpeedMultiplier = tonumber(jobSkillEffects and jobSkillEffects.speedMultiplier)
    if resolvedJobSkillSpeedMultiplier == nil then
        resolvedJobSkillSpeedMultiplier = tonumber(worker.jobSkillSpeedMultiplier)
    end
    return {
        ownerUsername = worker.ownerUsername,
        workerID = worker.workerID,
        name = worker.name,
        profession = worker.profession,
        jobType = worker.jobType,
        archetypeID = Config.NormalizeArchetypeID(worker.archetypeID or worker.profession),
        state = worker.state,
        jobEnabled = worker.jobEnabled,
        presenceState = worker.presenceState,
        travelHoursRemaining = worker.travelHoursRemaining,
        returnReason = worker.returnReason,
        homeX = worker.homeX,
        homeY = worker.homeY,
        homeZ = worker.homeZ or 0,
        workX = worker.workX,
        workY = worker.workY,
        workZ = worker.workZ or 0,
        assignedSiteID = worker.assignedSiteID,
        toolState = worker.toolState,
        siteState = worker.siteState,
        deathCause = worker.deathCause,
        autoRepeatJob = worker.autoRepeatJob == true or worker.autoRepeatScavenge == true,
        autoRepeatScavenge = worker.autoRepeatJob == true or worker.autoRepeatScavenge == true,
        caloriesCached = worker.caloriesCached or 0,
        hydrationCached = worker.hydrationCached or 0,
        caloriesOverflow = worker.caloriesOverflow or 0,
        hydrationOverflow = worker.hydrationOverflow or 0,
        currentCaloriesBuffer = worker.currentCaloriesBuffer or worker.caloriesCached or 0,
        currentHydrationBuffer = worker.currentHydrationBuffer or worker.hydrationCached or 0,
        carryoverCalories = worker.carryoverCalories or worker.caloriesOverflow or 0,
        carryoverHydration = worker.carryoverHydration or worker.hydrationOverflow or 0,
        bufferCaloriesTotal = worker.bufferCaloriesTotal or worker.reserveCaloriesTotal or (worker.caloriesCached or 0),
        bufferHydrationTotal = worker.bufferHydrationTotal or worker.reserveHydrationTotal or (worker.hydrationCached or 0),
        provisionCaloriesReserve = worker.provisionCaloriesReserve or worker.storedCalories or 0,
        provisionHydrationReserve = worker.provisionHydrationReserve or worker.storedHydration or 0,
        combinedCaloriesTotal = worker.combinedCaloriesTotal or worker.totalCaloriesAvailable or (worker.caloriesCached or 0),
        combinedHydrationTotal = worker.combinedHydrationTotal or worker.totalHydrationAvailable or (worker.hydrationCached or 0),
        reserveCaloriesTotal = worker.reserveCaloriesTotal or (worker.caloriesCached or 0),
        reserveHydrationTotal = worker.reserveHydrationTotal or (worker.hydrationCached or 0),
        storedCalories = worker.storedCalories or 0,
        storedHydration = worker.storedHydration or 0,
        totalCaloriesAvailable = worker.totalCaloriesAvailable or (worker.caloriesCached or 0),
        totalHydrationAvailable = worker.totalHydrationAvailable or (worker.hydrationCached or 0),
        workProgress = worker.workProgress or 0,
        workTarget = worker.workTarget or workTarget,
        workCycleHours = worker.workCycleHours or worker.workTarget or workTarget,
        baseWorkSpeedMultiplier = worker.baseWorkSpeedMultiplier or baseWorkSpeedMultiplier,
        hp = worker.hp or worker.maxHp or 0,
        maxHp = worker.maxHp or Config.DEFAULT_WORKER_MAX_HP or 100,
        energy = worker.energy or worker.tiredness,
        energyCurrent = worker.energyCurrent or worker.tirednessCurrent or 0,
        energyMax = worker.energyMax or worker.tirednessMax or 0,
        energyRatio = worker.energyRatio or worker.tirednessRatio or 0,
        energyLowThreshold = worker.energyLowThreshold or worker.tirednessLowThreshold or 0,
        isRestingForEnergy = worker.isRestingForEnergy == true or worker.isRestingForTiredness == true,
        energyRecoveryMultiplier = worker.energyRecoveryMultiplier or worker.tirednessRecoveryMultiplier or 1,
        -- Compatibility
        tiredness = worker.energy or worker.tiredness,
        tirednessCurrent = worker.energyCurrent or worker.tirednessCurrent or 0,
        tirednessMax = worker.energyMax or worker.tirednessMax or 0,
        tirednessRatio = worker.energyRatio or worker.tirednessRatio or 0,
        tirednessLowThreshold = worker.energyLowThreshold or worker.tirednessLowThreshold or 0,
        isRestingForTiredness = worker.isRestingForEnergy == true or worker.isRestingForTiredness == true,
        tirednessRecoveryMultiplier = worker.energyRecoveryMultiplier or worker.tirednessRecoveryMultiplier or 1,
        outputCount = worker.outputCount or 0,
        moneyStored = worker.moneyStored or 0,
        reputation = tonumber(worker.reputation) or 100,
        scavengeTier = worker.scavengeTier,
        scavengeTierLabel = worker.scavengeTierLabel,
        scavengePoolRolls = worker.scavengePoolRolls,
        scavengeBonusRareRolls = worker.scavengeBonusRareRolls,
        scavengeFailureWeight = worker.scavengeFailureWeight,
        scavengeRareFinds = worker.scavengeRareFinds,
        scavengeBotchedRolls = worker.scavengeBotchedRolls,
        scavengeQualityCounts = worker.scavengeQualityCounts,
        scavengeSearchSpeedMultiplier = worker.scavengeSearchSpeedMultiplier,
        scavengeCapabilities = worker.scavengeCapabilities,
        scavengeSiteProfileID = worker.scavengeSiteProfileID,
        scavengeSiteProfileLabel = worker.scavengeSiteProfileLabel,
        scavengeSiteRoomName = worker.scavengeSiteRoomName,
        scavengeSiteZoneType = worker.scavengeSiteZoneType,
        gathererConfig = worker.gathererConfig,
        gathererSelectionLabel = worker.gathererSelectionLabel,
        gathererLastQuantity = worker.gathererLastQuantity,
        gathererActiveResourceID = worker.gathererActiveResourceID,
        gathererActiveResourceLabel = worker.gathererActiveResourceLabel,
        gathererHasAxe = worker.gathererHasAxe == true,
        gathererHasPickaxe = worker.gathererHasPickaxe == true,
        gathererHasSack = worker.gathererHasSack == true,
        gathererWaterCarryAmount = worker.gathererWaterCarryAmount or 0,
        gathererWaterContainerCount = worker.gathererWaterContainerCount or 0,
        gathererWaterCapacity = worker.gathererWaterCapacity or 0,
        gathererWaterFreeCapacity = worker.gathererWaterFreeCapacity or 0,
        gathererWaterStorageCapacity = worker.gathererWaterStorageCapacity or 0,
        gathererWaterStorageStored = worker.gathererWaterStorageStored or 0,
        gathererWaterStorageAvailable = worker.gathererWaterStorageAvailable or 0,
        gathererWaterCollectableCapacity = worker.gathererWaterCollectableCapacity or 0,
        gathererRunnableResourceCount = worker.gathererRunnableResourceCount or 0,
        gathererEffectiveSpeedMultiplier = worker.gathererEffectiveSpeedMultiplier or nil,
        haulCount = worker.haulCount,
        haulRawWeight = worker.haulRawWeight,
        haulEffectiveWeight = worker.haulEffectiveWeight,
        baseCarryWeight = worker.baseCarryWeight,
        effectiveCarryLimit = worker.effectiveCarryLimit,
        maxCarryWeight = worker.maxCarryWeight,
        rawCarryAllowance = worker.rawCarryAllowance,
        carryContainerCount = worker.carryContainerCount,
        dumpCooldownHours = worker.dumpCooldownHours,
        dumpTrips = worker.dumpTrips,
        outputWeight = worker.outputWeight,
        inventoryProvisionWeight = worker.inventoryProvisionWeight,
        inventoryEquipmentWeight = worker.inventoryEquipmentWeight,
        inventoryOutputWeight = worker.inventoryOutputWeight,
        inventoryUsedWeight = worker.inventoryUsedWeight,
        inventoryMaxWeight = worker.inventoryMaxWeight,
        inventoryRemainingWeight = worker.inventoryRemainingWeight,
        warehouseUsedWeight = warehouseSummary and warehouseSummary.usedWeight or 0,
        warehouseMaxWeight = warehouseSummary and warehouseSummary.maxWeight or 0,
        warehouseRemainingWeight = warehouseSummary and warehouseSummary.remainingWeight or 0,
        skills = skillSnapshot,
        skillModelVersion = worker.skillModelVersion,
        primarySkillID = Skills and Skills.GetPrimarySkillID and Skills.GetPrimarySkillID(worker) or nil,
        jobSkillID = resolvedJobSkillID,
        jobSkillLabel = resolvedJobSkillLabel,
        jobSkillLevel = math.max(0, math.floor(resolvedJobSkillLevel or 0)),
        jobSkillSpeedMultiplier = resolvedJobSkillSpeedMultiplier or 1,
        housingState = worker.housingState,
        housingBuildingID = worker.housingBuildingID,
        housingBuildingType = worker.housingBuildingType,
        housingBuildingLevel = worker.housingBuildingLevel,
        housingRecoveryMultiplier = worker.housingRecoveryMultiplier,
        infirmaryBuildingID = worker.infirmaryBuildingID,
        infirmaryBuildingType = worker.infirmaryBuildingType,
        infirmaryBuildingLevel = worker.infirmaryBuildingLevel,
        infirmaryBedAssigned = worker.infirmaryBedAssigned == true,
        doctorCovered = worker.doctorCovered == true,
        sleepHealingRate = worker.sleepHealingRate or 0,
        sleepHealingSource = worker.sleepHealingSource or "None",
        medicalSupplyBlocked = worker.medicalSupplyBlocked == true,
        selfTreatmentActive = worker.selfTreatmentActive == true,
        selfTreatmentTierID = worker.selfTreatmentTierID,
        selfTreatmentLabel = worker.selfTreatmentLabel,
        selfTreatmentItemFullType = worker.selfTreatmentItemFullType,
        selfTreatmentHealRemaining = worker.selfTreatmentHealRemaining or 0,
        selfTreatmentRegenPerHour = worker.selfTreatmentRegenPerHour or 0,
        assignedProjectID = worker.assignedProjectID,
        assignedProjectBuildingType = worker.assignedProjectBuildingType,
        assignedProjectBuildingID = worker.assignedProjectBuildingID,
        assignedProjectTargetLevel = worker.assignedProjectTargetLevel,
        assignedProjectMaterialState = worker.assignedProjectMaterialState,
        assignedProjectProgress = worker.assignedProjectProgress,
        assignedProjectRequired = worker.assignedProjectRequired,
        dcDutyMode = worker.dcDutyMode,
        dcCanFight = worker.dcCanFight == true,
        dcGuardPostIndex = worker.dcGuardPostIndex,
        dcAnchorRevision = worker.dcAnchorRevision,
        dcBehaviorState = worker.dcBehaviorState,
        companionCommanderUsername = commanderUsername ~= "" and commanderUsername or nil,
        companionCommandVersion = companionData.commandVersion,
        companionCommandInvalid = commandInvalid,
        companionCommandStatus = commandInvalid and "Commander invalid, returning soon"
            or (commanderUsername ~= "" and ("Commanded by " .. commanderUsername) or "No commander"),
        companionMedicalSupplies = getCompanionMedicalSupplies(worker),
        isFemale = worker.isFemale,
        identitySeed = worker.identitySeed
    }
end

function Registry.GetWorkerSummariesForOwner(ownerUsername)
    local summaries = {}
    for _, worker in ipairs(Registry.GetWorkersForOwner(ownerUsername)) do
        summaries[#summaries + 1] = Registry.GetWorkerSummary(worker)
    end
    return summaries
end

function Registry.GetWorkerDetailsForOwner(ownerUsername, workerID, includeWarehouseLedgers, includeWorkerLedgers)
    local worker = Registry.GetWorkerForOwner(ownerUsername, workerID)
    if not worker then return nil end
    Registry.RecalculateWorker(worker)
    local detail = Internal.CopyShallow(worker)
    local includeWorkerLedgerData = includeWorkerLedgers ~= false
    local workerLedgerMask = includeWorkerLedgerData == true and type(includeWorkerLedgers) == "table" and includeWorkerLedgers or nil

    if includeWorkerLedgerData and not workerLedgerMask then
        detail.nutritionLedger = copyLedgerEntries(worker.nutritionLedger)
        detail.toolLedger = copyLedgerEntries(worker.toolLedger)
        detail.haulLedger = copyLedgerEntries(worker.haulLedger)
        detail.outputLedger = copyLedgerEntries(worker.outputLedger)
    elseif includeWorkerLedgerData then
        detail.nutritionLedger = workerLedgerMask.nutrition == true and copyLedgerEntries(worker.nutritionLedger) or nil
        detail.toolLedger = workerLedgerMask.tool == true and copyLedgerEntries(worker.toolLedger) or nil
        detail.haulLedger = workerLedgerMask.haul == true and copyLedgerEntries(worker.haulLedger) or nil
        detail.outputLedger = workerLedgerMask.output == true and copyLedgerEntries(worker.outputLedger) or nil
    else
        detail.nutritionLedger = nil
        detail.toolLedger = nil
        detail.haulLedger = nil
        detail.outputLedger = nil
    end
    detail.activityLog = copyLedgerEntries(worker.activityLog)
    detail.statusFlags = Internal.CopyDeep and Internal.CopyDeep(worker.statusFlags) or worker.statusFlags
    detail.reputation = tonumber(worker.reputation) or 100
    detail.energy = Internal.CopyDeep and Internal.CopyDeep(worker.energy) or worker.energy
    detail.tiredness = Internal.CopyDeep and Internal.CopyDeep(worker.tiredness) or worker.tiredness
    detail.companion = Internal.CopyDeep and Internal.CopyDeep(worker.companion) or worker.companion
    detail.selfTreatmentState = Internal.CopyDeep and Internal.CopyDeep(worker.selfTreatmentState) or worker.selfTreatmentState
    detail.warehouse = copyWarehouseDetail(worker.warehouse, includeWarehouseLedgers)
    if Skills and Skills.BuildClientSkillSnapshotForWorker then
        detail.skills = Skills.BuildClientSkillSnapshotForWorker(worker)
        detail.primarySkillID = Skills.GetPrimarySkillID and Skills.GetPrimarySkillID(worker) or nil
        detail.jobSkillEffects = Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker) or nil
    end
    return detail
end

return Registry
