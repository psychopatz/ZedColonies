DC_Colony = DC_Colony or {}
DC_Colony.Energy = DC_Colony.Energy or {}

local Config = DC_Colony.Config

Config.DEFAULT_ENERGY_MAX = 100
Config.DEFAULT_ENERGY_LOW_THRESHOLD_RATIO = 0.10
Config.DEFAULT_ENERGY_WORK_DRAIN_PER_HOUR = 8
Config.DEFAULT_ENERGY_SCAVENGE_WORK_DRAIN_MULTIPLIER = 1.15
Config.DEFAULT_ENERGY_TRAVEL_DRAIN_PER_HOUR = 2
Config.DEFAULT_ENERGY_HOME_RECOVERY_PER_HOUR = 12

-- Backwards compatibility
Config.DEFAULT_TIREDNESS_MAX = Config.DEFAULT_ENERGY_MAX
Config.DEFAULT_TIREDNESS_LOW_THRESHOLD_RATIO = Config.DEFAULT_ENERGY_LOW_THRESHOLD_RATIO
Config.DEFAULT_TIREDNESS_WORK_DRAIN_PER_HOUR = Config.DEFAULT_ENERGY_WORK_DRAIN_PER_HOUR
Config.DEFAULT_TIREDNESS_SCAVENGE_WORK_DRAIN_MULTIPLIER = Config.DEFAULT_ENERGY_SCAVENGE_WORK_DRAIN_MULTIPLIER
Config.DEFAULT_TIREDNESS_TRAVEL_DRAIN_PER_HOUR = Config.DEFAULT_ENERGY_TRAVEL_DRAIN_PER_HOUR
Config.DEFAULT_TIREDNESS_HOME_RECOVERY_PER_HOUR = Config.DEFAULT_ENERGY_HOME_RECOVERY_PER_HOUR

function Config.GetEnergyMax(worker)
    return math.max(1, tonumber(Config.DEFAULT_ENERGY_MAX) or 100)
end

function Config.GetEnergyLowThresholdRatio()
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_LOW_THRESHOLD_RATIO) or 0.10)
end

function Config.GetEnergyLowThreshold(worker, maxValue)
    local safeMax = math.max(1, tonumber(maxValue) or Config.GetEnergyMax(worker))
    return math.max(0, math.min(safeMax, safeMax * Config.GetEnergyLowThresholdRatio()))
end

function Config.GetEnergyBaseWorkDrainPerHour()
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_WORK_DRAIN_PER_HOUR) or 8)
end

function Config.GetEnergyScavengeWorkDrainMultiplier()
    return math.max(0.01, tonumber(Config.DEFAULT_ENERGY_SCAVENGE_WORK_DRAIN_MULTIPLIER) or 1.15)
end

function Config.GetEnergyTravelDrainPerHour(worker, profile)
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_TRAVEL_DRAIN_PER_HOUR) or 2)
end

function Config.GetEnergyHomeRecoveryPerHour(worker, profile)
    return math.max(0, tonumber(Config.DEFAULT_ENERGY_HOME_RECOVERY_PER_HOUR) or 12)
end

-- Aliases for Tiredness functions
Config.GetTirednessMax = Config.GetEnergyMax
Config.GetTirednessLowThresholdRatio = Config.GetEnergyLowThresholdRatio
Config.GetTirednessLowThreshold = Config.GetEnergyLowThreshold
Config.GetTirednessBaseWorkDrainPerHour = Config.GetEnergyBaseWorkDrainPerHour
Config.GetTirednessScavengeWorkDrainMultiplier = Config.GetEnergyScavengeWorkDrainMultiplier
Config.GetTirednessTravelDrainPerHour = Config.GetEnergyTravelDrainPerHour
Config.GetTirednessHomeRecoveryPerHour = Config.GetEnergyHomeRecoveryPerHour

return DC_Colony.Energy

