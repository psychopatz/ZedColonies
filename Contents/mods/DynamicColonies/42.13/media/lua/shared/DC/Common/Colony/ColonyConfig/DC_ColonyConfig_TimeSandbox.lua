DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

function Config.GetCurrentWorldHours()
    local gt = getGameTime()
    if not gt then return 0 end
    return tonumber(gt:getWorldAgeHours()) or 0
end

function Config.GetCurrentHour()
    return math.floor(Config.GetCurrentWorldHours())
end

function Config.GetSandboxTable()
    return SandboxVars and SandboxVars.DynamicColonies or {}
end

function Config.GetLegacySandboxTable()
    return SandboxVars and SandboxVars.DynamicTrading or {}
end

function Config.GetSandboxNumber(key, fallback)
    local sandbox = Config.GetSandboxTable()
    local value = tonumber(sandbox and sandbox[key])
    if value == nil then
        local legacy = Config.GetLegacySandboxTable()
        value = tonumber(legacy and legacy[key])
    end
    if value == nil then
        return fallback
    end
    return value
end

function Config.GetSandboxNumberAny(keys, fallback)
    local sandbox = Config.GetSandboxTable()
    for _, key in ipairs(keys or {}) do
        local value = tonumber(sandbox and sandbox[key])
        if value ~= nil then
            return value
        end
    end
    local legacy = Config.GetLegacySandboxTable()
    for _, key in ipairs(keys or {}) do
        local value = tonumber(legacy and legacy[key])
        if value ~= nil then
            return value
        end
    end
    return fallback
end

function Config.GetColonyDailyCaloriesUse()
    return math.max(
        0,
        Config.GetSandboxNumberAny(
            { "ColonyDailyCaloriesUse", "LabourDailyCaloriesUse" },
            Config.DEFAULT_LABOUR_DAILY_CALORIES_USE
        ) or Config.DEFAULT_LABOUR_DAILY_CALORIES_USE
    )
end

function Config.GetColonyDailyHydrationUse()
    return math.max(
        0,
        Config.GetSandboxNumberAny(
            { "ColonyDailyHydrationUse", "LabourDailyHydrationUse" },
            Config.DEFAULT_LABOUR_DAILY_HYDRATION_USE
        ) or Config.DEFAULT_LABOUR_DAILY_HYDRATION_USE
    )
end

function Config.GetDefaultWorkerCarryWeight()
    return math.max(
        0,
        Config.GetSandboxNumberAny(
            { "ColonyBaseCarryWeight", "LabourBaseCarryWeight" },
            Config.DEFAULT_WORKER_CARRY_WEIGHT
        ) or Config.DEFAULT_WORKER_CARRY_WEIGHT
    )
end

function Config.GetScavengeTravelHours()
    return math.max(
        0,
        Config.GetSandboxNumberAny(
            { "ColonyScavengeTravelHours", "NPCTradingWalkHours" },
            Config.DEFAULT_SCAVENGE_TRAVEL_HOURS
        ) or Config.DEFAULT_SCAVENGE_TRAVEL_HOURS
    )
end

function Config.GetStarterColonistCount()
    return math.max(
        0,
        math.floor(
            Config.GetSandboxNumberAny(
                { "ColonyStarterColonists" },
                0
            ) or 0
        )
    )
end

local function roundToNearestWhole(value)
    local numeric = tonumber(value) or 0
    if numeric <= 0 then
        return 0
    end
    return math.floor(numeric + 0.5)
end

function Config.GetScavengeBaseWorkAmount()
    local configuredAmount = Config.GetSandboxNumberAny(
        { "ColonyBaseWorkAmount", "LabourBaseWorkAmount" },
        nil
    )
    if configuredAmount ~= nil then
        return math.max(1, roundToNearestWhole(configuredAmount))
    end

    local sandbox = Config.GetSandboxTable()
    local legacy = Config.GetLegacySandboxTable()
    local legacyHours = tonumber(sandbox and sandbox.ColonyBaseWorkCycleHours)
    if legacyHours == nil then
        legacyHours = tonumber(legacy and legacy.ColonyBaseWorkCycleHours)
    end
    if legacyHours and legacyHours > 0 then
        local defaultLegacyHours = math.max(0.1, tonumber(Config.DEFAULT_SCAVENGE_WORK_CYCLE_HOURS) or 16)
        local defaultAmount = math.max(1, tonumber(Config.DEFAULT_SCAVENGE_WORK_AMOUNT) or 500)
        local convertedAmount = (legacyHours / defaultLegacyHours) * defaultAmount
        return math.max(1, roundToNearestWhole(convertedAmount))
    end

    return math.max(1, tonumber(Config.DEFAULT_SCAVENGE_WORK_AMOUNT) or 500)
end

function Config.GetScavengeBaseWorkPerHour()
    local defaultAmount = math.max(1, tonumber(Config.DEFAULT_SCAVENGE_WORK_AMOUNT) or 500)
    local defaultLegacyHours = math.max(0.1, tonumber(Config.DEFAULT_SCAVENGE_WORK_CYCLE_HOURS) or 16)
    return defaultAmount / defaultLegacyHours
end

function Config.GetScavengeBaseWorkMultiplier()
    return math.max(
        0.01,
        Config.GetSandboxNumberAny(
            { "ColonyBaseWorkMultiplier", "LabourBaseWorkMultiplier" },
            Config.DEFAULT_SCAVENGE_BASE_WORK_MULTIPLIER
        ) or Config.DEFAULT_SCAVENGE_BASE_WORK_MULTIPLIER
    )
end

function Config.GetFishingBaseWorkAmount()
    local configuredAmount = Config.GetSandboxNumberAny(
        { "ColonyFishingWorkAmount", "LabourFishingWorkAmount" },
        nil
    )
    if configuredAmount ~= nil then
        return math.max(1, roundToNearestWhole(configuredAmount))
    end

    return math.max(1, tonumber(Config.DEFAULT_FISHING_WORK_AMOUNT) or tonumber(Config.DEFAULT_SCAVENGE_WORK_AMOUNT) or 500)
end

function Config.GetFishingBaseWorkPerHour()
    local defaultAmount = math.max(1, tonumber(Config.DEFAULT_FISHING_WORK_AMOUNT) or tonumber(Config.DEFAULT_SCAVENGE_WORK_AMOUNT) or 500)
    local fishProfile = Config.JobProfiles and Config.JobProfiles.Fish or nil
    local defaultCycleHours = math.max(0.1, tonumber(fishProfile and fishProfile.cycleHours) or 18)
    return defaultAmount / defaultCycleHours
end

function Config.GetEffectiveWorkTarget(worker, profile)
    local safeProfile = profile or Config.GetJobProfile(worker and worker.jobType)
    local normalizedJob = Config.NormalizeJobType((worker and worker.jobType) or (safeProfile and safeProfile.jobType))
    if normalizedJob == (Config.JobTypes and Config.JobTypes.Scavenge) then
        return Config.GetScavengeBaseWorkAmount()
    end
    if normalizedJob == (Config.JobTypes and Config.JobTypes.Fish) then
        return Config.GetFishingBaseWorkAmount()
    end

    return math.max(0.1, tonumber(safeProfile and safeProfile.cycleHours) or 24)
end

function Config.GetEffectiveCycleHours(worker, profile)
    return Config.GetEffectiveWorkTarget(worker, profile)
end

function Config.GetBaseWorkSpeedMultiplier(worker, profile)
    local safeProfile = profile or Config.GetJobProfile(worker and worker.jobType)
    local normalizedJob = Config.NormalizeJobType((worker and worker.jobType) or (safeProfile and safeProfile.jobType))
    if normalizedJob == (Config.JobTypes and Config.JobTypes.Scavenge) then
        return Config.GetScavengeBaseWorkMultiplier()
    end

    return 1.0
end

function Config.GetEffectiveDailyCaloriesNeed(worker, profile)
    return Config.GetColonyDailyCaloriesUse()
end

function Config.GetEffectiveDailyHydrationNeed(worker, profile)
    return Config.GetColonyDailyHydrationUse()
end

function Config.GetEffectiveHourlyCaloriesNeed(worker, profile)
    local hoursPerDay = tonumber(Config.HOURS_PER_DAY) or 24
    if hoursPerDay <= 0 then
        return 0
    end
    return Config.GetEffectiveDailyCaloriesNeed(worker, profile) / hoursPerDay
end

function Config.GetEffectiveHourlyHydrationNeed(worker, profile)
    local hoursPerDay = tonumber(Config.HOURS_PER_DAY) or 24
    if hoursPerDay <= 0 then
        return 0
    end
    return Config.GetEffectiveDailyHydrationNeed(worker, profile) / hoursPerDay
end

return Config
