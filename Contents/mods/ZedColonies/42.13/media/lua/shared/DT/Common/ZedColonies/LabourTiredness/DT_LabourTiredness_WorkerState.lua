DT_Labour = DT_Labour or {}
DT_Labour.Tiredness = DT_Labour.Tiredness or {}

local Config = DT_Labour.Config
local Tiredness = DT_Labour.Tiredness

local function clamp(value, minimum, maximum)
    local safeValue = tonumber(value) or 0
    local safeMin = tonumber(minimum) or 0
    local safeMax = tonumber(maximum) or safeMin
    if safeValue < safeMin then
        return safeMin
    end
    if safeValue > safeMax then
        return safeMax
    end
    return safeValue
end

local function hasAnyEntries(source)
    if type(source) ~= "table" then
        return false
    end

    for _ in pairs(source) do
        return true
    end

    return false
end

local function copyNumericMap(source, fallbackKey)
    local map = {}
    for key, value in pairs(type(source) == "table" and source or {}) do
        local numeric = tonumber(value)
        if numeric and numeric > 0 then
            map[key] = numeric
        end
    end

    if not hasAnyEntries(map) and fallbackKey then
        map[fallbackKey] = 1.0
    end

    return map
end

function Tiredness.EnsureWorkerTiredness(worker)
    if not worker then
        return nil
    end

    local tiredness = type(worker.tiredness) == "table" and worker.tiredness or {}
    local maxValue = math.max(1, tonumber(tiredness.max) or Config.GetTirednessMax(worker))
    local lowThreshold = clamp(
        tiredness.lowThreshold,
        0,
        maxValue
    )
    if lowThreshold <= 0 then
        lowThreshold = Config.GetTirednessLowThreshold(worker, maxValue)
    end

    local currentValue = tonumber(tiredness.current)
    if currentValue == nil then
        currentValue = tonumber(worker.tirednessCurrent)
    end
    if currentValue == nil then
        currentValue = maxValue
    end

    tiredness.max = maxValue
    tiredness.lowThreshold = clamp(lowThreshold, 0, maxValue)
    tiredness.current = clamp(currentValue, 0, maxValue)
    tiredness.forcedRest = tiredness.forcedRest == true
    tiredness.recoverySources = copyNumericMap(tiredness.recoverySources, "base")
    tiredness.drainSources = copyNumericMap(tiredness.drainSources, "base")
    tiredness.lastReason = tiredness.lastReason or nil
    worker.tiredness = tiredness

    return tiredness
end

function Tiredness.GetCurrent(worker)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    return tiredness and tiredness.current or 0
end

function Tiredness.GetMax(worker)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    return tiredness and tiredness.max or 1
end

function Tiredness.GetLowThreshold(worker)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    return tiredness and tiredness.lowThreshold or 0
end

function Tiredness.GetRatio(worker)
    local maxValue = math.max(1, Tiredness.GetMax(worker))
    return clamp(Tiredness.GetCurrent(worker) / maxValue, 0, 1)
end

function Tiredness.SetCurrent(worker, value)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    if not tiredness then
        return 0
    end

    tiredness.current = clamp(value, 0, tiredness.max)
    return tiredness.current
end

function Tiredness.IsForcedRest(worker)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    return tiredness and tiredness.forcedRest == true or false
end

function Tiredness.IsDepleted(worker)
    return Tiredness.GetCurrent(worker) <= (Tiredness.GetLowThreshold(worker) + 0.0001)
end

function Tiredness.SetForcedRest(worker, forcedRest, reason)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    if not tiredness then
        return false
    end

    local nextValue = forcedRest == true
    local changed = tiredness.forcedRest ~= nextValue
    tiredness.forcedRest = nextValue

    if nextValue then
        tiredness.lastReason = reason or tiredness.lastReason or (Config.ReturnReasons and Config.ReturnReasons.LowTiredness) or "LowTiredness"
    elseif changed then
        tiredness.lastReason = nil
    end

    return changed
end

function Tiredness.SetRecoverySources(worker, sources)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    if tiredness then
        tiredness.recoverySources = copyNumericMap(sources, "base")
    end
end

function Tiredness.SetDrainSources(worker, sources)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    if tiredness then
        tiredness.drainSources = copyNumericMap(sources, "base")
    end
end

function Tiredness.ApplyPresentationFields(worker)
    local tiredness = Tiredness.EnsureWorkerTiredness(worker)
    if not tiredness then
        return
    end

    local recoveryMultiplier = 1.0
    if Tiredness.GetRecoveryMultiplier then
        recoveryMultiplier = Tiredness.GetRecoveryMultiplier(worker)
    end

    worker.tirednessCurrent = tiredness.current
    worker.tirednessMax = tiredness.max
    worker.tirednessRatio = Tiredness.GetRatio(worker)
    worker.tirednessLowThreshold = tiredness.lowThreshold
    worker.isRestingForTiredness = tiredness.forcedRest == true
    worker.tirednessRecoveryMultiplier = recoveryMultiplier
end

return Tiredness
