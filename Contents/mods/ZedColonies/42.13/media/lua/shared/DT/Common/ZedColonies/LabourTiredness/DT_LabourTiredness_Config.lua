DT_Labour = DT_Labour or {}
DT_Labour.Tiredness = DT_Labour.Tiredness or {}

local Config = DT_Labour.Config

Config.DEFAULT_TIREDNESS_MAX = 100
Config.DEFAULT_TIREDNESS_LOW_THRESHOLD_RATIO = 0.10
Config.DEFAULT_TIREDNESS_WORK_DRAIN_PER_HOUR = 4
Config.DEFAULT_TIREDNESS_SCAVENGE_WORK_DRAIN_MULTIPLIER = 1.15
Config.DEFAULT_TIREDNESS_TRAVEL_DRAIN_PER_HOUR = 1
Config.DEFAULT_TIREDNESS_HOME_RECOVERY_PER_HOUR = 6

function Config.GetTirednessMax(worker)
    return math.max(1, tonumber(Config.DEFAULT_TIREDNESS_MAX) or 100)
end

function Config.GetTirednessLowThresholdRatio()
    return math.max(0, tonumber(Config.DEFAULT_TIREDNESS_LOW_THRESHOLD_RATIO) or 0.10)
end

function Config.GetTirednessLowThreshold(worker, maxValue)
    local safeMax = math.max(1, tonumber(maxValue) or Config.GetTirednessMax(worker))
    return math.max(0, math.min(safeMax, safeMax * Config.GetTirednessLowThresholdRatio()))
end

function Config.GetTirednessBaseWorkDrainPerHour()
    return math.max(0, tonumber(Config.DEFAULT_TIREDNESS_WORK_DRAIN_PER_HOUR) or 4)
end

function Config.GetTirednessScavengeWorkDrainMultiplier()
    return math.max(0.01, tonumber(Config.DEFAULT_TIREDNESS_SCAVENGE_WORK_DRAIN_MULTIPLIER) or 1.15)
end

function Config.GetTirednessTravelDrainPerHour(worker, profile)
    return math.max(0, tonumber(Config.DEFAULT_TIREDNESS_TRAVEL_DRAIN_PER_HOUR) or 1)
end

function Config.GetTirednessHomeRecoveryPerHour(worker, profile)
    return math.max(0, tonumber(Config.DEFAULT_TIREDNESS_HOME_RECOVERY_PER_HOUR) or 6)
end

return DT_Labour.Tiredness
