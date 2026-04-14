DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

function Config.NormalizeArchetypeID(archetypeID)
    local value = tostring(archetypeID or "")
    if value == "" then
        return "General"
    end

    if Config.JobProfiles[value] then
        return "General"
    end

    return value
end

function Config.NormalizeJobType(jobType)
    if Config.JobProfiles[jobType] then
        return jobType
    end

    local mapped = Config.LegacyProfessionToJob[jobType]
    if mapped then
        return mapped
    end

    return Config.JobTypes.Scavenge
end

function Config.GetJobProfile(jobType)
    return Config.JobProfiles[Config.NormalizeJobType(jobType)] or Config.JobProfiles.Scavenge
end

function Config.GetProfile(profession)
    return Config.GetJobProfile(profession)
end

local function getWorkerSkillLevel(worker, skillID)
    local skills = DC_Colony and DC_Colony.Skills or nil
    local entry = skills and skills.GetSkillEntry and skills.GetSkillEntry(worker, skillID) or nil
    return math.max(0, math.floor(tonumber(entry and entry.level) or 0))
end

function Config.GetWorkerJobCapability(worker, jobType)
    local normalizedJobType = Config.NormalizeJobType(jobType)
    local capability = {
        capable = true,
        reason = nil,
        skillID = nil,
        skillLevel = 0,
    }

    if normalizedJobType == ((Config.JobTypes or {}).Builder) then
        capability.skillID = "Construction"
        capability.skillLevel = getWorkerSkillLevel(worker, capability.skillID)
        capability.capable = capability.skillLevel > 0
        if not capability.capable then
            capability.reason = "That worker has no Construction skill and cannot be assigned to Builder."
        end
    elseif normalizedJobType == ((Config.JobTypes or {}).TravelCompanion) then
        local companion = DC_Colony and DC_Colony.Companion or nil
        capability.skillID = "Combat"
        capability.skillLevel = math.max(
            getWorkerSkillLevel(worker, "Melee"),
            getWorkerSkillLevel(worker, "Shooting")
        )
        if Config.IsTravelCompanionSupported and not Config.IsTravelCompanionSupported() then
            capability.capable = false
            capability.reason = "Travel Companion requires Dynamic Trading V2."
            return capability
        end
        if companion and companion.CanWorkerBeCompanion then
            capability.capable, capability.reason = companion.CanWorkerBeCompanion(worker)
        else
            capability.capable = false
            capability.reason = "Travel Companion is unavailable."
        end
    elseif normalizedJobType == ((Config.JobTypes or {}).Fish) then
        capability.skillID = "Animals"
        capability.skillLevel = getWorkerSkillLevel(worker, capability.skillID)
        capability.capable = capability.skillLevel > 0
        if not capability.capable then
            capability.reason = "That worker has no Animals skill and cannot be assigned to Fishing."
        end
    end

    return capability
end

function Config.CanWorkerTakeJob(worker, jobType)
    local normalizedJobType = Config.NormalizeJobType(jobType)
    local incapacitatedState = tostring((Config.States or {}).Incapacitated or "Incapacitated")
    local unemployedJob = tostring((Config.JobTypes or {}).Unemployed or "Unemployed")
    if worker and tostring(worker.state or "") == incapacitatedState and tostring(normalizedJobType or "") ~= unemployedJob then
        return false, "That worker is incapacitated and must recover before returning to duty."
    end

    local capability = Config.GetWorkerJobCapability(worker, jobType)
    return capability.capable == true, capability.reason
end

function Config.IsTravelCompanionSupported()
    local companion = DC_Colony and DC_Colony.Companion or nil
    if companion and companion.IsV2Active then
        return companion.IsV2Active() == true
    end

    local activated = getActivatedMods and getActivatedMods() or nil
    return activated and activated.contains and activated:contains("DynamicTradingV2") or false
end

function Config.GetDefaultJobForArchetype(archetypeID)
    local normalized = Config.NormalizeArchetypeID(archetypeID)
    if normalized == "Builder" then
        return Config.JobTypes.Builder
    end
    if normalized == "Doctor" then
        return Config.JobTypes.Doctor
    end
    if normalized == "Farmer" then
        return Config.JobTypes.Farm
    end
    if normalized == "Angler" then
        return Config.JobTypes.Fish
    end
    if normalized == "Scavenger" then
        return Config.JobTypes.Scavenge
    end
    return Config.JobTypes.Unemployed
end

function Config.GetJobSpeedMultiplier(archetypeID, jobType)
    local normalizedJobType = Config.NormalizeJobType(jobType)
    local bonuses = Config.ArchetypeJobBonuses[tostring(archetypeID or "")]
    if bonuses and bonuses[normalizedJobType] then
        return bonuses[normalizedJobType]
    end
    return 1.0
end

function Config.GetWorkerBaseCarryWeight(worker)
    local explicitCarryWeight = tonumber(worker and worker.baseCarryWeightOverride)
    if explicitCarryWeight and explicitCarryWeight > 0 then
        return explicitCarryWeight
    end

    local archetypeID = Config.NormalizeArchetypeID(worker and worker.archetypeID)
    local archetypeCarryWeight = tonumber(Config.ArchetypeCarryWeight and Config.ArchetypeCarryWeight[archetypeID])
    if archetypeCarryWeight and archetypeCarryWeight > 0 then
        return archetypeCarryWeight
    end

    return Config.GetDefaultWorkerCarryWeight and Config.GetDefaultWorkerCarryWeight()
        or math.max(0, tonumber(Config.DEFAULT_WORKER_CARRY_WEIGHT) or 8)
end

function Config.GetNextJobType(jobType)
    local order = {
        Config.JobTypes.Unemployed,
        Config.JobTypes.Builder,
        Config.JobTypes.Doctor,
        Config.JobTypes.Scavenge,
        Config.JobTypes.Farm,
        Config.JobTypes.Fish
    }
    if Config.IsTravelCompanionSupported and Config.IsTravelCompanionSupported() then
        table.insert(order, 5, Config.JobTypes.TravelCompanion)
    end
    local normalized = Config.NormalizeJobType(jobType)
    for index, value in ipairs(order) do
        if value == normalized then
            return order[(index % #order) + 1]
        end
    end
    return order[1]
end

function Config.GetProjectionUUID(workerID)
    return Config.PROJECTION_PREFIX .. tostring(workerID or "unknown")
end

function Config.GetOwnerUsername(playerOrUsername)
    if type(playerOrUsername) == "string" then
        return playerOrUsername
    end

    local player = playerOrUsername
    if player and player.getUsername then
        local username = player:getUsername()
        if username and username ~= "" then
            if DynamicTrading_Factions and DynamicTrading_Factions.GetPlayerFaction then
                local faction = DynamicTrading_Factions.GetPlayerFaction(player)
                local authorityUsername = faction and tostring(faction.leaderUsername or "") or ""
                if authorityUsername ~= "" then
                    return authorityUsername
                end
            end
            return username
        end
    end

    return "local"
end

return Config
