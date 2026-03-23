require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourSkills/DT_LabourSkills"

DT_Labour = DT_Labour or {}
DT_Labour.Output = DT_Labour.Output or {}

local Config = DT_Labour.Config
local Output = DT_Labour.Output
local Skills = DT_Labour.Skills

Output.CandidateCache = Output.CandidateCache or {}

local function matchesAllTags(itemTags, requiredTags)
    if type(itemTags) ~= "table" then return false end
    for _, required in ipairs(requiredTags or {}) do
        if not Config.HasMatchingTag(itemTags, required) then
            return false
        end
    end
    return true
end

local function getCandidates(requiredTags)
    local cacheKey = table.concat(requiredTags or {}, "|")
    if Output.CandidateCache[cacheKey] and #Output.CandidateCache[cacheKey] > 0 then
        return Output.CandidateCache[cacheKey]
    end

    local pool = {}
    local masterList = DynamicTrading and DynamicTrading.Config and DynamicTrading.Config.MasterList or {}
    for fullType, itemData in pairs(masterList) do
        if itemData and matchesAllTags(itemData.tags, requiredTags) then
            pool[#pool + 1] = fullType
        end
    end

    Output.CandidateCache[cacheKey] = pool
    return pool
end

local function applyWeightMultiplier(baseWeight, multiplier)
    local safeWeight = math.max(0, tonumber(baseWeight) or 0)
    local safeMultiplier = tonumber(multiplier)
    if safeWeight <= 0 then
        return 0
    end
    if safeMultiplier == nil then
        return safeWeight
    end
    if safeMultiplier <= 0 then
        return 0
    end
    return math.max(1, math.floor((safeWeight * safeMultiplier) + 0.5))
end

local function rollChance(chance)
    local safeChance = math.max(0, math.min(0.99, tonumber(chance) or 0))
    if safeChance <= 0 then
        return false
    end

    local scaled = math.max(1, math.floor((safeChance * 10000) + 0.5))
    return (ZombRand(10000) + 1) <= scaled
end

local function applyQuantityMultiplier(baseQty, multiplier)
    local safeQty = math.max(1, math.floor(tonumber(baseQty) or 1))
    local scaled = math.max(1, safeQty * math.max(0.01, tonumber(multiplier) or 1))
    local guaranteed = math.floor(scaled)
    local remainder = scaled - guaranteed

    if remainder > 0 and rollChance(remainder) then
        guaranteed = guaranteed + 1
    end

    return math.max(1, guaranteed)
end

local function getJobFailureChance(jobType)
    if jobType == Config.JobTypes.Farm then
        return 0.18
    end
    if jobType == Config.JobTypes.Fish then
        return 0.24
    end
    return 0
end

local function clampNumber(value, minimum, maximum)
    local safeValue = tonumber(value) or 0
    if safeValue < minimum then
        return minimum
    end
    if safeValue > maximum then
        return maximum
    end
    return safeValue
end

local function getWorkerSkillLevel(worker, skillID)
    local entry = Skills and Skills.GetSkillEntry and Skills.GetSkillEntry(worker, skillID) or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

local function buildScavengeSkillContext(worker, siteProfile, skillEffects)
    local defaults = Config.ScavengeLootDefaults or {}
    local primarySkillID = skillEffects and skillEffects.skillID
        or (Config.GetScavengeSiteSkillID and Config.GetScavengeSiteSkillID(worker and worker.scavengeSiteProfileID))
        or "Construction"
    local primaryLevel = math.max(0, math.floor(tonumber(skillEffects and skillEffects.level) or getWorkerSkillLevel(worker, primarySkillID)))
    local secondaryWeights = siteProfile and siteProfile.secondarySkillWeights or {}
    local context = {
        primarySkillID = primarySkillID,
        primaryLevel = primaryLevel,
        levels = {},
        siteMix = {}
    }

    context.levels[primarySkillID] = primaryLevel
    context.siteMix[primarySkillID] = 1.0

    for skillID, mix in pairs(secondaryWeights) do
        local safeMix = clampNumber((tonumber(mix) or 0) * (tonumber(defaults.secondarySkillWeightScale) or 0.45), 0, 1)
        if safeMix > 0 then
            context.levels[skillID] = getWorkerSkillLevel(worker, skillID)
            context.siteMix[skillID] = safeMix
        end
    end

    return context
end

local function getRuleSkillRating(rule, skillContext)
    local weights = rule and rule.skillWeights or nil
    if type(weights) ~= "table" then
        return math.max(0, tonumber(skillContext and skillContext.primaryLevel) or 0)
    end

    local totalLevel = 0
    local totalWeight = 0
    for skillID, affinity in pairs(weights) do
        local safeAffinity = math.max(0, tonumber(affinity) or 0)
        local mix = 0
        if skillID == skillContext.primarySkillID then
            mix = 1.0
        else
            mix = clampNumber(skillContext.siteMix[skillID] or 0, 0, 1)
        end

        if safeAffinity > 0 and mix > 0 then
            local level = math.max(0, tonumber(skillContext.levels[skillID]) or 0)
            local weight = safeAffinity * mix
            totalLevel = totalLevel + (level * weight)
            totalWeight = totalWeight + weight
        end
    end

    if totalWeight <= 0 then
        return math.max(0, tonumber(skillContext and skillContext.primaryLevel) or 0)
    end

    return totalLevel / totalWeight
end

local function getRuleSkillWeightMultiplier(rule, skillContext)
    local defaults = Config.ScavengeLootDefaults or {}
    local rating = getRuleSkillRating(rule, skillContext)
    if tonumber(rule and rule.skillUnlockLevel) and rating < tonumber(rule.skillUnlockLevel) then
        return 0, rating
    end

    local perLevelScale = tonumber(defaults.skillWeightMultiplierScale) or 0.85
    local multiplier = 1 + ((rating / 20) * perLevelScale)
    if tonumber(rule and rule.rareSkillThreshold) and rating >= tonumber(rule.rareSkillThreshold) then
        multiplier = multiplier * math.max(1, tonumber(rule.rareWeightMultiplier) or 1.25)
    end

    return clampNumber(multiplier, 0, 3), rating
end

local function getBonusRareRollCount(loadout, skillContext)
    local defaults = Config.ScavengeLootDefaults or {}
    local bonusRolls = 0
    local primaryLevel = math.max(0, tonumber(skillContext and skillContext.primaryLevel) or 0)
    local tier = math.max(0, tonumber(loadout and loadout.tier) or 0)

    if tier >= 2 and primaryLevel >= (tonumber(defaults.bonusRareRollThreshold) or 10) then
        bonusRolls = bonusRolls + 1
    end
    if tier >= 3 and primaryLevel >= (tonumber(defaults.bonusRareRollMasteryThreshold) or 16) then
        bonusRolls = bonusRolls + 1
    end

    return math.max(0, math.min(tonumber(defaults.maxBonusRareRolls) or 2, bonusRolls))
end

local function buildWeightedScavengeEntries(loadout, siteProfile, skillEffects, skillContext, onlyRare)
    local entries = {}
    local totalWeight = 0
    local failureWeight = math.max(0, (tonumber(loadout and loadout.failureWeight) or 0)
        + (tonumber(siteProfile and siteProfile.failureWeightDelta) or 0))
    if onlyRare == true then
        failureWeight = failureWeight + 1
    end

    for _, rule in ipairs(Config.ScavengeLootRules or {}) do
        local minTier = math.max(0, tonumber(rule.minTier) or 0)
        if minTier <= math.max(0, tonumber(loadout and loadout.tier) or 0) then
            local isEligible = true
            if onlyRare == true and rule.isRare ~= true then
                isEligible = false
            end

            if rule.requiresAllCapabilities then
                for _, capability in ipairs(rule.requiresAllCapabilities) do
                    if not (loadout and loadout.capabilityMap and loadout.capabilityMap[capability]) then
                        isEligible = false
                        break
                    end
                end
            end

            if isEligible and rule.requiresAnyCapabilities and #rule.requiresAnyCapabilities > 0 then
                isEligible = false
                for _, capability in ipairs(rule.requiresAnyCapabilities) do
                    if loadout and loadout.capabilityMap and loadout.capabilityMap[capability] then
                        isEligible = true
                        break
                    end
                end
            end

            if isEligible then
                local pool = getCandidates(rule.tags)
                if #pool > 0 then
                    local ruleWeights = siteProfile and siteProfile.ruleWeights or nil
                    local weightMultiplier = ruleWeights and ruleWeights[rule.id] or nil
                    local skillWeightMultiplier, skillRating = getRuleSkillWeightMultiplier(rule, skillContext)
                    local combinedMultiplier = (tonumber(weightMultiplier) or 1) * skillWeightMultiplier
                    local weight = applyWeightMultiplier(rule.weight, combinedMultiplier)
                    if weight > 0 then
                        totalWeight = totalWeight + weight
                        entries[#entries + 1] = {
                            rule = rule,
                            pool = pool,
                            weight = weight,
                            skillRating = skillRating
                        }
                    end
                end
            end
        end
    end

    failureWeight = applyWeightMultiplier(failureWeight, skillEffects and skillEffects.botchChanceMultiplier or 1)
    if totalWeight > 0 and failureWeight > 0 then
        totalWeight = totalWeight + failureWeight
        table.insert(entries, 1, {
            failure = true,
            weight = failureWeight
        })
    end

    return entries, totalWeight
end

local function rollWeightedEntry(entries, totalWeight)
    if not entries or #entries <= 0 or totalWeight <= 0 then
        return nil
    end

    local roll = ZombRand(totalWeight) + 1
    local cursor = 0
    for _, entry in ipairs(entries) do
        cursor = cursor + math.max(0, tonumber(entry.weight) or 0)
        if roll <= cursor then
            return entry
        end
    end

    return entries[#entries]
end

local function getRuleQuantity(rule, loadout)
    local minQty = math.max(1, tonumber(rule and rule.minQty) or 1)
    local maxQty = math.max(minQty, tonumber(rule and rule.maxQty) or minQty)

    if loadout and loadout.bulkLoot then
        local bulkBonus = math.max(0, tonumber(rule and rule.bulkBonus) or 0)
        minQty = minQty + bulkBonus
        maxQty = maxQty + bulkBonus
    end

    if loadout and loadout.bundleLoot then
        local bundleBonus = math.max(0, tonumber(rule and rule.bundleBonus) or 0)
        minQty = minQty + bundleBonus
        maxQty = maxQty + bundleBonus
    end

    return Config.RandomRangeInclusive(minQty, maxQty)
end

local function hasKeys(value)
    if type(value) ~= "table" then
        return false
    end

    for _, _ in pairs(value) do
        return true
    end

    return false
end

local function resolveScavengeQuality(rule, selected, skillEffects, skillContext)
    local defaults = Config.ScavengeLootDefaults or {}
    local difficulty = math.max(0, tonumber(rule and rule.difficulty) or 0)
    if difficulty <= 0 then
        return "standard", math.max(0, tonumber(selected and selected.skillRating) or 0)
    end

    local skillRating = math.max(0, tonumber(selected and selected.skillRating) or getRuleSkillRating(rule, skillContext))
    local deficit = math.max(0, difficulty - skillRating)
    local surplus = math.max(0, skillRating - difficulty)
    local botchChance = 0
    if rule and rule.botchOutcome then
        botchChance = ((tonumber(defaults.botchChanceBase) or 0.04)
            + (deficit * (tonumber(defaults.botchChancePerDifficultyGap) or 0.035)))
            * math.max(0.1, tonumber(skillEffects and skillEffects.botchChanceMultiplier) or 1)
        botchChance = clampNumber(botchChance, 0, 0.55)
        if rollChance(botchChance) then
            return "botched", skillRating
        end
    end

    local excellentThreshold = difficulty + 5
    if skillRating >= excellentThreshold then
        local excellentChance = (tonumber(defaults.excellentChanceBase) or 0.03)
            + ((skillRating - excellentThreshold) * (tonumber(defaults.excellentChancePerSkillSurplus) or 0.02))
        if rollChance(clampNumber(excellentChance, 0, 0.30)) then
            return "excellent", skillRating
        end
    end

    if skillRating >= difficulty then
        local cleanChance = (tonumber(defaults.cleanChanceBase) or 0.10)
            + (surplus * (tonumber(defaults.cleanChancePerSkillSurplus) or 0.025))
        if rollChance(clampNumber(cleanChance, 0, 0.50)) then
            return "clean", skillRating
        end
    end

    return "standard", skillRating
end

local function buildWasteScavengeEntry(loadout, skillEffects)
    local pool = getCandidates({ "Quality.Waste" })
    if #pool <= 0 then
        return nil
    end

    local qty = applyQuantityMultiplier(getRuleQuantity({
        minQty = 1,
        maxQty = 2,
        bulkBonus = 1,
        bundleBonus = 1
    }, loadout), math.min(1, math.max(0.65, tonumber(skillEffects and skillEffects.yieldMultiplier) or 1)))

    return {
        fullType = pool[ZombRand(#pool) + 1],
        qty = qty
    }
end

local function resolveScavengeSelection(selected, loadout, skillEffects, skillContext)
    if not selected or selected.failure or not selected.rule or not selected.pool or #selected.pool <= 0 then
        return nil, "failure", nil
    end

    local quality, skillRating = resolveScavengeQuality(selected.rule, selected, skillEffects, skillContext)
    if quality == "botched" then
        if selected.rule.botchOutcome == "waste" then
            local wasteEntry = buildWasteScavengeEntry(loadout, skillEffects)
            if wasteEntry then
                return wasteEntry, "botched", {
                    quality = quality,
                    skillRating = skillRating,
                    wasted = true,
                    isRare = selected.rule.isRare == true
                }
            end
        end
        return nil, "failure", {
            quality = quality,
            skillRating = skillRating,
            failed = true,
            isRare = selected.rule.isRare == true
        }
    end

    local pool = selected.pool
    local fullType = pool[ZombRand(#pool) + 1]
    if not fullType then
        return nil, "failure", nil
    end

    local qty = applyQuantityMultiplier(getRuleQuantity(selected.rule, loadout), skillEffects.yieldMultiplier)
    if quality == "clean" then
        qty = applyQuantityMultiplier(qty, 1.15)
    elseif quality == "excellent" then
        qty = applyQuantityMultiplier(qty, selected.rule.isRare == true and 1.20 or 1.35)
    end

    return {
        fullType = fullType,
        qty = qty
    }, "success", {
        quality = quality,
        skillRating = skillRating,
        isRare = selected.rule.isRare == true,
        ruleID = selected.rule.id
    }
end

function Output.GenerateScavengeRun(worker)
    local results = {}
    local loadout = Config.GetScavengeLoadout and Config.GetScavengeLoadout(worker) or {}
    local siteProfile = Config.GetScavengeSiteProfile and Config.GetScavengeSiteProfile(worker and worker.scavengeSiteProfileID) or nil
    local skillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker) or {
        skillID = Config.GetScavengeSiteSkillID and Config.GetScavengeSiteSkillID(worker and worker.scavengeSiteProfileID) or "Construction",
        speedMultiplier = 1,
        yieldMultiplier = 1,
        botchChanceMultiplier = 1,
        level = 0
    }
    local skillContext = buildScavengeSkillContext(worker, siteProfile, skillEffects)
    local poolRolls = math.max(1, tonumber(loadout and loadout.poolRolls) or 1)
        + math.max(0, tonumber(siteProfile and siteProfile.poolRollBonus) or 0)
    local maxPoolRolls = (Config.ScavengeLootDefaults and Config.ScavengeLootDefaults.maxPoolRolls) or poolRolls
    poolRolls = math.max(1, math.min(maxPoolRolls, poolRolls))
    local bonusRareRolls = getBonusRareRollCount(loadout, skillContext)
    local avoidDuplicates = loadout and loadout.hasRoutePlan == true
    local usedRuleIDs = {}
    local usedFullTypes = {}
    local failedRolls = 0
    local successfulRolls = 0
    local totalQuantity = 0
    local botchedRolls = 0
    local rareFinds = 0
    local qualityCounts = {
        standard = 0,
        clean = 0,
        excellent = 0,
        botched = 0
    }

    local function runScavengeAttempt(onlyRare)
        local weightedEntries, totalWeight = buildWeightedScavengeEntries(loadout, siteProfile, skillEffects, skillContext, onlyRare == true)
        if not weightedEntries or #weightedEntries <= 0 or totalWeight <= 0 then
            return
        end
        if avoidDuplicates and hasKeys(usedRuleIDs) then
            local filteredEntries = {}
            local filteredWeight = 0
            for _, entry in ipairs(weightedEntries) do
                if entry.failure or not (entry.rule and usedRuleIDs[entry.rule.id]) then
                    filteredEntries[#filteredEntries + 1] = entry
                    filteredWeight = filteredWeight + math.max(0, tonumber(entry.weight) or 0)
                end
            end
            if #filteredEntries > 0 then
                weightedEntries = filteredEntries
                totalWeight = filteredWeight
            end
        end
        if totalWeight <= 0 then
            return
        end

        local selected = rollWeightedEntry(weightedEntries, totalWeight)
        if selected and not selected.failure and selected.pool then
            local resolvedEntry, outcomeType, meta = resolveScavengeSelection(selected, loadout, skillEffects, skillContext)
            if resolvedEntry and avoidDuplicates and not (meta and meta.wasted) and #selected.pool > 1 and usedFullTypes[resolvedEntry.fullType] then
                for _ = 1, #selected.pool do
                    local candidate = selected.pool[ZombRand(#selected.pool) + 1]
                    if candidate and not usedFullTypes[candidate] then
                        resolvedEntry.fullType = candidate
                        break
                    end
                end
            end

            if resolvedEntry then
                results[#results + 1] = resolvedEntry
                successfulRolls = successfulRolls + 1
                totalQuantity = totalQuantity + math.max(0, tonumber(resolvedEntry.qty) or 0)
                if selected.rule and selected.rule.id then
                    usedRuleIDs[selected.rule.id] = true
                end
                if meta and meta.wasted ~= true then
                    usedFullTypes[resolvedEntry.fullType] = true
                end
                if meta and meta.quality and qualityCounts[meta.quality] ~= nil then
                    qualityCounts[meta.quality] = qualityCounts[meta.quality] + 1
                end
                if meta and meta.quality == "botched" then
                    botchedRolls = botchedRolls + 1
                end
                if meta and meta.isRare == true then
                    rareFinds = rareFinds + 1
                end
            elseif outcomeType == "failure" then
                failedRolls = failedRolls + 1
                if meta and meta.quality == "botched" then
                    botchedRolls = botchedRolls + 1
                    qualityCounts.botched = qualityCounts.botched + 1
                end
            end
        else
            failedRolls = failedRolls + 1
        end
    end

    for _ = 1, poolRolls do
        runScavengeAttempt(false)
    end

    for _ = 1, bonusRareRolls do
        runScavengeAttempt(true)
    end

    return {
        entries = results,
        loadout = loadout,
        siteProfile = siteProfile,
        poolRolls = poolRolls,
        bonusRareRolls = bonusRareRolls,
        failedRolls = failedRolls,
        successfulRolls = successfulRolls,
        botchedRolls = botchedRolls,
        rareFinds = rareFinds,
        qualityCounts = qualityCounts,
        totalQuantity = totalQuantity,
        success = successfulRolls > 0 and totalQuantity > 0,
        skillEffects = skillEffects,
        skillContext = skillContext
    }
end

function Output.GenerateScavengeLoot(worker)
    local run = Output.GenerateScavengeRun(worker)
    return run.entries or {}
end

function Output.GenerateForJob(profile, worker)
    local results = {
        entries = {},
        totalQuantity = 0,
        success = false,
        failed = false,
        failureReason = nil
    }
    if not profile then
        return results
    end

    local normalizedJobType = Config.NormalizeJobType and Config.NormalizeJobType(profile.jobType) or profile.jobType
    if normalizedJobType == Config.JobTypes.Scavenge then
        return Output.GenerateScavengeRun(worker)
    end

    local skillEffects = Skills and Skills.GetWorkerJobEffects and Skills.GetWorkerJobEffects(worker, profile) or {
        speedMultiplier = 1,
        yieldMultiplier = 1,
        botchChanceMultiplier = 1,
        level = 0
    }
    results.skillEffects = skillEffects

    if rollChance(getJobFailureChance(normalizedJobType) * (skillEffects.botchChanceMultiplier or 1)) then
        results.failed = true
        results.failureReason = normalizedJobType == Config.JobTypes.Fish and "No catch this cycle." or "Botched cycle."
        return results
    end

    for _, rule in ipairs(profile.outputRules or {}) do
        local pool = getCandidates(rule.tags)
        if #pool > 0 then
            local picks = math.max(1, rule.picks or 1)
            for _ = 1, picks do
                local fullType = pool[ZombRand(#pool) + 1]
                local qty = ZombRand((rule.minQty or 1), (rule.maxQty or 1) + 1)
                qty = applyQuantityMultiplier(qty, skillEffects.yieldMultiplier)
                results.entries[#results.entries + 1] = {
                    fullType = fullType,
                    qty = qty
                }
                results.totalQuantity = results.totalQuantity + qty
            end
        end
    end

    results.success = results.totalQuantity > 0
    return results
end

function Output.GenerateForProfile(profile, worker)
    return Output.GenerateForJob(profile, worker)
end

return Output
