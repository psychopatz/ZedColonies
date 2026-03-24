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

local function isSleepEligible(worker, forcedRest)
    return worker
        and tostring(worker.presenceState or "") == tostring((Config.PresenceStates or {}).Home or "Home")
        and forcedRest == true
        and math.max(0, tonumber(worker.hp) or 0) > 0
end

local function getOwnerMedicalPlan(ownerUsername)
    local plans = Internal.ownerMedicalPlans or {}
    return plans[getOwnerKey(ownerUsername)]
end

local function buildOwnerMedicalPlan(ownerUsername)
    local buildings = getBuildings()
    local infirmary = buildings and buildings.BuildInfirmaryAssignment and buildings.BuildInfirmaryAssignment(ownerUsername) or nil
    if not infirmary then
        infirmary = {
            assignments = {},
            doctorCoveredWorkerIDs = {},
            doctorCoveredCount = 0,
            doctorCount = 0,
            treatmentHourBudget = 0
        }
    end

    local plan = {
        ownerUsername = getOwnerKey(ownerUsername),
        infirmary = infirmary,
        priorityIndex = {},
        remainingTreatmentHours = math.max(0, tonumber(infirmary.treatmentHourBudget) or 0),
        initialTreatmentHours = math.max(0, tonumber(infirmary.treatmentHourBudget) or 0),
        usedTreatmentHours = 0,
        coveredPatientCount = math.max(0, tonumber(infirmary.doctorCoveredCount) or 0),
        doctorCount = math.max(0, tonumber(infirmary.doctorCount) or 0),
    }

    for index, workerID in ipairs(infirmary.doctorCoveredWorkerIDs or {}) do
        plan.priorityIndex[tostring(workerID or "")] = index
    end

    return plan
end

local function buildAllOwnerMedicalPlans(data)
    local plans = {}
    local seenOwners = {}

    for _, worker in pairs(data.Workers or {}) do
        local ownerKey = getOwnerKey(worker and worker.ownerUsername)
        if ownerKey ~= "" and not seenOwners[ownerKey] then
            seenOwners[ownerKey] = true
            plans[ownerKey] = buildOwnerMedicalPlan(ownerKey)
        end
    end

    return plans
end

local function getWorkerMedicalAssignment(worker)
    local plan = getOwnerMedicalPlan(worker and worker.ownerUsername)
    local infirmary = plan and plan.infirmary or nil
    local assignments = infirmary and infirmary.assignments or {}
    return assignments[tostring(worker and worker.workerID or "")]
end

local function applySleepHealing(worker, forcedRest, nutritionResult)
    local baseRate = 0.25
    local treatedRate = 1.00
    local supportedHours = math.max(0, tonumber(nutritionResult and nutritionResult.supportedHours) or 0)
    local maxHp = math.max(1, tonumber(worker and worker.maxHp) or Config.DEFAULT_WORKER_MAX_HP or 100)
    local hp = Internal.clampHp(worker and worker.hp, maxHp)
    local sleepEligible = isSleepEligible(worker, forcedRest)
    local assignment = getWorkerMedicalAssignment(worker) or {}
    local plan = getOwnerMedicalPlan(worker and worker.ownerUsername)
    local boostedHours = 0
    local healingAmount = 0

    worker.sleepHealingRate = 0
    worker.sleepHealingSource = "None"
    worker.medicalSupplyBlocked = false

    if not sleepEligible or supportedHours <= 0 or hp <= 0 then
        return hp, 0, 0
    end

    healingAmount = supportedHours * baseRate
    if assignment.assigned == true and assignment.doctorCovered == true and plan and (plan.remainingTreatmentHours or 0) > 0 then
        boostedHours = math.min(supportedHours, math.max(0, tonumber(plan.remainingTreatmentHours) or 0))
        plan.remainingTreatmentHours = math.max(0, (tonumber(plan.remainingTreatmentHours) or 0) - boostedHours)
        plan.usedTreatmentHours = math.max(0, tonumber(plan.usedTreatmentHours) or 0) + boostedHours
        healingAmount = healingAmount + (boostedHours * (treatedRate - baseRate))
    end

    hp = Internal.clampHp(hp + healingAmount, maxHp)
    worker.hp = hp
    worker.sleepHealingRate = supportedHours > 0 and (healingAmount / supportedHours) or 0

    if boostedHours > 0 then
        worker.sleepHealingSource = "InfirmaryDoctor"
    elseif assignment.assigned == true then
        worker.sleepHealingSource = "Infirmary"
    else
        worker.sleepHealingSource = "HomeSleep"
    end

    if assignment.assigned == true and assignment.doctorCovered == true and boostedHours < supportedHours then
        worker.medicalSupplyBlocked = true
    end

    return hp, supportedHours, boostedHours
end

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
    local nutritionResult = Internal.processNutrition(
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
    local hp = Internal.clampHp(nutritionResult and nutritionResult.hp, math.max(1, tonumber(worker.maxHp) or Config.DEFAULT_WORKER_MAX_HP or 100))

    hp = select(1, applySleepHealing(worker, forcedRest, nutritionResult))

    worker.starvationHours = 0
    worker.dehydrationHours = 0

    if normalizedJobType == Config.JobTypes.Scavenge then
        local totalCaloriesAvailable, totalHydrationAvailable = Internal.getAvailableProvisionTotals(worker)
        local returnCaloriesThreshold, returnHydrationThreshold = Internal.getRequiredTravelReserve(worker, profile, 1)
        local outboundCaloriesThreshold, outboundHydrationThreshold = Internal.getRequiredTravelReserve(worker, profile, 2)
        local presenceState = Internal.getScavengePresenceState(worker)
        local didScavengeWork = false

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
                    worker.scavengeBonusRareRolls = scavengeRun.bonusRareRolls or 0
                    worker.scavengeRareFinds = scavengeRun.rareFinds or 0
                    worker.scavengeBotchedRolls = scavengeRun.botchedRolls or 0
                    worker.scavengeQualityCounts = scavengeRun.qualityCounts or nil
                    for _, entry in ipairs(scavengeRun.entries or {}) do
                        Registry.AddHaulEntry(worker, entry)
                    end
                    Internal.logJobCycleOutcome(worker, currentHour, scavengeRun.totalQuantity, Internal.getScavengeLocationLabel(worker, scavengeRun), scavengeRun.entries)
                    if scavengeRun.success then
                        grantWorkerJobXP(worker, currentHour, scavengeRun.skillEffects or jobSkillEffects, scavengeRun.totalQuantity)
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
    elseif isBuilderJob then
        worker.scavengeBonusRareRolls = nil
        worker.scavengeRareFinds = nil
        worker.scavengeBotchedRolls = nil
        worker.scavengeQualityCounts = nil

        local projectState = DC_Buildings and DC_Buildings.GetProjectDisplayState and DC_Buildings.GetProjectDisplayState(worker.ownerUsername, worker.workerID) or {
            hasProject = false,
            label = "No Project"
        }
        if projectState.hasProject and DC_Buildings and DC_Buildings.RefreshOwnerProjectMaterials then
            DC_Buildings.RefreshOwnerProjectMaterials(worker.ownerUsername)
            projectState = DC_Buildings.GetProjectDisplayState(worker.ownerUsername, worker.workerID) or projectState
        end
        local didWorkThisTick = false
        local buildResult = nil
        local waitingForProjectMaterials = false

        if hp <= 0 then
            Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
        elseif worker.jobEnabled and toolsReady and hasHydration and hasCalories and not forcedRest and projectState.hasProject then
            worker.state = Config.States.Working
            buildResult = DC_Buildings
                and DC_Buildings.ProcessWorkerProject
                and DC_Buildings.ProcessWorkerProject(worker, currentHour, workableHours, speedMultiplier)
                or nil
            didWorkThisTick = buildResult and buildResult.didWork == true or false
            waitingForProjectMaterials = buildResult and buildResult.waitingForMaterials == true or false
            if buildResult and buildResult.completed and buildResult.project then
                local xpResult = buildResult.xpResult or nil
                local xpText = ""
                if xpResult and (tonumber(xpResult.granted) or 0) > 0 then
                    xpText = " Earned "
                        .. tostring(math.floor((tonumber(xpResult.granted) or 0) + 0.5))
                        .. " Construction XP."
                    if (tonumber(xpResult.leveledUp) or 0) > 0 then
                        xpText = xpText
                            .. " Construction increased to level "
                            .. tostring(xpResult.newLevel or 0)
                            .. "."
                    end
                end
                Internal.appendWorkerLog(
                    worker,
                    tostring(buildResult.project.buildingType or "Building")
                        .. " reached level "
                        .. tostring(buildResult.project.targetLevel or 1)
                        .. "."
                        .. xpText,
                    currentHour,
                    "buildings"
                )
            end
        end

        if Energy and deltaHours > 0 and hp > 0 then
            if didWorkThisTick and workableHours > 0 then
                Energy.ApplyWorkDrain(worker, workableHours, profile)
            else
                Energy.ApplyHomeRecovery(worker, deltaHours, profile)
            end

            forcedRest = Energy.IsForcedRest(worker)
            if forcedRest then
                Energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
            elseif Energy.IsDepleted(worker) then
                forcedRest = true
                Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to keep building. Resting at home.")
            end
            forcedRest = Energy.IsForcedRest(worker)
        end

        if hp <= 0 then
            Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
        elseif not worker.jobEnabled then
            worker.state = Config.States.Idle
        elseif not toolsReady then
            worker.state = Config.States.MissingTool
        elseif not hasHydration then
            worker.state = Config.States.Dehydrated
        elseif not hasCalories then
            worker.state = Config.States.Starving
        elseif forcedRest then
            worker.state = Config.States.Resting
        elseif waitingForProjectMaterials then
            worker.state = Config.States.WarehouseShortage
        elseif projectState.hasProject then
            worker.state = Config.States.Working
        else
            worker.state = Config.States.Idle
        end
    elseif isDoctorJob then
        worker.scavengeBonusRareRolls = nil
        worker.scavengeRareFinds = nil
        worker.scavengeBotchedRolls = nil
        worker.scavengeQualityCounts = nil

        local medicalPlan = getOwnerMedicalPlan(worker.ownerUsername)
        local coveredPatientCount = medicalPlan and math.max(0, tonumber(medicalPlan.coveredPatientCount) or 0) or 0
        local doctorCount = medicalPlan and math.max(1, tonumber(medicalPlan.doctorCount) or 1) or 1
        local hasTreatmentDemand = coveredPatientCount > 0
        local hasTreatmentSupplies = medicalPlan and (tonumber(medicalPlan.initialTreatmentHours) or 0) > 0 or false
        local doctorLoadRatio = hasTreatmentDemand and math.min(1, coveredPatientCount / math.max(1, doctorCount * 5)) or 0
        local doctorWorkHours = supportedHours * doctorLoadRatio
        local didWorkThisTick = false

        if hp <= 0 then
            Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
        elseif worker.jobEnabled and toolsReady and hasHydration and hasCalories and not forcedRest and hasTreatmentDemand and hasTreatmentSupplies then
            worker.state = Config.States.Working
            worker.workProgress = Internal.clampHours(worker.workProgress) + (doctorWorkHours * speedMultiplier)
            while worker.workProgress >= cycleHours do
                worker.workProgress = worker.workProgress - cycleHours
            end
            didWorkThisTick = doctorWorkHours > 0
        end

        if Energy and deltaHours > 0 and hp > 0 then
            if didWorkThisTick and doctorWorkHours > 0 then
                Energy.ApplyWorkDrain(worker, doctorWorkHours, profile)
            else
                Energy.ApplyHomeRecovery(worker, deltaHours, profile)
            end

            forcedRest = Energy.IsForcedRest(worker)
            if forcedRest then
                Energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
            elseif Energy.IsDepleted(worker) then
                forcedRest = true
                Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to keep treating patients. Resting at home.")
            end
            forcedRest = Energy.IsForcedRest(worker)
        end

        if hp <= 0 then
            Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
        elseif not worker.jobEnabled then
            worker.state = Config.States.Idle
        elseif not toolsReady then
            worker.state = Config.States.MissingTool
        elseif not hasHydration then
            worker.state = Config.States.Dehydrated
        elseif not hasCalories then
            worker.state = Config.States.Starving
        elseif forcedRest then
            worker.state = Config.States.Resting
        elseif not hasTreatmentDemand then
            worker.state = Config.States.Idle
        elseif not hasTreatmentSupplies then
            worker.state = Config.States.WarehouseShortage
        else
            worker.state = Config.States.Working
        end
    else
        worker.scavengeBonusRareRolls = nil
        worker.scavengeRareFinds = nil
        worker.scavengeBotchedRolls = nil
        worker.scavengeQualityCounts = nil
        local didWorkThisTick = false
        if hp <= 0 then
            Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
        elseif worker.jobEnabled and toolsReady and hasHydration and hasCalories and not forcedRest then
            worker.state = Config.States.Working
            worker.workProgress = Internal.clampHours(worker.workProgress) + (workableHours * speedMultiplier)
            didWorkThisTick = workableHours > 0
            while worker.workProgress >= cycleHours do
                worker.workProgress = worker.workProgress - cycleHours
                local jobResult = Output.GenerateForJob(profile, worker)
                local warehouseBlocked = 0
                for _, entry in ipairs(jobResult.entries or {}) do
                    local movedQty, leftoverQty = Warehouse.DepositHaulEntry(worker.ownerUsername, entry)
                    warehouseBlocked = warehouseBlocked + leftoverQty
                    if leftoverQty > 0 then
                        Registry.AddOutputEntry(worker, {
                            fullType = entry.fullType,
                            qty = leftoverQty
                        })
                    end
                end
                Internal.logJobCycleOutcome(worker, currentHour, jobResult.totalQuantity, Interaction.GetPlaceLabel(worker), jobResult.entries)
                if jobResult.success then
                    grantWorkerJobXP(worker, currentHour, jobResult.skillEffects or jobSkillEffects, jobResult.totalQuantity)
                elseif jobResult.failed and jobResult.failureReason then
                    Internal.appendWorkerLog(worker, tostring(jobResult.failureReason), currentHour, "output")
                end
                if warehouseBlocked > 0 then
                    Internal.appendWorkerLog(
                        worker,
                        "Warehouse is full. " .. tostring(warehouseBlocked) .. " produced item" .. (warehouseBlocked == 1 and "" or "s") .. " could not be stored.",
                        currentHour,
                        "warehouse"
                    )
                    worker.state = Config.States.StorageFull
                    break
                end
            end
        end

        if Energy and deltaHours > 0 and hp > 0 then
            if didWorkThisTick and workableHours > 0 then
                Energy.ApplyWorkDrain(worker, workableHours, profile)
            else
                Energy.ApplyHomeRecovery(worker, deltaHours, profile)
            end

            forcedRest = Energy.IsForcedRest(worker)
            if forcedRest then
                Energy.CompleteForcedRest(worker, currentHour, "Fully rested again.")
            elseif Energy.IsDepleted(worker) then
                forcedRest = true
                Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to keep working. Resting at home.")
            end
            forcedRest = Energy.IsForcedRest(worker)
        end

        if hp <= 0 then
            Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
        elseif not worker.jobEnabled then
            worker.state = Config.States.Idle
        elseif not toolsReady then
            worker.state = Config.States.MissingTool
        elseif not hasHydration then
            worker.state = Config.States.Dehydrated
        elseif not hasCalories then
            worker.state = Config.States.Starving
        elseif forcedRest then
            worker.state = Config.States.Resting
        elseif worker.state ~= Config.States.StorageFull then
            worker.state = Config.States.Working
        end
    end

    if deltaHours > 0 then
        worker.lastSimHour = currentHour
    end
    Registry.RecalculateWorker(worker)
end

function Sim.ProcessAllWorkers(currentHour)
    currentHour = currentHour or (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()
    local data = Registry.GetData()
    Internal.ownerMedicalPlans = buildAllOwnerMedicalPlans(data)

    local orderedWorkers = {}
    for _, worker in pairs(data.Workers or {}) do
        orderedWorkers[#orderedWorkers + 1] = worker
    end

    table.sort(orderedWorkers, function(a, b)
        local ownerA = getOwnerKey(a and a.ownerUsername)
        local ownerB = getOwnerKey(b and b.ownerUsername)
        if ownerA ~= ownerB then
            return ownerA < ownerB
        end

        local planA = Internal.ownerMedicalPlans and Internal.ownerMedicalPlans[ownerA] or nil
        local planB = Internal.ownerMedicalPlans and Internal.ownerMedicalPlans[ownerB] or nil
        local priorityA = planA and planA.priorityIndex and planA.priorityIndex[tostring(a and a.workerID or "")] or 1000000
        local priorityB = planB and planB.priorityIndex and planB.priorityIndex[tostring(b and b.workerID or "")] or 1000000
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

    for ownerUsername, plan in pairs(Internal.ownerMedicalPlans or {}) do
        local usedHours = math.max(0, tonumber(plan and plan.usedTreatmentHours) or 0)
        if usedHours > 0 and Warehouse and Warehouse.ConsumeMedicalProvisionHours then
            Warehouse.ConsumeMedicalProvisionHours(ownerUsername, usedHours)
        end
    end

    Internal.ownerMedicalPlans = nil
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
