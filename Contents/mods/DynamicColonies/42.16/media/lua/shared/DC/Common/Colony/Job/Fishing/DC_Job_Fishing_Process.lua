local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Interaction = DC_Colony.Interaction
local Sim = DC_Colony.Sim
local Internal = Sim.Internal
local Energy = DC_Colony.Energy
local Skills = DC_Colony.Skills

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

local function rollChance(chance)
    local safeChance = clamp(chance, 0, 0.99)
    if safeChance <= 0 then
        return false
    end

    local scaled = math.max(1, math.floor((safeChance * 10000) + 0.5))
    return (ZombRand(10000) + 1) <= scaled
end

local function appendWeightedEntries(target, entries, copies)
    for _ = 1, math.max(1, math.floor(tonumber(copies) or 1)) do
        for _, fullType in ipairs(entries or {}) do
            target[#target + 1] = fullType
        end
    end
end

local function buildCatchPoolForTier(tier)
    local pool = {}
    appendWeightedEntries(pool, (Config.FishingCatchPools or {})[1], 1)
    if tier >= 2 then
        appendWeightedEntries(pool, (Config.FishingCatchPools or {})[2], 2)
    end
    if tier >= 3 then
        appendWeightedEntries(pool, (Config.FishingCatchPools or {})[3], 4)
    end
    return pool
end

local function buildFishingResult(worker, loadout, skillEffects)
    local result = {
        entries = {},
        totalQuantity = 0,
        success = false,
        failed = false,
        failureReason = nil,
        skillEffects = skillEffects,
    }

    local tier = math.max(0, tonumber(loadout and loadout.tier) or 0)
    if tier <= 0 then
        result.failed = true
        result.failureReason = "Fishing gear is not ready."
        return result
    end

    local baseFailureChance = ((Config.FishingFailureChanceByTier or {})[tier]) or 0.28
    local failureChance = clamp(
        baseFailureChance + (tonumber(loadout and loadout.failureChanceModifier) or 0),
        0.01,
        0.95
    )
    if rollChance(failureChance * clamp(skillEffects and skillEffects.botchChanceMultiplier, 0.2, 2.0)) then
        result.failed = true
        result.failureReason = "No catch this cycle."
        return result
    end

    local pool = buildCatchPoolForTier(tier)
    if #pool <= 0 then
        result.failed = true
        result.failureReason = "No catch this cycle."
        return result
    end

    local fullType = pool[ZombRand(#pool) + 1]
    local qty = 1
    if DC_Colony.Output and DC_Colony.Output.applyQuantityMultiplier then
        qty = DC_Colony.Output.applyQuantityMultiplier(qty, skillEffects and skillEffects.yieldMultiplier or 1)
    end

    result.entries[#result.entries + 1] = {
        fullType = fullType,
        qty = qty,
    }
    result.totalQuantity = qty
    result.success = true
    return result
end

local function grantMaintenanceRollXP(worker)
    if not worker or not Skills or not Skills.GrantXP then
        return
    end

    Skills.GrantXP(worker, "Maintenance", 1)
end

local function persistNormalizedEntry(worker, index, normalized)
    if not worker or not index then
        return false
    end

    if normalized then
        worker.toolLedger[index] = normalized
    end
    Registry.Internal.MarkToolCacheDirty(worker)
    return true
end

local function consumeBaitEntry(worker, index, entry, currentHour)
    local normalized = Registry.Internal.NormalizeEquipmentEntry and Registry.Internal.NormalizeEquipmentEntry(entry) or nil
    if not normalized then
        return false
    end

    local consumedDisplayName = tostring(normalized.displayName or normalized.fullType or "Fishing bait")

    if normalized.isDrainable == true and (tonumber(normalized.useDelta) or 0) > 0 then
        normalized.usedDelta = math.max(0, (tonumber(normalized.usedDelta) or 0) - (tonumber(normalized.useDelta) or 0))
        if Registry.Internal.IsEquipmentEntryUsable and Registry.Internal.IsEquipmentEntryUsable(normalized) then
            persistNormalizedEntry(worker, index, normalized)
        else
            Sim.ConsumeToolEntry(worker, index)
        end
    else
        Sim.ConsumeToolEntry(worker, index)
    end

    Internal.appendWorkerLog(
        worker,
        consumedDisplayName .. " was consumed while fishing.",
        currentHour,
        "output"
    )
    return true
end

local function applyBaitConsumption(worker, loadout, currentHour)
    if not (loadout and loadout.baitApplies and loadout.baitIndex and loadout.baitEntry) then
        return false
    end

    grantMaintenanceRollXP(worker)
    local consumeChance = Config.GetFishingBaitConsumeChance and Config.GetFishingBaitConsumeChance(worker) or 0.30
    if not rollChance(consumeChance) then
        return false
    end

    return consumeBaitEntry(worker, loadout.baitIndex, loadout.baitEntry, currentHour)
end

local function applyLineAndTackleWear(worker, loadout, currentHour)
    if not loadout then
        return
    end

    if loadout.lineIndex and rollChance(0.50) then
        Sim.ApplyWearToToolEntry(worker, loadout.lineIndex, currentHour, 1)
    end

    local refreshed = Config.GetFishingLoadout and Config.GetFishingLoadout(worker) or loadout
    if refreshed.tackleIndex and rollChance(0.50) then
        Sim.ApplyWearToToolEntry(worker, refreshed.tackleIndex, currentHour, 1)
    end
end

local function applySuccessfulFishingWear(worker, currentHour)
    local refreshed = Config.GetFishingLoadout and Config.GetFishingLoadout(worker) or nil
    if not refreshed then
        return
    end

    local activeToolIndex = refreshed.tier >= 2 and refreshed.rodIndex or refreshed.activeToolIndex
    if activeToolIndex then
        Sim.ApplyWearToToolEntry(worker, activeToolIndex, currentHour, 1)
    end

    applyLineAndTackleWear(worker, refreshed, currentHour)
end

local function addFishingOutput(worker, entries)
    local blocked = 0
    for _, entry in ipairs(entries or {}) do
        local requestedQty = math.max(1, tonumber(entry and entry.qty) or 1)
        local storedQty = Registry.AddOutputEntry(worker, entry)
        blocked = blocked + math.max(0, requestedQty - storedQty)
    end
    return blocked
end

function Sim.ProcessFishingJob(worker, ctx)
    local currentHour = ctx.currentHour
    local profile = ctx.profile
    local normalizedJobType = ctx.normalizedJobType
    local baseSpeedMultiplier = ctx.speedMultiplier
    local cycleHours = ctx.cycleHours
    local toolsReady = ctx.toolsReady
    local hp = ctx.hp
    local hasCalories = ctx.hasCalories
    local hasHydration = ctx.hasHydration
    local forcedRest = ctx.forcedRest
    local workableHours = ctx.workableHours
    local deltaHours = ctx.deltaHours
    local lowEnergyReason = ctx.lowEnergyReason
    local jobSkillEffects = ctx.jobSkillEffects

    local loadout = Config.GetFishingLoadout and Config.GetFishingLoadout(worker) or nil
    local baseWorkPerHour = math.max(
        0.01,
        tonumber(Config.GetFishingBaseWorkPerHour and Config.GetFishingBaseWorkPerHour())
            or 1
    )
    local finalSpeedMultiplier = baseSpeedMultiplier
    if loadout and loadout.baitApplies then
        finalSpeedMultiplier = finalSpeedMultiplier * math.max(1.0, tonumber(loadout.baitSpeedMultiplier) or 1.0)
    end
    local effectiveWorkPerHour = baseWorkPerHour * finalSpeedMultiplier

    worker.fishingTier = loadout and loadout.tier or 0
    worker.fishingTierLabel = loadout and loadout.tierLabel or (Config.GetFishingTierLabel and Config.GetFishingTierLabel(0)) or nil
    worker.fishingCapabilities = loadout and loadout.capabilityList or {}
    worker.fishingBaitActive = loadout and loadout.baitApplies == true or false
    worker.fishingHasBackpack = loadout and loadout.carryProfile and #(loadout.carryProfile.containers or {}) > 0 or false

    local didWorkThisTick = false

    if hp <= 0 then
        Internal.markWorkerDead(worker, currentHour, normalizedJobType, Config.PresenceStates.Home, hasCalories, hasHydration)
    elseif worker.jobEnabled and toolsReady and hasHydration and hasCalories and not forcedRest then
        worker.state = Config.States.Working
        worker.workProgress = Internal.clampHours(worker.workProgress) + (workableHours * effectiveWorkPerHour)
        didWorkThisTick = workableHours > 0

        while worker.workProgress >= cycleHours do
            loadout = Config.GetFishingLoadout and Config.GetFishingLoadout(worker) or nil
            if not loadout or (tonumber(loadout.tier) or 0) <= 0 or not Registry.WorkerHasRequiredTools(worker) then
                worker.workProgress = 0
                break
            end

            worker.workProgress = worker.workProgress - cycleHours
            local jobResult = buildFishingResult(worker, loadout, jobSkillEffects)
            applyBaitConsumption(worker, loadout, currentHour)

            if jobResult.success then
                applySuccessfulFishingWear(worker, currentHour)
                local blockedCount = addFishingOutput(worker, jobResult.entries)
                Internal.logJobCycleOutcome(worker, currentHour, jobResult.totalQuantity, Interaction.GetPlaceLabel(worker), jobResult.entries)
                Sim.grantWorkerJobXP(worker, currentHour, jobResult.skillEffects or jobSkillEffects, jobResult.totalQuantity)
                if blockedCount > 0 then
                    Internal.appendWorkerLog(
                        worker,
                        "Inventory is full. " .. tostring(blockedCount) .. " caught item" .. (blockedCount == 1 and "" or "s") .. " could not be carried.",
                        currentHour,
                        "inventory"
                    )
                    worker.state = Config.States.StorageFull
                    break
                end
            else
                Internal.appendWorkerLog(worker, tostring(jobResult.failureReason or "No catch this cycle."), currentHour, "output")
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
            Energy.BeginForcedRest(worker, currentHour, lowEnergyReason, "Too tired to keep fishing. Resting at home.")
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

if DC_Colony.Config.JobProfiles and DC_Colony.Config.JobProfiles.Fish then
    DC_Colony.Config.JobProfiles.Fish.processHandler = Sim.ProcessFishingJob
    DC_Colony.Config.JobProfiles.Fish.hooks.onJobBlocked = function(worker)
        local Config = DC_Colony.Config
        worker.fishingTier = 0
        worker.fishingTierLabel = Config.GetFishingTierLabel and Config.GetFishingTierLabel(0) or nil
        worker.fishingCapabilities = {}
        worker.fishingBaitActive = false
        worker.fishingHasBackpack = false
    end
    DC_Colony.Config.JobProfiles.Fish.hooks.clearStaleFields = function(worker)
        worker.fishingTier = nil
        worker.fishingTierLabel = nil
        worker.fishingCapabilities = nil
        worker.fishingBaitActive = nil
        worker.fishingHasBackpack = nil
    end
end
