DT_Labour = DT_Labour or {}
DT_Labour.Tiredness = DT_Labour.Tiredness or {}

local Config = DT_Labour.Config
local Tiredness = DT_Labour.Tiredness

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

function Tiredness.GetRecoverySources(worker, profile)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    if not tiredness then
        return { base = 1.0 }
    end

    tiredness.recoverySources = type(tiredness.recoverySources) == "table" and tiredness.recoverySources or {}
    if not hasAnyEntries(tiredness.recoverySources) then
        tiredness.recoverySources.base = 1.0
    end
    return tiredness.recoverySources
end

function Tiredness.GetDrainSources(worker, profile)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    if not tiredness then
        return { base = 1.0 }
    end

    tiredness.drainSources = type(tiredness.drainSources) == "table" and tiredness.drainSources or {}
    if not hasAnyEntries(tiredness.drainSources) then
        tiredness.drainSources.base = 1.0
    end
    return tiredness.drainSources
end

function Tiredness.GetRecoveryMultiplier(worker, profile)
    return multiplySources(Tiredness.GetRecoverySources(worker, profile))
end

function Tiredness.GetDrainMultiplier(worker, profile)
    return multiplySources(Tiredness.GetDrainSources(worker, profile))
end

function Tiredness.GetWorkDrainPerHour(worker, profile)
    local drainPerHour = Config.GetTirednessBaseWorkDrainPerHour()
    drainPerHour = drainPerHour * Tiredness.GetDrainMultiplier(worker, profile)

    local normalizedJob = Config.NormalizeJobType and Config.NormalizeJobType(worker and worker.jobType) or nil
    if normalizedJob == ((Config.JobTypes or {}).Scavenge) then
        drainPerHour = drainPerHour * Config.GetTirednessScavengeWorkDrainMultiplier()
    end

    return math.max(0, drainPerHour)
end

function Tiredness.GetTravelDrainPerHour(worker, profile)
    return math.max(0, Config.GetTirednessTravelDrainPerHour(worker, profile) * Tiredness.GetDrainMultiplier(worker, profile))
end

function Tiredness.GetHomeRecoveryPerHour(worker, profile)
    return math.max(0, Config.GetTirednessHomeRecoveryPerHour(worker, profile) * Tiredness.GetRecoveryMultiplier(worker, profile))
end

return Tiredness
