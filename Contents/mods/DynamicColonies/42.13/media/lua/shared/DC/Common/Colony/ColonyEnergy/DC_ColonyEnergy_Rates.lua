DC_Colony = DC_Colony or {}
DC_Colony.Energy = DC_Colony.Energy or {}

local Config = DC_Colony.Config
local Energy = DC_Colony.Energy

local function hasAnyEntries(source)
    if type(source) ~= "table" then
        return false
    end

    for _ in pairs(source) do
        return true
    end

    return false
end

local function multiplySources(sources)
    local total = 1.0
    for _, value in pairs(type(sources) == "table" and sources or {}) do
        local numeric = tonumber(value)
        if numeric and numeric > 0 then
            total = total * numeric
        end
    end
    return math.max(0.01, total)
end

function Energy.GetRecoverySources(worker, profile)
    local energy = Energy.EnsureWorkerEnergy(worker)
    if not energy then
        return { base = 1.0 }
    end

    energy.recoverySources = type(energy.recoverySources) == "table" and energy.recoverySources or {}
    if not hasAnyEntries(energy.recoverySources) then
        energy.recoverySources.base = 1.0
    end
    return energy.recoverySources
end

function Energy.GetDrainSources(worker, profile)
    local energy = Energy.EnsureWorkerEnergy(worker)
    if not energy then
        return { base = 1.0 }
    end

    energy.drainSources = type(energy.drainSources) == "table" and energy.drainSources or {}
    if not hasAnyEntries(energy.drainSources) then
        energy.drainSources.base = 1.0
    end
    return energy.drainSources
end

function Energy.GetRecoveryMultiplier(worker, profile)
    return multiplySources(Energy.GetRecoverySources(worker, profile))
end

function Energy.GetDrainMultiplier(worker, profile)
    return multiplySources(Energy.GetDrainSources(worker, profile))
end

function Energy.GetWorkDrainPerHour(worker, profile)
    local drainPerHour = (Config.GetEnergyBaseWorkDrainPerHour and Config.GetEnergyBaseWorkDrainPerHour()) or (Config.GetTirednessBaseWorkDrainPerHour and Config.GetTirednessBaseWorkDrainPerHour()) or 1.0
    drainPerHour = drainPerHour * Energy.GetDrainMultiplier(worker, profile)

    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker and worker.jobType) or nil
    if normalizedJob == ((Config.JobTypes or {}).Scavenge) then
        drainPerHour = drainPerHour * ((Config.GetEnergyScavengeWorkDrainMultiplier and Config.GetEnergyScavengeWorkDrainMultiplier()) or (Config.GetTirednessScavengeWorkDrainMultiplier and Config.GetTirednessScavengeWorkDrainMultiplier()) or 1.0)
    end

    return math.max(0, drainPerHour)
end

function Energy.GetTravelDrainPerHour(worker, profile)
    local baseDrain = (Config.GetEnergyTravelDrainPerHour and Config.GetEnergyTravelDrainPerHour(worker, profile)) or (Config.GetTirednessTravelDrainPerHour and Config.GetTirednessTravelDrainPerHour(worker, profile)) or 0.5
    return math.max(0, baseDrain * Energy.GetDrainMultiplier(worker, profile))
end

function Energy.GetHomeRecoveryPerHour(worker, profile)
    local baseRecovery = (Config.GetEnergyHomeRecoveryPerHour and Config.GetEnergyHomeRecoveryPerHour(worker, profile)) or (Config.GetTirednessHomeRecoveryPerHour and Config.GetTirednessHomeRecoveryPerHour(worker, profile)) or 2.0
    return math.max(0, baseRecovery * Energy.GetRecoveryMultiplier(worker, profile))
end

return Energy

