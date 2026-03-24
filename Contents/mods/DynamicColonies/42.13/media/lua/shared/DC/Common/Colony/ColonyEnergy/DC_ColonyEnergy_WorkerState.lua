DC_Colony = DC_Colony or {}
DC_Colony.Energy = DC_Colony.Energy or {}

local Config = DC_Colony.Config
local Energy = DC_Colony.Energy

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

function Energy.EnsureWorkerEnergy(worker)
    if not worker then
        return nil
    end

    local energy = type(worker.energy) == "table" and worker.energy or {}
    local maxValue = math.max(1, tonumber(energy.max) or (Config.GetEnergyMax and Config.GetEnergyMax(worker)) or (Config.GetTirednessMax and Config.GetTirednessMax(worker)) or 100)
    local lowThreshold = clamp(
        energy.lowThreshold,
        0,
        maxValue
    )
    if lowThreshold <= 0 then
        lowThreshold = (Config.GetEnergyLowThreshold and Config.GetEnergyLowThreshold(worker, maxValue)) or (Config.GetTirednessLowThreshold and Config.GetTirednessLowThreshold(worker, maxValue)) or (maxValue * 0.1)
    end

    local currentValue = tonumber(energy.current)
    if currentValue == nil then
        currentValue = tonumber(worker.energyCurrent) or tonumber(worker.tirednessCurrent)
    end
    if currentValue == nil then
        currentValue = maxValue
    end

    energy.max = maxValue
    energy.lowThreshold = clamp(lowThreshold, 0, maxValue)
    energy.current = clamp(currentValue, 0, maxValue)
    energy.forcedRest = energy.forcedRest == true
    energy.recoverySources = copyNumericMap(energy.recoverySources, "base")
    energy.drainSources = copyNumericMap(energy.drainSources, "base")
    energy.lastReason = energy.lastReason or nil
    
    -- Track when rest started to enforce the 10-hour cap
    energy.restStartedHour = tonumber(energy.restStartedHour) or nil

    worker.energy = energy

    return energy
end

function Energy.GetCurrent(worker)
    local energy = Energy.EnsureWorkerEnergy(worker)
    return energy and energy.current or 0
end

function Energy.GetMax(worker)
    local energy = Energy.EnsureWorkerEnergy(worker)
    return energy and energy.max or 1
end

function Energy.GetLowThreshold(worker)
    local energy = Energy.EnsureWorkerEnergy(worker)
    return energy and energy.lowThreshold or 0
end

function Energy.GetRatio(worker)
    local maxValue = math.max(1, Energy.GetMax(worker))
    return clamp(Energy.GetCurrent(worker) / maxValue, 0, 1)
end

function Energy.SetCurrent(worker, value)
    local energy = Energy.EnsureWorkerEnergy(worker)
    if not energy then
        return 0
    end

    energy.current = clamp(value, 0, energy.max)
    return energy.current
end

function Energy.IsForcedRest(worker)
    local energy = Energy.EnsureWorkerEnergy(worker)
    return energy and energy.forcedRest == true or false
end

function Energy.IsDepleted(worker)
    return Energy.GetCurrent(worker) <= (Energy.GetLowThreshold(worker) + 0.0001)
end

function Energy.SetForcedRest(worker, forcedRest, reason, currentHour)
    local energy = Energy.EnsureWorkerEnergy(worker)
    if not energy then
        return false
    end

    local nextValue = forcedRest == true
    local changed = energy.forcedRest ~= nextValue
    energy.forcedRest = nextValue

    if nextValue then
        energy.lastReason = reason or energy.lastReason or (Config.ReturnReasons and (Config.ReturnReasons.LowEnergy or Config.ReturnReasons.LowTiredness)) or "LowEnergy"
        -- Mark rest start time if just starting
        if changed then
            energy.restStartedHour = tonumber(currentHour) or nil
        end
    elseif changed then
        energy.lastReason = nil
        energy.restStartedHour = nil
    end

    return changed
end

function Energy.SetRecoverySources(worker, sources)
    local energy = Energy.EnsureWorkerEnergy(worker)
    if energy then
        energy.recoverySources = copyNumericMap(sources, "base")
    end
end

function Energy.SetDrainSources(worker, sources)
    local energy = Energy.EnsureWorkerEnergy(worker)
    if energy then
        energy.drainSources = copyNumericMap(sources, "base")
    end
end

function Energy.ApplyPresentationFields(worker)
    local energy = Energy.EnsureWorkerEnergy(worker)
    if not energy then
        return
    end

    local recoveryMultiplier = 1.0
    if Energy.GetRecoveryMultiplier then
        recoveryMultiplier = Energy.GetRecoveryMultiplier(worker)
    end

    worker.energyCurrent = energy.current
    worker.energyMax = energy.max
    worker.energyRatio = Energy.GetRatio(worker)
    worker.energyLowThreshold = energy.lowThreshold
    worker.isRestingForEnergy = energy.forcedRest == true
    worker.energyRecoveryMultiplier = recoveryMultiplier
    
    -- Maintain compatibility for now or cleanup if all UI updated
    worker.tirednessCurrent = energy.current
    worker.tirednessMax = energy.max
    worker.tirednessRatio = worker.energyRatio
    worker.isRestingForTiredness = worker.isRestingForEnergy
end

return Energy

