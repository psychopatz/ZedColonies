DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Housing = Buildings.Internal.Housing or {}

Buildings.Internal.Housing = Housing

function Housing.GetInfirmaryInstanceCapacity(instance)
    local config = Housing.Config or Buildings.Config
    local level = math.max(0, math.floor(tonumber(instance and instance.level) or 0))
    local baseCapacity = config.GetInfirmaryBaseCapacity and config.GetInfirmaryBaseCapacity(level) or 0
    local bedCount = Buildings.GetBuildingInstallCount and Buildings.GetBuildingInstallCount(instance, "bed") or 0
    local maxBeds = config.GetInstallMaxCount and config.GetInstallMaxCount("Infirmary", "bed", level) or bedCount
    local cappedBeds = math.min(math.max(0, bedCount), math.max(0, maxBeds))
    local maxCapacity = config.GetInfirmaryCapacityCap and config.GetInfirmaryCapacityCap(level) or (level * 5)
    return {
        level = level,
        baseCapacity = baseCapacity,
        installedBeds = cappedBeds,
        maxCapacity = maxCapacity,
        capacity = math.min(maxCapacity, baseCapacity + cappedBeds)
    }
end

function Buildings.BuildInfirmaryAssignment(ownerUsername)
    local sleepingWorkers, activeDoctors = Housing.GetSleepingWorkers(ownerUsername)
    local infirmaryInstances = Housing.GetInfirmaryInstances(ownerUsername)
    local assignments = {}
    local buildingSummaries = {}
    local occupantsByWorkerID = {}
    local assignedWorkers = {}
    local totalCapacity = 0
    local workerIndex = 1
    local assignedWorkerIDs = {}
    local doctorCoveredWorkerIDs = {}

    for _, instance in ipairs(infirmaryInstances) do
        local capacityState = Housing.GetInfirmaryInstanceCapacity(instance)
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

    local warehouse = Housing.GetWarehouse()
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

return Buildings