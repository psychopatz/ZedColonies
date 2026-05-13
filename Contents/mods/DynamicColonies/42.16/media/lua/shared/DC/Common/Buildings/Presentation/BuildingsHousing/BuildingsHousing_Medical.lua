DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Housing = Buildings.Internal.Housing or {}

Buildings.Internal.Housing = Housing

function Housing.IsSleepEligibleWorker(worker)
    local health = DC_Colony and DC_Colony.Health or nil
    local forcedRest = DC_Colony and DC_Colony.Energy and DC_Colony.Energy.IsForcedRest and DC_Colony.Energy.IsForcedRest(worker) or false
    if health and health.IsSleepEligible then
        return health.IsSleepEligible(worker, forcedRest)
    end

    return Housing.IsLivingWorker(worker)
        and tostring(worker and worker.presenceState or "") == tostring((DC_Colony and DC_Colony.Config and DC_Colony.Config.PresenceStates and DC_Colony.Config.PresenceStates.Home) or "Home")
        and forcedRest == true
end

function Housing.CompareMedicalPriority(a, b)
    local aMaxHp = math.max(1, tonumber(a and a.maxHp) or 1)
    local bMaxHp = math.max(1, tonumber(b and b.maxHp) or 1)
    local aHp = math.max(0, tonumber(a and a.hp) or 0)
    local bHp = math.max(0, tonumber(b and b.hp) or 0)
    local aRatio = aHp / aMaxHp
    local bRatio = bHp / bMaxHp
    if math.abs(aRatio - bRatio) > 0.0001 then
        return aRatio < bRatio
    end
    if math.abs(aHp - bHp) > 0.0001 then
        return aHp < bHp
    end
    return tostring(a and a.workerID or "") < tostring(b and b.workerID or "")
end

function Housing.IsDoctorAvailable(worker)
    local labourConfig = DC_Colony and DC_Colony.Config or {}
    return Housing.IsLivingWorker(worker)
        and tostring(labourConfig.NormalizeJobType and labourConfig.NormalizeJobType(worker and worker.jobType) or worker and worker.jobType or "") == tostring((labourConfig.JobTypes or {}).Doctor or "Doctor")
        and worker.jobEnabled == true
        and tostring(worker and worker.presenceState or "") == tostring((labourConfig.PresenceStates or {}).Home or "Home")
        and not (DC_Colony and DC_Colony.Energy and DC_Colony.Energy.IsForcedRest and DC_Colony.Energy.IsForcedRest(worker) or false)
        and math.max(0, tonumber(worker and worker.hp) or 0) > 0
end

function Housing.GetSleepingWorkers(ownerUsername)
    local registry = Housing.GetRegistry()
    local workers = registry and registry.GetWorkersForOwnerRaw and registry.GetWorkersForOwnerRaw(ownerUsername)
        or registry and registry.GetWorkersForOwner and registry.GetWorkersForOwner(ownerUsername)
        or {}
    local sleepingWorkers = {}
    local activeDoctors = {}
    for _, worker in ipairs(workers or {}) do
        if Housing.IsSleepEligibleWorker(worker) then
            sleepingWorkers[#sleepingWorkers + 1] = worker
        end
        if Housing.IsDoctorAvailable(worker) then
            activeDoctors[#activeDoctors + 1] = worker
        end
    end

    table.sort(sleepingWorkers, Housing.CompareMedicalPriority)
    table.sort(activeDoctors, function(a, b)
        return tostring(a and a.workerID or "") < tostring(b and b.workerID or "")
    end)
    return sleepingWorkers, activeDoctors
end

return Buildings