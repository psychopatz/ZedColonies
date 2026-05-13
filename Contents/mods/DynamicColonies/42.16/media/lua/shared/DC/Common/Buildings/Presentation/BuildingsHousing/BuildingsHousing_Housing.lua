DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Housing = Buildings.Internal.Housing or {}

Buildings.Internal.Housing = Housing

function Buildings.BuildHousingAssignment(ownerUsername)
    local config = Housing.Config or Buildings.Config
    local workers = Housing.GetLivingWorkers(ownerUsername)
    local barracksInstances = Housing.GetBarracksInstances(ownerUsername)
    local assignments = {}
    local housedCount = 0
    local capacity = 0
    local buildingSummaries = {}
    local workerIndex = 1

    for _, instance in ipairs(barracksInstances) do
        local level = math.max(0, math.floor(tonumber(instance.level) or 0))
        local slots = config.GetBarracksSlotsForLevel(level)
        local recoveryMultiplier = config.GetBarracksRecoveryMultiplier(level)
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
            recoveryMultiplier = config.GetUnhousedRecoveryMultiplier(),
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

return Buildings