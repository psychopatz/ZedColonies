DT_Labour = DT_Labour or {}
DT_Labour.Config = DT_Labour.Config or {}

local Config = DT_Labour.Config

function Config.GetScavengeTierLabel(tier)
    local safeTier = math.max(0, math.floor(tonumber(tier) or 0))
    if safeTier <= 0 then
        return "Tier 0 - Open Containers"
    end
    if safeTier == 1 then
        return "Tier 1 - Locked Entry"
    end
    if safeTier == 2 then
        return "Tier 2 - Salvage and Strip"
    end
    return "Tier 3 - Secure and Industrial"
end

function Config.GetScavengeSiteProfile(profileID)
    local profiles = Config.ScavengeSiteProfiles or {}
    return profiles[tostring(profileID or "")] or profiles.Unknown or { id = "Unknown", displayName = "Unsorted Location", ruleWeights = {} }
end

function Config.GetScavengeLoadout(worker)
    local defaults = Config.ScavengeLootDefaults or {}
    local loadout = {
        tier = 0,
        capabilityList = {},
        capabilityMap = {},
        searchSpeedMultiplier = defaults.darkSearchSpeedMultiplier or 0.5,
        poolRolls = defaults.basePoolRolls or 2,
        haulBonus = 0,
        routePlanning = 0,
        failureWeight = (defaults.tierFailureWeights and defaults.tierFailureWeights[0]) or 7,
        hasCarpentryKit = false,
        hasMetalKit = false,
        hasRoutePlan = false,
        bulkLoot = false,
        bundleLoot = false
    }

    local capabilitySeen = {}
    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        local fullType = entry and entry.fullType or nil
        local profile = Config.GetScavengeItemProfile(fullType)
        if profile then
            loadout.tier = math.max(loadout.tier, tonumber(profile.tier) or 0)
            loadout.haulBonus = loadout.haulBonus + math.max(0, tonumber(profile.haulBonus) or 0)
            loadout.routePlanning = loadout.routePlanning + math.max(0, tonumber(profile.routePlanning) or 0)

            local speed = tonumber(profile.searchSpeedMultiplier)
            if speed and speed > 0 then
                loadout.searchSpeedMultiplier = math.max(loadout.searchSpeedMultiplier, speed)
            end

            for _, capability in ipairs(profile.capabilities or {}) do
                if not capabilitySeen[capability] then
                    capabilitySeen[capability] = true
                    loadout.capabilityMap[capability] = true
                    loadout.capabilityList[#loadout.capabilityList + 1] = capability
                end
            end
        end
    end

    loadout.hasCarpentryKit = loadout.capabilityMap["Scavenge.Extraction.CarpentryHammer"] == true
        and loadout.capabilityMap["Scavenge.Extraction.CarpentrySaw"] == true
    loadout.hasMetalKit = loadout.capabilityMap["Scavenge.Extraction.MetalTorch"] == true
        and loadout.capabilityMap["Scavenge.Extraction.MetalMask"] == true
    loadout.hasRoutePlan = loadout.capabilityMap["Scavenge.Utility.Map"] == true
        and loadout.capabilityMap["Scavenge.Utility.Pen"] == true
    loadout.bulkLoot = loadout.capabilityMap["Scavenge.Haul.Bulk"] == true
    loadout.bundleLoot = loadout.capabilityMap["Scavenge.Haul.Bundle"] == true
    loadout.carryProfile = Config.GetScavengeCarryProfile(worker)
    loadout.effectiveCarryLimit = loadout.carryProfile and loadout.carryProfile.effectiveCarryLimit
        or (Config.GetWorkerBaseCarryWeight and Config.GetWorkerBaseCarryWeight(worker))
        or (Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight())
        or (tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT) or 8)
    loadout.maxCarryWeight = loadout.carryProfile and loadout.carryProfile.maxCarryWeight
        or loadout.effectiveCarryLimit
    loadout.rawCarryAllowance = loadout.carryProfile and loadout.carryProfile.rawAllowance or loadout.maxCarryWeight
    loadout.carryContainerCount = #(loadout.carryProfile and loadout.carryProfile.containers or {})

    if loadout.capabilityMap["Scavenge.Access.LockedHome"] or loadout.capabilityMap["Scavenge.Access.ElectronicStore"] then
        loadout.tier = math.max(loadout.tier, 1)
    end
    if loadout.hasCarpentryKit or loadout.capabilityMap["Scavenge.Extraction.Plumbing"] then
        loadout.tier = math.max(loadout.tier, 2)
    end
    if loadout.hasMetalKit or loadout.capabilityMap["Scavenge.Access.HeavyEntry"] then
        loadout.tier = math.max(loadout.tier, 3)
    end

    loadout.poolRolls = loadout.poolRolls + loadout.haulBonus
    if loadout.bulkLoot then
        loadout.poolRolls = loadout.poolRolls + 1
    end
    if loadout.hasRoutePlan then
        loadout.poolRolls = loadout.poolRolls + 1
    end
    loadout.poolRolls = math.max(1, math.min(defaults.maxPoolRolls or 5, loadout.poolRolls))

    local failureWeights = defaults.tierFailureWeights or {}
    loadout.failureWeight = failureWeights[loadout.tier] or failureWeights[0] or 7
    if loadout.capabilityMap["Scavenge.Utility.Light"] then
        loadout.failureWeight = math.max(0, loadout.failureWeight - 1)
    end
    if loadout.hasRoutePlan then
        loadout.failureWeight = math.max(0, loadout.failureWeight - 1)
    end

    return loadout
end

return Config
