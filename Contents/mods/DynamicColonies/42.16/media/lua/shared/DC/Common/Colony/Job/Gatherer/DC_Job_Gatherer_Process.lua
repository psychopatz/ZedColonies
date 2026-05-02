local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy
local Resources = DC_Colony.Resources
local Gatherer = DC_Colony.Gatherer
local Skills = DC_Colony.Skills
local Interaction = DC_Colony.Interaction

local function clamp(value, minimum, maximum)
    local amount = tonumber(value) or 0
    if amount < minimum then
        return minimum
    end
    if amount > maximum then
        return maximum
    end
    return amount
end

local function randomRange(minValue, maxValue)
    if Config.RandomRangeInclusive then
        return Config.RandomRangeInclusive(minValue, maxValue)
    end

    local minNumber = math.floor(tonumber(minValue) or 1)
    local maxNumber = math.floor(tonumber(maxValue) or minNumber)
    if maxNumber < minNumber then
        minNumber, maxNumber = maxNumber, minNumber
    end
    return minNumber + ZombRand((maxNumber - minNumber) + 1)
end

local function chooseFullType(rule)
    local fullTypes = rule and rule.fullTypes or nil
    if type(fullTypes) == "table" and #fullTypes > 0 then
        return tostring(fullTypes[ZombRand(#fullTypes) + 1])
    end
    if rule and rule.fullType then
        return tostring(rule.fullType)
    end
    return nil
end

local function buildSkillEffects(skillID, worker)
    local entry = skillID and Skills and Skills.GetSkillEntry and Skills.GetSkillEntry(worker, skillID) or nil
    local level = math.max(0, math.floor(tonumber(entry and entry.level) or 0))
    return {
        skillID = skillID,
        skillLabel = skillID and Config.GetSkillDisplayName and Config.GetSkillDisplayName(skillID) or skillID,
        level = level,
        speedMultiplier = clamp(0.70 + (0.04 * level), 0.70, 1.50),
        yieldMultiplier = clamp(0.85 + (0.02 * level), 0.85, 1.25),
        botchChanceMultiplier = clamp(1.20 - (0.04 * level), 0.35, 1.20),
    }
end

local function getGathererPresenceState(worker)
    local states = Config.PresenceStates or {}
    local presenceState = tostring(worker and worker.presenceState or "")
    if presenceState == tostring(states.AwayToSite or "AwayToSite")
        or presenceState == tostring(states.Gathering or "Gathering")
        or presenceState == tostring(states.AwayToHome or "AwayToHome") then
        return presenceState
    end
    return tostring(states.Home or "Home")
end

local function getTravelHours()
    if Internal.getScavengeTravelHours then
        return Internal.getScavengeTravelHours()
    end
    return math.max(0, tonumber(Config.DEFAULT_SCAVENGE_TRAVEL_HOURS) or 0)
end

local function getPlaceLabel(worker)
    local label = Interaction and Interaction.GetPlaceLabel and Interaction.GetPlaceLabel(worker) or nil
    if label and tostring(label) ~= "" then
        return tostring(label)
    end
    return "nearby resources"
end

local function getSelectedResourceDefs(worker)
    return Gatherer and Gatherer.GetSelectedResourceList and Gatherer.GetSelectedResourceList(worker) or {}
end

local function getRunnableResources(worker, loadout)
    local resources = {}
    local baseSpeed = math.max(0.01, tonumber(worker and worker.baseWorkSpeedMultiplier) or 1)
    for _, def in ipairs(getSelectedResourceDefs(worker)) do
        local resourceState = loadout and loadout.resourceStates and loadout.resourceStates[def.id] or nil
        if resourceState and resourceState.runnable == true then
            local skillID = Gatherer.GetResourceSkillID and Gatherer.GetResourceSkillID(def.id) or tostring(def.skillID or "Plants")
            local skillEffects = buildSkillEffects(skillID, worker)
            local equipmentSpeed = math.max(0.01, tonumber(resourceState.speedMultiplier) or 1)
            resources[#resources + 1] = {
                def = def,
                state = resourceState,
                skillEffects = skillEffects,
                effectiveSpeed = baseSpeed * math.max(0.01, tonumber(skillEffects.speedMultiplier) or 1) * equipmentSpeed,
                weight = math.max(1, tonumber(def.weight) or 1),
            }
        end
    end
    return resources
end

local function getBlockingRequirement(loadout)
    for _, resourceID in ipairs(loadout and loadout.blockedResourceIDs or {}) do
        local state = loadout and loadout.resourceStates and loadout.resourceStates[resourceID] or nil
        if state and state.selected == true and state.blocked == true then
            return true
        end
    end
    return false
end

local function chooseRunnableResource(runnableResources)
    local totalWeight = 0
    for _, resource in ipairs(runnableResources or {}) do
        totalWeight = totalWeight + math.max(1, tonumber(resource.weight) or 1)
    end
    if totalWeight <= 0 then
        return runnableResources and runnableResources[1] or nil
    end

    local roll = ZombRand(totalWeight) + 1
    local cursor = 0
    for _, resource in ipairs(runnableResources or {}) do
        cursor = cursor + math.max(1, tonumber(resource.weight) or 1)
        if roll <= cursor then
            return resource
        end
    end

    return runnableResources and runnableResources[#runnableResources] or nil
end

local function getAverageEffectiveSpeed(runnableResources)
    local totalWeight = 0
    local totalSpeed = 0
    for _, resource in ipairs(runnableResources or {}) do
        local weight = math.max(1, tonumber(resource.weight) or 1)
        totalWeight = totalWeight + weight
        totalSpeed = totalSpeed + (math.max(0.01, tonumber(resource.effectiveSpeed) or 1) * weight)
    end
    if totalWeight <= 0 then
        return 0
    end
    return totalSpeed / totalWeight
end

local function scaleQuantity(rule, skillEffects)
    local qty = randomRange(rule and rule.minQty or 1, rule and rule.maxQty or 1)
    if DC_Colony.Output and DC_Colony.Output.applyQuantityMultiplier then
        qty = DC_Colony.Output.applyQuantityMultiplier(qty, skillEffects and skillEffects.yieldMultiplier or 1)
    end
    return math.max(0, math.floor(tonumber(qty) or 0))
end

local function buildResourceEntries(resourcePlan)
    local entries = {}
    local def = resourcePlan and resourcePlan.def or nil
    local skillEffects = resourcePlan and resourcePlan.skillEffects or nil
    if not def or tostring(def.id or "") == "water" then
        return entries
    end

    for _, rule in ipairs(def.outputRules or {}) do
        local fullType = chooseFullType(rule)
        local qty = fullType and scaleQuantity(rule, skillEffects) or 0
        if fullType and qty > 0 then
            entries[#entries + 1] = {
                fullType = fullType,
                qty = qty,
                gathererResourceID = def.id,
                gathererResourceLabel = def.label,
            }
        end
    end

    return entries
end

local function depositWaterToOwner(ownerUsername, amount, def)
    local requested = math.max(0, tonumber(amount) or 0)
    if requested <= 0 or not Resources then
        return 0
    end

    local accepted = Resources.AddWaterStored and Resources.AddWaterStored(ownerUsername, requested) or 0
    if accepted <= 0 then
        return 0
    end

    local stockpilePerQty = math.max(1, tonumber(def and def.waterPerQty) or 120)
    local stockpileUnits = math.floor(accepted / stockpilePerQty)
    if stockpileUnits > 0 and def and def.stockpileResource and rawget(_G, "DynamicTrading_Factions") then
        local factions = rawget(_G, "DynamicTrading_Factions")
        if factions.GetPlayerFaction and factions.ModifyStockpile then
            local ok, faction = pcall(factions.GetPlayerFaction, ownerUsername)
            if ok and type(faction) == "table" and faction.id then
                pcall(factions.ModifyStockpile, faction.id, def.stockpileResource, stockpileUnits * math.max(0, tonumber(def.stockpilePerQty) or 1))
            end
        end
    end

    return accepted
end

local function mirrorDynamicTradingStockpile(ownerUsername, def, qty)
    local resource = def and def.stockpileResource
    local perQty = math.max(0, tonumber(def and def.stockpilePerQty) or 0)
    if not resource or perQty <= 0 or qty <= 0 then
        return false
    end

    local factions = rawget(_G, "DynamicTrading_Factions")
    if not factions or not factions.GetPlayerFaction or not factions.ModifyStockpile then
        return false
    end

    local ok, faction = pcall(factions.GetPlayerFaction, ownerUsername)
    if not ok or type(faction) ~= "table" or not faction.id then
        return false
    end

    local modifyOk, modified = pcall(factions.ModifyStockpile, faction.id, resource, perQty * qty)
    return modifyOk and modified == true
end

local function getStoredActiveResourcePlan(worker, runnableResources)
    local activeID = tostring(worker and worker.gathererActiveResourceID or "")
    if activeID == "" then
        return nil
    end

    for _, resource in ipairs(runnableResources or {}) do
        if tostring(resource and resource.def and resource.def.id or "") == activeID then
            return resource
        end
    end

    return nil
end

local function chooseActiveResourcePlan(worker, runnableResources)
    if type(runnableResources) ~= "table" or #runnableResources <= 0 then
        return nil
    end

    local current = getStoredActiveResourcePlan(worker, runnableResources)
    if current then
        return current
    end

    return chooseRunnableResource(runnableResources)
end

local function markToolLedgerDirty(worker)
    local registryInternal = Registry and Registry.Internal or nil
    if registryInternal and registryInternal.MarkToolCacheDirty then
        registryInternal.MarkToolCacheDirty(worker)
    end
end

local function snapshotWaterContainers(worker, loadout)
    worker.gathererWaterBaseline = {}
    for _, container in ipairs(loadout and loadout.waterContainers or {}) do
        if tostring(container and container.entryID or "") ~= "" then
            worker.gathererWaterBaseline[tostring(container.entryID)] = math.max(0, tonumber(container.fluidAmount) or 0)
        end
    end
    worker.gathererWaterCarryAmount = 0
end

local function getContainerBaseline(worker, entryID, currentAmount)
    local baselineMap = type(worker and worker.gathererWaterBaseline) == "table" and worker.gathererWaterBaseline or nil
    local key = tostring(entryID or "")
    if not baselineMap or key == "" then
        return math.max(0, tonumber(currentAmount) or 0)
    end
    local stored = baselineMap[key]
    if stored == nil then
        stored = math.max(0, tonumber(currentAmount) or 0)
        baselineMap[key] = stored
    end
    return math.max(0, tonumber(stored) or 0)
end

local function recalculateWaterCarry(worker)
    local baselineMap = type(worker and worker.gathererWaterBaseline) == "table" and worker.gathererWaterBaseline or nil
    if not worker or not baselineMap then
        worker.gathererWaterCarryAmount = 0
        return 0
    end

    local total = 0
    for _, entry in ipairs(worker.toolLedger or {}) do
        local key = tostring(entry and entry.entryID or "")
        if key ~= "" and baselineMap[key] ~= nil then
            local currentAmount = math.max(0, tonumber(entry and entry.fluidAmount) or 0)
            local baseline = math.max(0, tonumber(baselineMap[key]) or 0)
            total = total + math.max(0, currentAmount - baseline)
        end
    end

    worker.gathererWaterCarryAmount = math.max(0, total)
    return worker.gathererWaterCarryAmount
end

local function fillWaterContainers(worker, loadout, amount)
    local remaining = math.max(0, tonumber(amount) or 0)
    if not worker or remaining <= 0 then
        return 0
    end

    local containerIDs = {}
    for _, container in ipairs(loadout and loadout.waterContainers or {}) do
        local key = tostring(container and container.entryID or "")
        if key ~= "" then
            containerIDs[key] = true
        end
    end

    if next(containerIDs) == nil then
        return 0
    end

    for _, entry in ipairs(worker.toolLedger or {}) do
        if remaining <= 0 then
            break
        end

        local entryID = tostring(entry and entry.entryID or "")
        if containerIDs[entryID] == true then
            local capacity = math.max(0, tonumber(entry and entry.fluidCapacity) or 0)
            local currentAmount = math.max(0, tonumber(entry and entry.fluidAmount) or 0)
            getContainerBaseline(worker, entryID, currentAmount)
            local freeCapacity = math.max(0, capacity - currentAmount)
            if freeCapacity > 0 then
                local fillAmount = math.max(0, math.min(remaining, freeCapacity))
                entry.fluidAmount = currentAmount + fillAmount
                remaining = remaining - fillAmount
            end
        end
    end

    local filled = math.max(0, tonumber(amount) or 0) - remaining
    if filled > 0 then
        recalculateWaterCarry(worker)
        markToolLedgerDirty(worker)
    end
    return filled
end

local function drainGatheredWaterFromContainers(worker, amount)
    local remaining = math.max(0, tonumber(amount) or 0)
    local baselineMap = type(worker and worker.gathererWaterBaseline) == "table" and worker.gathererWaterBaseline or nil
    if not worker or remaining <= 0 or not baselineMap then
        return 0
    end

    for index = #(worker.toolLedger or {}), 1, -1 do
        if remaining <= 0 then
            break
        end

        local entry = worker.toolLedger[index]
        local entryID = tostring(entry and entry.entryID or "")
        local baseline = baselineMap[entryID]
        if entryID ~= "" and baseline ~= nil then
            local currentAmount = math.max(0, tonumber(entry and entry.fluidAmount) or 0)
            local gatheredAmount = math.max(0, currentAmount - math.max(0, tonumber(baseline) or 0))
            if gatheredAmount > 0 then
                local drainedAmount = math.max(0, math.min(remaining, gatheredAmount))
                entry.fluidAmount = currentAmount - drainedAmount
                remaining = remaining - drainedAmount
            end
        end
    end

    local drained = math.max(0, tonumber(amount) or 0) - remaining
    if drained > 0 then
        recalculateWaterCarry(worker)
        markToolLedgerDirty(worker)
    end
    return drained
end

local function clearWaterContainerSnapshot(worker)
    if not worker then
        return
    end
    worker.gathererWaterBaseline = nil
    worker.gathererWaterCarryAmount = 0
end

local function depositWaterContainersToOwner(worker, currentHour, def, logBlocked)
    if not worker then
        return 0, 0
    end

    local carriedWater = recalculateWaterCarry(worker)
    if carriedWater <= 0 then
        clearWaterContainerSnapshot(worker)
        return 0, 0
    end

    local accepted = depositWaterToOwner(worker.ownerUsername, carriedWater, def)
    if accepted > 0 then
        drainGatheredWaterFromContainers(worker, accepted)
        Internal.appendWorkerLog(
            worker,
            "Returned home and stored " .. tostring(math.floor(accepted + 0.5)) .. " water.",
            currentHour,
            "output"
        )
    end

    local leftover = recalculateWaterCarry(worker)
    if leftover <= 0 then
        clearWaterContainerSnapshot(worker)
    elseif logBlocked == true then
        Internal.appendWorkerLog(
            worker,
            "Water storage is full. " .. tostring(math.floor(leftover + 0.5)) .. " water is still in carried containers.",
            currentHour,
            "warehouse"
        )
    end

    return accepted, leftover
end

local function startGathererOutbound(worker, currentHour)
    snapshotWaterContainers(worker, Gatherer.GetLoadout(worker))
    worker.presenceState = Config.PresenceStates.AwayToSite
    worker.travelHoursRemaining = getTravelHours()
    worker.returnReason = nil
    Internal.appendWorkerLog(worker, "Set out to gather " .. tostring(worker.gathererSelectionLabel or "resources") .. ".", currentHour, "travel")
end

local function beginGathererReturnHome(worker, currentHour, reason, travelHours)
    if not worker then
        return false
    end

    local presenceState = getGathererPresenceState(worker)
    if presenceState == Config.PresenceStates.Home or presenceState == Config.PresenceStates.AwayToHome then
        return false
    end

    if reason == Config.ReturnReasons.Manual then
        worker.jobEnabled = false
    end

    worker.presenceState = Config.PresenceStates.AwayToHome
    worker.travelHoursRemaining = math.max(0, tonumber(travelHours) or getTravelHours())
    worker.returnReason = reason or Config.ReturnReasons.Manual
    Internal.appendWorkerLog(
        worker,
        Internal.getReturnHomeMessage and Internal.getReturnHomeMessage(worker.returnReason) or "Heading home.",
        currentHour,
        "travel"
    )
    return true
end

local function completeGathererReturnHome(worker, currentHour)
    if not worker then
        return
    end

    worker.presenceState = Config.PresenceStates.Home
    worker.travelHoursRemaining = 0
    worker.dumpCooldownHours = 0

    if not Internal.isAutoRepeatEnabled(worker) then
        worker.jobEnabled = false
    end

    local waterDef = Gatherer and Gatherer.GetResource and Gatherer.GetResource("water") or nil
    local carriedWater = recalculateWaterCarry(worker)
    if carriedWater > 0 then
        local accepted, leftover = depositWaterContainersToOwner(worker, currentHour, waterDef, true)
        worker.gathererWaterCarryAmount = leftover
    else
        Internal.appendWorkerLog(worker, "Returned home from gathering.", currentHour, "travel")
    end
end

local function progressGathererTravel(worker, currentHour, deltaHours)
    if not worker or deltaHours <= 0 then
        return
    end

    local presenceState = getGathererPresenceState(worker)
    if presenceState ~= Config.PresenceStates.AwayToSite and presenceState ~= Config.PresenceStates.AwayToHome then
        return
    end

    worker.travelHoursRemaining = math.max(0, Internal.clampHours(worker.travelHoursRemaining) - deltaHours)
    if worker.travelHoursRemaining > 0 then
        return
    end

    if presenceState == Config.PresenceStates.AwayToSite then
        worker.presenceState = Config.PresenceStates.Gathering
        Internal.appendWorkerLog(worker, "Arrived at the gathering area.", currentHour, "travel")
        return
    end

    completeGathererReturnHome(worker, currentHour)
end

local function processWoodOrStoneCycle(worker, resourcePlan, currentHour)
    local entries = buildResourceEntries(resourcePlan)
    local storedQuantity = 0
    local blockedQuantity = 0

    for _, entry in ipairs(entries) do
        local requestedQty = math.max(1, tonumber(entry and entry.qty) or 1)
        local storedQty = Registry.AddOutputEntry(worker, entry)
        storedQuantity = storedQuantity + storedQty
        blockedQuantity = blockedQuantity + math.max(0, requestedQty - storedQty)
        if storedQty > 0 then
            mirrorDynamicTradingStockpile(worker.ownerUsername, resourcePlan.def, storedQty)
        end
    end

    Internal.logJobCycleOutcome(worker, currentHour, storedQuantity, getPlaceLabel(worker), entries)
    return storedQuantity, blockedQuantity
end

local function processWaterCycle(worker, resourcePlan, loadout, currentHour)
    local availableCapacity = math.max(0, tonumber(loadout and loadout.waterCollectableCapacity) or 0)
    if availableCapacity <= 0 then
        return 0, 0
    end

    local baseAmount = math.max(1, tonumber(resourcePlan and resourcePlan.def and resourcePlan.def.waterPerQty) or 120)
    local scaledAmount = math.max(1, math.floor((baseAmount * math.max(0.1, tonumber(resourcePlan.skillEffects and resourcePlan.skillEffects.yieldMultiplier) or 1)) + 0.5))
    local accepted = math.max(0, math.min(scaledAmount, availableCapacity))
    if accepted <= 0 then
        return 0, 0
    end

    accepted = fillWaterContainers(worker, loadout, accepted)
    if accepted <= 0 then
        return 0, 0
    end
    Internal.appendWorkerLog(
        worker,
        "Collected " .. tostring(math.floor(accepted + 0.5)) .. " water at " .. getPlaceLabel(worker) .. ".",
        currentHour,
        "output"
    )
    return accepted, 0
end

local function updateGathererPresentation(worker, selectedResource, loadout)
    worker.gathererSelectionLabel = Gatherer.GetSelectionLabel and Gatherer.GetSelectionLabel(worker) or worker.gathererSelectionLabel
    worker.gathererActiveResourceID = selectedResource and selectedResource.def and selectedResource.def.id or nil
    worker.gathererActiveResourceLabel = selectedResource and selectedResource.def and selectedResource.def.label or nil
    worker.gathererWaterContainerCount = loadout and loadout.waterContainerCount or worker.gathererWaterContainerCount
    worker.gathererWaterCapacity = loadout and loadout.waterCapacity or worker.gathererWaterCapacity
    worker.gathererWaterFreeCapacity = loadout and loadout.waterFreeCapacity or worker.gathererWaterFreeCapacity
    worker.gathererWaterStorageCapacity = loadout and loadout.waterStorageCapacity or worker.gathererWaterStorageCapacity
    worker.gathererWaterStorageStored = loadout and loadout.waterStorageStored or worker.gathererWaterStorageStored
    worker.gathererWaterStorageAvailable = loadout and loadout.waterStorageAvailable or worker.gathererWaterStorageAvailable
    worker.gathererWaterCollectableCapacity = loadout and loadout.waterCollectableCapacity or worker.gathererWaterCollectableCapacity
    if selectedResource and selectedResource.skillEffects then
        worker.jobSkillID = selectedResource.skillEffects.skillID
        worker.jobSkillLabel = selectedResource.skillEffects.skillLabel
        worker.jobSkillLevel = selectedResource.skillEffects.level
        worker.jobSkillSpeedMultiplier = selectedResource.skillEffects.speedMultiplier
        worker.jobSkillYieldMultiplier = selectedResource.skillEffects.yieldMultiplier
        worker.jobSkillBotchMultiplier = selectedResource.skillEffects.botchChanceMultiplier
    end
end

function Sim.ProcessGathererJob(worker, ctx)
    local currentHour = ctx.currentHour
    local profile = ctx.profile
    local normalizedJobType = ctx.normalizedJobType
    local hp = ctx.hp
    local hasCalories = ctx.hasCalories
    local hasHydration = ctx.hasHydration
    local forcedRest = ctx.forcedRest
    local workableHours = ctx.workableHours
    local deltaHours = ctx.deltaHours
    local lowEnergyReason = ctx.lowEnergyReason

    local totalCaloriesAvailable = 0
    local totalHydrationAvailable = 0
    if Internal.getAvailableProvisionTotals then
        totalCaloriesAvailable, totalHydrationAvailable = Internal.getAvailableProvisionTotals(worker)
    end
    local returnCaloriesThreshold = 0
    local returnHydrationThreshold = 0
    local outboundCaloriesThreshold = 0
    local outboundHydrationThreshold = 0
    if Internal.getRequiredTravelReserve then
        returnCaloriesThreshold, returnHydrationThreshold = Internal.getRequiredTravelReserve(worker, profile, 1)
        outboundCaloriesThreshold, outboundHydrationThreshold = Internal.getRequiredTravelReserve(worker, profile, 2)
    end

    if Internal.ensureWorkerHome then
        Internal.ensureWorkerHome(worker)
    end

    worker.gathererConfig = Gatherer.NormalizeConfig(worker)
    worker.gathererSelectionLabel = Gatherer.GetSelectionLabel(worker)
    local presenceState = getGathererPresenceState(worker)
    if presenceState == Config.PresenceStates.Home then
        depositWaterContainersToOwner(worker, currentHour, Gatherer and Gatherer.GetResource and Gatherer.GetResource("water") or nil, false)
    end

    presenceState = getGathererPresenceState(worker)
    local loadout = Gatherer.GetLoadout(worker)
    local runnableResources = getRunnableResources(worker, loadout)
    local blockingRequirement = getBlockingRequirement(loadout)
    local didGatherWork = false
    local totalQuantity = 0

    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, presenceState, hasCalories, hasHydration)
        return
    end

    if presenceState ~= Config.PresenceStates.Home and presenceState ~= Config.PresenceStates.AwayToHome then
        if totalHydrationAvailable < returnHydrationThreshold then
            beginGathererReturnHome(worker, currentHour, Config.ReturnReasons.LowDrink)
        elseif totalCaloriesAvailable < returnCaloriesThreshold then
            beginGathererReturnHome(worker, currentHour, Config.ReturnReasons.LowFood)
        elseif Energy.IsForcedRest(worker) then
            beginGathererReturnHome(worker, currentHour, lowEnergyReason)
        elseif #runnableResources <= 0 then
            beginGathererReturnHome(worker, currentHour, Config.ReturnReasons.MissingTool)
        end
    end

    presenceState = getGathererPresenceState(worker)

    if not worker.jobEnabled and presenceState ~= Config.PresenceStates.Home and presenceState ~= Config.PresenceStates.AwayToHome then
        beginGathererReturnHome(
            worker,
            currentHour,
            Config.ReturnReasons.Manual,
            presenceState == Config.PresenceStates.AwayToSite and worker.travelHoursRemaining or nil
        )
    end

    presenceState = getGathererPresenceState(worker)

    if worker.jobEnabled
        and presenceState == Config.PresenceStates.Home
        and math.max(0, tonumber(worker.gathererWaterCarryAmount) or 0) <= 0
        and #(worker.outputLedger or {}) <= 0
        and hasCalories
        and hasHydration
        and not forcedRest
        and #runnableResources > 0
        and totalCaloriesAvailable >= outboundCaloriesThreshold
        and totalHydrationAvailable >= outboundHydrationThreshold then
        startGathererOutbound(worker, currentHour)
    end

    presenceState = getGathererPresenceState(worker)

    if presenceState == Config.PresenceStates.AwayToSite or presenceState == Config.PresenceStates.AwayToHome then
        progressGathererTravel(worker, currentHour, deltaHours)
        presenceState = getGathererPresenceState(worker)
    end

    if presenceState == Config.PresenceStates.Gathering and worker.jobEnabled and hasCalories and hasHydration and not forcedRest then
        loadout = Gatherer.GetLoadout(worker)
        runnableResources = getRunnableResources(worker, loadout)
        local activeResourcePlan = chooseActiveResourcePlan(worker, runnableResources)
        updateGathererPresentation(worker, activeResourcePlan, loadout)
        local effectiveWorkPerHour = activeResourcePlan and math.max(0.01, tonumber(activeResourcePlan.effectiveSpeed) or 0) or 0
        worker.gathererEffectiveSpeedMultiplier = effectiveWorkPerHour
        if effectiveWorkPerHour > 0 and activeResourcePlan then
            worker.state = Config.States.Working
            worker.workProgress = Internal.clampHours(worker.workProgress) + (workableHours * effectiveWorkPerHour)
            didGatherWork = workableHours > 0
        end

        while worker.workProgress >= ctx.cycleHours do
            loadout = Gatherer.GetLoadout(worker)
            runnableResources = getRunnableResources(worker, loadout)
            if #runnableResources <= 0 then
                worker.workProgress = 0
                beginGathererReturnHome(worker, currentHour, Config.ReturnReasons.MissingTool)
                break
            end

            local resourcePlan = chooseActiveResourcePlan(worker, runnableResources)
            if not resourcePlan then
                break
            end

            worker.workProgress = worker.workProgress - ctx.cycleHours
            updateGathererPresentation(worker, resourcePlan, loadout)

            local cycleQuantity = 0
            local blockedQuantity = 0
            if tostring(resourcePlan.def and resourcePlan.def.id or "") == "water" then
                cycleQuantity, blockedQuantity = processWaterCycle(worker, resourcePlan, loadout, currentHour)
            else
                cycleQuantity, blockedQuantity = processWoodOrStoneCycle(worker, resourcePlan, currentHour)
            end

            totalQuantity = totalQuantity + cycleQuantity
            if cycleQuantity > 0 then
                Sim.grantWorkerJobXP(worker, currentHour, resourcePlan.skillEffects, cycleQuantity)
            end
            worker.gathererActiveResourceID = nil
            worker.gathererActiveResourceLabel = nil

            if blockedQuantity > 0 then
                Internal.appendWorkerLog(
                    worker,
                    "Inventory is full. " .. tostring(blockedQuantity) .. " gathered item" .. (blockedQuantity == 1 and "" or "s") .. " could not be carried.",
                    currentHour,
                    "inventory"
                )
                beginGathererReturnHome(worker, currentHour, Config.ReturnReasons.FullHaul)
                break
            end

            local waterCapacity = math.max(0, tonumber(loadout and loadout.waterCollectableCapacity) or 0)
            local waterCarry = math.max(0, tonumber(worker.gathererWaterCarryAmount) or 0)
            if tostring(resourcePlan.def and resourcePlan.def.id or "") == "water"
                and (waterCapacity <= 0 or waterCarry + 0.0001 >= math.max(0, tonumber(loadout and loadout.waterStorageAvailable) or 0)) then
                beginGathererReturnHome(worker, currentHour, Config.ReturnReasons.FullHaul)
                break
            end

            if Registry.GetInventoryRemainingCapacity(worker) <= 0 then
                beginGathererReturnHome(worker, currentHour, Config.ReturnReasons.FullHaul)
                break
            end
        end
    end

    presenceState = getGathererPresenceState(worker)
    worker.dumpCooldownHours = math.max(0, tonumber(worker.travelHoursRemaining) or 0)
    if Energy and deltaHours > 0 then
        if didGatherWork and workableHours > 0 then
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
            Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, presenceState == Config.PresenceStates.Home and "Too tired to keep gathering. Resting at home." or nil)
            if presenceState ~= Config.PresenceStates.Home and presenceState ~= Config.PresenceStates.AwayToHome then
                beginGathererReturnHome(worker, currentHour, lowEnergyReason)
            end
        end
        presenceState = getGathererPresenceState(worker)
        forcedRest = Energy.IsForcedRest(worker)
    end

    worker.gathererLastQuantity = totalQuantity
    loadout = Gatherer.GetLoadout(worker)
    runnableResources = getRunnableResources(worker, loadout)
    blockingRequirement = getBlockingRequirement(loadout)
    updateGathererPresentation(worker, chooseActiveResourcePlan(worker, runnableResources), loadout)
    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, presenceState, hasCalories, hasHydration)
    elseif not hasHydration then
        worker.state = Config.States.Dehydrated
    elseif not hasCalories then
        worker.state = Config.States.Starving
    elseif forcedRest and presenceState == Config.PresenceStates.Home then
        worker.state = Config.States.Resting
    elseif presenceState == Config.PresenceStates.Home
        and ((worker.outputLedger and #worker.outputLedger > 0) or math.max(0, tonumber(worker.gathererWaterCarryAmount) or 0) > 0) then
        worker.state = Config.States.StorageFull
    elseif presenceState == Config.PresenceStates.Home
        and worker.jobEnabled
        and (totalCaloriesAvailable < outboundCaloriesThreshold or totalHydrationAvailable < outboundHydrationThreshold) then
        worker.state = Config.States.WarehouseShortage
    elseif presenceState == Config.PresenceStates.Home
        and worker.jobEnabled
        and loadout
        and loadout.selectedResources
        and loadout.selectedResources.water == true
        and math.max(0, tonumber(loadout.waterStorageCapacity) or 0) <= 0
        and #runnableResources <= 0 then
        worker.state = Config.States.MissingSite
    elseif presenceState == Config.PresenceStates.Home
        and worker.jobEnabled
        and loadout
        and loadout.selectedResources
        and loadout.selectedResources.water == true
        and math.max(0, tonumber(loadout.waterStorageAvailable) or 0) <= 0
        and #runnableResources <= 0 then
        worker.state = Config.States.StorageFull
    elseif presenceState == Config.PresenceStates.Gathering and worker.jobEnabled and not forcedRest and #runnableResources > 0 then
        worker.state = Config.States.Working
    elseif presenceState == Config.PresenceStates.Home and worker.jobEnabled and #runnableResources <= 0 and blockingRequirement then
        worker.state = Config.States.MissingTool
    else
        worker.state = Config.States.Idle
    end
end

if DC_Colony.Config.JobProfiles and DC_Colony.Config.JobProfiles.Gatherer then
    DC_Colony.Config.JobProfiles.Gatherer.processHandler = Sim.ProcessGathererJob
end

return Sim
