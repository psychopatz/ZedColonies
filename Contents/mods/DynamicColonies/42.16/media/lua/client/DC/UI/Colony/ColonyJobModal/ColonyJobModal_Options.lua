DC_ColonyJobModal = DC_ColonyJobModal or {}
DC_ColonyJobModal.Internal = DC_ColonyJobModal.Internal or {}

local FlavorText = DC_ColonyJobModal.Internal.FlavorText or {}

local function getJobDisplayColor(config, jobType)
    local normalized = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
    local jobTypes = config.JobTypes or {}

    if normalized == tostring(jobTypes.Builder or "Builder") then
        return { r = 0.48, g = 0.9, b = 0.48, a = 1 }
    end
    if normalized == tostring(jobTypes.Scavenge or "Scavenge") then
        return { r = 0.95, g = 0.78, b = 0.36, a = 1 }
    end
    if normalized == tostring(jobTypes.Farm or "Farm") then
        return { r = 0.62, g = 0.88, b = 0.42, a = 1 }
    end
    if normalized == tostring(jobTypes.Fish or "Fish") then
        return { r = 0.48, g = 0.78, b = 0.98, a = 1 }
    end
    if normalized == tostring(jobTypes.Gatherer or "Gatherer") then
        return { r = 0.74, g = 0.86, b = 0.42, a = 1 }
    end
    if normalized == tostring(jobTypes.Doctor or "Doctor") then
        return { r = 0.95, g = 0.52, b = 0.52, a = 1 }
    end
    if normalized == tostring(jobTypes.Guard or "Guard") then
        return { r = 0.96, g = 0.68, b = 0.32, a = 1 }
    end
    if normalized == tostring(jobTypes.Unemployed or "Unemployed") then
        return { r = 0.7, g = 0.7, b = 0.7, a = 1 }
    end

    return { r = 0.9, g = 0.9, b = 0.9, a = 1 }
end

local function canSelectJob(config, worker, normalizedJob)
    if config.CanWorkerTakeJob then
        local capable, reason = config.CanWorkerTakeJob(worker, normalizedJob)
        return capable, reason
    end
    return true, nil
end

local function getSkillColor(level)
    level = tonumber(level) or 0
    if level >= 5 then
        return { r = 0.48, g = 0.9, b = 0.48, a = 1 }
    elseif level >= 3 then
        return { r = 0.95, g = 0.78, b = 0.36, a = 1 }
    elseif level >= 1 then
        return { r = 0.95, g = 0.52, b = 0.52, a = 1 }
    else
        return { r = 0.75, g = 0.35, b = 0.35, a = 1 }
    end
end

local function describeJobOption(config, worker, normalized, label)
    local jobTypes = config.JobTypes or {}
    local color = nil
    local tempWorker = worker and {
        scavengeSiteProfileID = worker.scavengeSiteProfileID,
        gathererConfig = worker.gathererConfig,
        jobType = normalized
    } or { jobType = normalized }
    local skillID = config.GetWorkerJobSkillID and config.GetWorkerJobSkillID(tempWorker, { jobType = normalized }) or nil

    if normalized == tostring((jobTypes.TravelCompanion or "TravelCompanion"))
        or normalized == tostring((jobTypes.Guard or "Guard")) then
        local meleeLevel = 0
        local shootingLevel = 0
        if DC_Colony and DC_Colony.Skills then
            local meleeEntry = DC_Colony.Skills.GetSkillEntry(worker, "Melee")
            meleeLevel = math.max(0, math.floor(tonumber(meleeEntry and meleeEntry.level) or 0))
            local shootingEntry = DC_Colony.Skills.GetSkillEntry(worker, "Shooting")
            shootingLevel = math.max(0, math.floor(tonumber(shootingEntry and shootingEntry.level) or 0))
        end
        local highestLevel = math.max(meleeLevel, shootingLevel)
        color = getSkillColor(highestLevel)
        local texts = {}
        if shootingLevel > 0 then table.insert(texts, "Shooting " .. tostring(shootingLevel)) end
        if meleeLevel > 0 then table.insert(texts, "Melee " .. tostring(meleeLevel)) end
        if #texts > 0 then
            label = label .. " - " .. table.concat(texts, " / ")
        else
            label = label .. " - Lvl 0 Combat"
        end
    elseif skillID and DC_Colony and DC_Colony.Skills then
        local entry = DC_Colony.Skills.GetSkillEntry(worker, skillID)
        local level = math.max(0, math.floor(tonumber(entry and entry.level) or 0))
        if level <= 0 then level = 0 end
        local skillLabel = config.GetSkillDisplayName and config.GetSkillDisplayName(skillID) or skillID
        label = label .. " - Lvl " .. tostring(level) .. " " .. skillLabel
        color = getSkillColor(level)
    else
        color = getJobDisplayColor(config, normalized)
    end

    return label, color
end

local function buildOrderedJobOptions(config, worker)
    local ordered = {}
    local seen = {}
    local jobTypes = config.JobTypes or {}
    local extras = {}

    local function addJob(jobType)
        local normalized = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
        if normalized == "" or seen[normalized] then
            return
        end

        local profile = config.GetJobProfile and config.GetJobProfile(normalized) or {}
        local enabled, reason = canSelectJob(config, worker, normalized)
        local label = tostring(profile.displayName or normalized)
        local color
        label, color = describeJobOption(config, worker, normalized, label)

        if enabled == false and normalized == tostring((jobTypes.TravelCompanion or "TravelCompanion")) and string.find(tostring(reason or ""), "V2", 1, true) then
            label = label .. tostring(FlavorText.needsV2Suffix or " (Needs V2)")
        end
        ordered[#ordered + 1] = {
            jobType = normalized,
            label = label,
            enabled = enabled,
            disabledReason = reason,
            color = color,
            disabledColor = enabled and nil or { r = 0.92, g = 0.28, b = 0.28, a = 1 }
        }
        seen[normalized] = true
    end

    addJob(jobTypes.Unemployed)
    addJob(jobTypes.Scavenge)
    addJob(jobTypes.Gatherer)
    addJob(jobTypes.Farm)
    addJob(jobTypes.Fish)

    for jobType, profile in pairs(config.JobProfiles or {}) do
        local normalized = config.NormalizeJobType and config.NormalizeJobType(jobType) or tostring(jobType or "")
        if normalized ~= "" and not seen[normalized] then
            local enabled, reason = canSelectJob(config, worker, normalized)
            local label = tostring(profile and profile.displayName or normalized)
            local color
            label, color = describeJobOption(config, worker, normalized, label)

            if enabled == false and normalized == tostring((jobTypes.TravelCompanion or "TravelCompanion")) and string.find(tostring(reason or ""), "V2", 1, true) then
                label = label .. tostring(FlavorText.needsV2Suffix or " (Needs V2)")
            end
            extras[#extras + 1] = {
                jobType = normalized,
                label = label,
                enabled = enabled,
                disabledReason = reason,
                color = color,
                disabledColor = enabled and nil or { r = 0.92, g = 0.28, b = 0.28, a = 1 }
            }
            seen[normalized] = true
        end
    end

    table.sort(extras, function(a, b)
        return tostring(a.label or a.jobType) < tostring(b.label or b.jobType)
    end)

    for _, option in ipairs(extras) do
        ordered[#ordered + 1] = option
    end

    return ordered
end

DC_ColonyJobModal.Internal.BuildOrderedJobOptions = buildOrderedJobOptions

return DC_ColonyJobModal
