DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Skills = DC_Colony.Skills

function Registry.GetWorkerSummary(worker)
    local profile = Config.GetJobProfile(worker.jobType)
    local workTarget = Config.GetEffectiveWorkTarget and Config.GetEffectiveWorkTarget(worker, profile)
        or (Config.GetEffectiveCycleHours and Config.GetEffectiveCycleHours(worker, profile))
        or (profile and profile.cycleHours)
        or 0
    local baseWorkSpeedMultiplier = Config.GetBaseWorkSpeedMultiplier and Config.GetBaseWorkSpeedMultiplier(worker, profile) or 1.0
    local jobSkillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, profile) or nil
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    local warehouseSummary = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(worker.ownerUsername) or nil
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
        primarySkillID = Skills and Skills.GetPrimarySkillID and Skills.GetPrimarySkillID(worker) or nil,
        jobSkillID = jobSkillEffects and jobSkillEffects.skillID or nil,
        jobSkillLabel = jobSkillEffects and jobSkillEffects.skillLabel or nil,
        jobSkillLevel = jobSkillEffects and jobSkillEffects.level or 0,
        jobSkillSpeedMultiplier = jobSkillEffects and jobSkillEffects.speedMultiplier or 1,
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
    local detail = Registry.Internal.CopyShallow(worker)
    local includeWorkerLedgerData = includeWorkerLedgers ~= false
    if Skills and Skills.BuildClientSkillSnapshotForWorker then
        detail.skills = Skills.BuildClientSkillSnapshotForWorker(worker)
        detail.primarySkillID = Skills.GetPrimarySkillID and Skills.GetPrimarySkillID(worker) or nil
        detail.jobSkillEffects = Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker) or nil
    end
    if not includeWorkerLedgerData then
        detail.nutritionLedger = nil
        detail.toolLedger = nil
        detail.haulLedger = nil
        detail.outputLedger = nil
    end
    return detail
end

return Registry
