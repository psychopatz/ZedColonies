DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Housing = Buildings.Internal.Housing or {}

Buildings.Internal.Housing = Housing

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
    local config = Housing.Config or Buildings.Config
    local summary = Buildings.BuildHousingAssignment(ownerUsername)
    return summary.assignments[tostring(workerID or "")] or {
        housingState = "Unhoused",
        buildingID = nil,
        buildingType = nil,
        buildingLevel = 0,
        recoveryMultiplier = config.GetUnhousedRecoveryMultiplier(),
        slotIndex = nil
    }
end

return Buildings