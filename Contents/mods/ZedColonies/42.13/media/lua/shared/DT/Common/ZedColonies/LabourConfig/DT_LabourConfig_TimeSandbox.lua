DT_Labour = DT_Labour or {}
DT_Labour.Config = DT_Labour.Config or {}

local Config = DT_Labour.Config

function Config.GetCurrentWorldHours()
    local gt = getGameTime()
    if not gt then return 0 end
    return tonumber(gt:getWorldAgeHours()) or 0
end

function Config.GetCurrentHour()
    return math.floor(Config.GetCurrentWorldHours())
end

function Config.GetSandboxTable()
    return SandboxVars and SandboxVars.DynamicTrading or {}
end

function Config.GetSandboxNumber(key, fallback)
    local sandbox = Config.GetSandboxTable()
    local value = tonumber(sandbox and sandbox[key])
    if value == nil then
        return fallback
    end
    return value
end

function Config.GetLabourDailyCaloriesUse()
    return math.max(0, Config.GetSandboxNumber("LabourDailyCaloriesUse", Config.DEFAULT_LABOUR_DAILY_CALORIES_USE) or Config.DEFAULT_LABOUR_DAILY_CALORIES_USE)
end

function Config.GetLabourDailyHydrationUse()
    return math.max(0, Config.GetSandboxNumber("LabourDailyHydrationUse", Config.DEFAULT_LABOUR_DAILY_HYDRATION_USE) or Config.DEFAULT_LABOUR_DAILY_HYDRATION_USE)
end

function Config.GetDefaultWorkerCarryWeight()
    return math.max(0, Config.GetSandboxNumber("LabourBaseCarryWeight", Config.DEFAULT_WORKER_CARRY_WEIGHT) or Config.DEFAULT_WORKER_CARRY_WEIGHT)
end

function Config.GetScavengeTravelHours()
    return math.max(0, Config.GetSandboxNumber("NPCTradingWalkHours", Config.DEFAULT_SCAVENGE_TRAVEL_HOURS) or Config.DEFAULT_SCAVENGE_TRAVEL_HOURS)
end

local function roundToNearestWhole(value)
    local numeric = tonumber(value) or 0
    if numeric <= 0 then
        return 0
    end
    return math.floor(numeric + 0.5)
end

function Config.GetScavengeBaseWorkAmount()
    local sandbox = Config.GetSandboxTable()
    local configuredAmount = sandbox and sandbox.LabourBaseWorkAmount
    if configuredAmount ~= nil then
        return math.max(1, roundToNearestWhole(configuredAmount))
    end

    local legacyHours = tonumber(sandbox and sandbox.LabourBaseWorkCycleHours)
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
    return math.max(0.01, Config.GetSandboxNumber("LabourBaseWorkMultiplier", Config.DEFAULT_SCAVENGE_BASE_WORK_MULTIPLIER) or Config.DEFAULT_SCAVENGE_BASE_WORK_MULTIPLIER)
end

function Config.GetEffectiveWorkTarget(worker, profile)
    local safeProfile = profile or Config.GetJobProfile(worker and worker.jobType)
    local normalizedJob = Config.NormalizeJobType((worker and worker.jobType) or (safeProfile and safeProfile.jobType))
    if normalizedJob == (Config.JobTypes and Config.JobTypes.Scavenge) then
        return Config.GetScavengeBaseWorkAmount()
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
    return Config.GetLabourDailyCaloriesUse()
end

function Config.GetEffectiveDailyHydrationNeed(worker, profile)
    return Config.GetLabourDailyHydrationUse()
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
