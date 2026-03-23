DT_Buildings = DT_Buildings or {}
DT_Buildings.Internal = DT_Buildings.Internal or {}

local Buildings = DT_Buildings
local Config = Buildings.Config

local function getRegistry()
    return DT_Labour and DT_Labour.Registry or nil
end

local function getWarehouse()
    return DT_Labour and DT_Labour.Warehouse or nil
end

local function isLivingWorker(worker)
    local deadState = DT_Labour
        and DT_Labour.Config
        and DT_Labour.Config.States
        and DT_Labour.Config.States.Dead
        or "Dead"
    return worker and tostring(worker.state or "") ~= tostring(deadState)
end

local function getLivingWorkers(ownerUsername)
    local registry = getRegistry()
    local workers = registry and registry.GetWorkersForOwnerRaw and registry.GetWorkersForOwnerRaw(ownerUsername)
        or registry and registry.GetWorkersForOwner and registry.GetWorkersForOwner(ownerUsername)
        or {}
    local living = {}
    for _, worker in ipairs(workers or {}) do
        if isLivingWorker(worker) then
            living[#living + 1] = worker
        end
    end

    table.sort(living, function(a, b)
        return tostring(a.workerID or "") < tostring(b.workerID or "")
    end)
    return living
end

local function getBarracksInstances(ownerUsername)
    local instances = {}
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if tostring(instance.buildingType or "") == "Barracks" and tonumber(instance.level) and tonumber(instance.level) > 0 then
            instances[#instances + 1] = instance
        end
    end

    table.sort(instances, function(a, b)
        if tonumber(a.level) == tonumber(b.level) then
            return tostring(a.buildingID or "") < tostring(b.buildingID or "")
        end
        return tonumber(a.level) > tonumber(b.level)
    end)
    return instances
end

local function getInfirmaryInstances(ownerUsername)
    local instances = {}
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(ownerUsername)) do
        if tostring(instance.buildingType or "") == "Infirmary" and tonumber(instance.level) and tonumber(instance.level) > 0 then
            instances[#instances + 1] = instance
        end
    end

    table.sort(instances, function(a, b)
        if tonumber(a.level) == tonumber(b.level) then
            return tostring(a.buildingID or "") < tostring(b.buildingID or "")
        end
        return tonumber(a.level) > tonumber(b.level)
    end)
    return instances
end

local function isSleepEligibleWorker(worker)
    return isLivingWorker(worker)
        and tostring(worker and worker.presenceState or "") == tostring((DT_Labour and DT_Labour.Config and DT_Labour.Config.PresenceStates and DT_Labour.Config.PresenceStates.Home) or "Home")
        and (DT_Labour and DT_Labour.Tiredness and DT_Labour.Tiredness.IsForcedRest and DT_Labour.Tiredness.IsForcedRest(worker) or false)
        and math.max(0, tonumber(worker and worker.hp) or 0) > 0
end

local function compareMedicalPriority(a, b)
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

local function isDoctorAvailable(worker)
    local labourConfig = DT_Labour and DT_Labour.Config or {}
    return isLivingWorker(worker)
        and tostring(labourConfig.NormalizeJobType and labourConfig.NormalizeJobType(worker and worker.jobType) or worker and worker.jobType or "") == tostring((labourConfig.JobTypes or {}).Doctor or "Doctor")
        and worker.jobEnabled == true
        and tostring(worker and worker.presenceState or "") == tostring((labourConfig.PresenceStates or {}).Home or "Home")
        and not (DT_Labour and DT_Labour.Tiredness and DT_Labour.Tiredness.IsForcedRest and DT_Labour.Tiredness.IsForcedRest(worker) or false)
        and math.max(0, tonumber(worker and worker.hp) or 0) > 0
end

local function getSleepingWorkers(ownerUsername)
    local registry = getRegistry()
    local workers = registry and registry.GetWorkersForOwnerRaw and registry.GetWorkersForOwnerRaw(ownerUsername)
        or registry and registry.GetWorkersForOwner and registry.GetWorkersForOwner(ownerUsername)
        or {}
    local sleepingWorkers = {}
    local activeDoctors = {}
    for _, worker in ipairs(workers or {}) do
        if isSleepEligibleWorker(worker) then
            sleepingWorkers[#sleepingWorkers + 1] = worker
        end
        if isDoctorAvailable(worker) then
            activeDoctors[#activeDoctors + 1] = worker
        end
    end

    table.sort(sleepingWorkers, compareMedicalPriority)
    table.sort(activeDoctors, function(a, b)
        return tostring(a and a.workerID or "") < tostring(b and b.workerID or "")
    end)
    return sleepingWorkers, activeDoctors
end

local function getInfirmaryInstanceCapacity(instance)
    local level = math.max(0, math.floor(tonumber(instance and instance.level) or 0))
    local baseCapacity = Config.GetInfirmaryBaseCapacity and Config.GetInfirmaryBaseCapacity(level) or 0
    local bedCount = Buildings.GetBuildingInstallCount and Buildings.GetBuildingInstallCount(instance, "bed") or 0
    local maxBeds = Config.GetInstallMaxCount and Config.GetInstallMaxCount("Infirmary", "bed", level) or bedCount
    local cappedBeds = math.min(math.max(0, bedCount), math.max(0, maxBeds))
    local maxCapacity = Config.GetInfirmaryCapacityCap and Config.GetInfirmaryCapacityCap(level) or (level * 5)
    return {
        level = level,
        baseCapacity = baseCapacity,
        installedBeds = cappedBeds,
        maxCapacity = maxCapacity,
        capacity = math.min(maxCapacity, baseCapacity + cappedBeds)
    }
end

function Buildings.BuildHousingAssignment(ownerUsername)
    local workers = getLivingWorkers(ownerUsername)
    local barracksInstances = getBarracksInstances(ownerUsername)
    local assignments = {}
    local housedCount = 0
    local capacity = 0
    local buildingSummaries = {}
    local workerIndex = 1

    for _, instance in ipairs(barracksInstances) do
        local level = math.max(0, math.floor(tonumber(instance.level) or 0))
        local slots = Config.GetBarracksSlotsForLevel(level)
        local recoveryMultiplier = Config.GetBarracksRecoveryMultiplier(level)
        capacity = capacity + slots

        local summary = {
            buildingID = instance.buildingID,
            buildingType = instance.buildingType,
            level = level,
            slots = slots,
            occupied = 0,
            recoveryMultiplier = recoveryMultiplier,
            occupants = {}
        }

        for slotIndex = 1, slots do
            local worker = workers[workerIndex]
            if not worker then
                break
            end

            assignments[worker.workerID] = {
                housingState = "Housed",
                buildingID = instance.buildingID,
                buildingType = instance.buildingType,
                buildingLevel = level,
                recoveryMultiplier = recoveryMultiplier,
                slotIndex = slotIndex
            }
            housedCount = housedCount + 1
            summary.occupied = summary.occupied + 1
            summary.occupants[#summary.occupants + 1] = {
                workerID = worker.workerID,
                name = worker.name or worker.workerID
            }
            workerIndex = workerIndex + 1
        end

        buildingSummaries[#buildingSummaries + 1] = summary
    end

    for index = workerIndex, #workers do
        local worker = workers[index]
        assignments[worker.workerID] = {
            housingState = "Unhoused",
            buildingID = nil,
            buildingType = nil,
            buildingLevel = 0,
            recoveryMultiplier = Config.GetUnhousedRecoveryMultiplier(),
            slotIndex = nil
        }
    end

    return {
        assignments = assignments,
        buildings = buildingSummaries,
        capacity = capacity,
        housedCount = housedCount,
        unhousedCount = math.max(0, #workers - housedCount),
        livingWorkers = #workers
    }
end

function Buildings.BuildInfirmaryAssignment(ownerUsername)
    local sleepingWorkers, activeDoctors = getSleepingWorkers(ownerUsername)
    local infirmaryInstances = getInfirmaryInstances(ownerUsername)
    local assignments = {}
    local buildingSummaries = {}
    local occupantsByWorkerID = {}
    local assignedWorkers = {}
    local totalCapacity = 0
    local workerIndex = 1
    local assignedWorkerIDs = {}
    local doctorCoveredWorkerIDs = {}

    for _, instance in ipairs(infirmaryInstances) do
        local capacityState = getInfirmaryInstanceCapacity(instance)
        totalCapacity = totalCapacity + capacityState.capacity

        local summary = {
            buildingID = instance.buildingID,
            buildingType = instance.buildingType,
            level = capacityState.level,
            baseCapacity = capacityState.baseCapacity,
            installedBeds = capacityState.installedBeds,
            maxCapacity = capacityState.maxCapacity,
            capacity = capacityState.capacity,
            occupied = 0,
            occupants = {}
        }

        for slotIndex = 1, capacityState.capacity do
            local worker = sleepingWorkers[workerIndex]
            if not worker then
                break
            end

            local occupant = {
                workerID = worker.workerID,
                name = worker.name or worker.workerID,
                hp = math.max(0, tonumber(worker.hp) or 0),
                maxHp = math.max(1, tonumber(worker.maxHp) or 1),
                slotIndex = slotIndex,
                doctorCovered = false
            }

            assignments[worker.workerID] = {
                sleepEligible = true,
                assigned = true,
                buildingID = instance.buildingID,
                buildingType = instance.buildingType,
                buildingLevel = capacityState.level,
                slotIndex = slotIndex,
                doctorCovered = false
            }
            summary.occupied = summary.occupied + 1
            summary.occupants[#summary.occupants + 1] = occupant
            occupantsByWorkerID[worker.workerID] = occupant
            assignedWorkers[#assignedWorkers + 1] = worker
            assignedWorkerIDs[#assignedWorkerIDs + 1] = worker.workerID
            workerIndex = workerIndex + 1
        end

        buildingSummaries[#buildingSummaries + 1] = summary
    end

    local doctorCoverageSlots = #activeDoctors * 5
    local doctorCoveredCount = math.min(#assignedWorkers, doctorCoverageSlots)
    for index, worker in ipairs(assignedWorkers) do
        if index > doctorCoveredCount then
            break
        end

        if assignments[worker.workerID] then
            assignments[worker.workerID].doctorCovered = true
        end
        if occupantsByWorkerID[worker.workerID] then
            occupantsByWorkerID[worker.workerID].doctorCovered = true
        end
        doctorCoveredWorkerIDs[#doctorCoveredWorkerIDs + 1] = worker.workerID
    end

    for _, worker in ipairs(sleepingWorkers) do
        assignments[worker.workerID] = assignments[worker.workerID] or {
            sleepEligible = true,
            assigned = false,
            buildingID = nil,
            buildingType = nil,
            buildingLevel = 0,
            slotIndex = nil,
            doctorCovered = false
        }
    end

    local warehouse = getWarehouse()
    local treatmentHourBudget = warehouse and warehouse.GetMedicalProvisionHourBudget and warehouse.GetMedicalProvisionHourBudget(ownerUsername) or 0

    return {
        assignments = assignments,
        buildings = buildingSummaries,
        assignedWorkerIDs = assignedWorkerIDs,
        doctorCoveredWorkerIDs = doctorCoveredWorkerIDs,
        sleepingWorkers = #sleepingWorkers,
        assignedCount = #assignedWorkers,
        totalCapacity = totalCapacity,
        doctorCount = #activeDoctors,
        doctorCoverageSlots = doctorCoverageSlots,
        doctorCoveredCount = doctorCoveredCount,
        treatmentHourBudget = math.max(0, tonumber(treatmentHourBudget) or 0),
        hasMedicalSupplies = treatmentHourBudget > 0
    }
end

function Buildings.GetWorkerInfirmary(ownerUsername, workerID)
    local summary = Buildings.BuildInfirmaryAssignment(ownerUsername)
    return summary.assignments[tostring(workerID or "")] or {
        sleepEligible = false,
        assigned = false,
        buildingID = nil,
        buildingType = nil,
        buildingLevel = 0,
        slotIndex = nil,
        doctorCovered = false
    }
end

function Buildings.GetWorkerHousing(ownerUsername, workerID)
    local summary = Buildings.BuildHousingAssignment(ownerUsername)
    return summary.assignments[tostring(workerID or "")] or {
        housingState = "Unhoused",
        buildingID = nil,
        buildingType = nil,
        buildingLevel = 0,
        recoveryMultiplier = Config.GetUnhousedRecoveryMultiplier(),
        slotIndex = nil
    }
end

return Buildings
