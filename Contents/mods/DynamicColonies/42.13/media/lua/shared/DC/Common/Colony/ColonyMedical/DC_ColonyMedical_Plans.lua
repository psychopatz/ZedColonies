DC_Colony = DC_Colony or {}
DC_Colony.Medical = DC_Colony.Medical or {}

local Config = DC_Colony.Config
local Medical = DC_Colony.Medical

Medical.Internal = Medical.Internal or {}
Medical.Internal.ownerMedicalPlans = {}

local function getBuildings()
    return DC_Buildings or nil
end

local function getOwnerKey(ownerUsername)
    return Config.GetOwnerUsername and Config.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
end

function Medical.BuildOwnerPlan(ownerUsername)
    local buildings = getBuildings()
    local infirmary = buildings and buildings.BuildInfirmaryAssignment and buildings.BuildInfirmaryAssignment(ownerUsername) or nil
    if not infirmary then
        infirmary = {
            assignments = {},
            doctorCoveredWorkerIDs = {},
            doctorCoveredCount = 0,
            doctorCount = 0,
            treatmentHourBudget = 0
        }
    end

    local plan = {
        ownerUsername = getOwnerKey(ownerUsername),
        infirmary = infirmary,
        priorityIndex = {},
        remainingTreatmentHours = math.max(0, tonumber(infirmary.treatmentHourBudget) or 0),
        initialTreatmentHours = math.max(0, tonumber(infirmary.treatmentHourBudget) or 0),
        usedTreatmentHours = 0,
        coveredPatientCount = math.max(0, tonumber(infirmary.doctorCoveredCount) or 0),
        doctorCount = math.max(0, tonumber(infirmary.doctorCount) or 0),
    }

    for index, workerID in ipairs(infirmary.doctorCoveredWorkerIDs or {}) do
        plan.priorityIndex[tostring(workerID or "")] = index
    end

    return plan
end

function Medical.BuildAllOwnerPlans()
    local plans = {}

    if not DC_Colony or not DC_Colony.Registry or not DC_Colony.Registry.GetOwnerUsernames then
        return plans
    end

    for _, ownerUsername in ipairs(DC_Colony.Registry.GetOwnerUsernames()) do
        local ownerKey = getOwnerKey(ownerUsername)
        if ownerKey ~= "" then
            plans[ownerKey] = Medical.BuildOwnerPlan(ownerKey)
        end
    end

    return plans
end

function Medical.SetPlansCache(plans)
    Medical.Internal.ownerMedicalPlans = plans or {}
end

function Medical.ClearPlansCache()
    Medical.Internal.ownerMedicalPlans = {}
end

function Medical.GetOwnerPlan(ownerUsername)
    local ownerKey = getOwnerKey(ownerUsername)
    return Medical.Internal.ownerMedicalPlans[ownerKey]
end

function Medical.GetWorkerAssignment(worker)
    local plan = Medical.GetOwnerPlan(worker and worker.ownerUsername)
    local infirmary = plan and plan.infirmary or nil
    local assignments = infirmary and infirmary.assignments or {}
    return assignments[tostring(worker and worker.workerID or "")]
end

function Medical.ConsumeTreatmentHours(worker, requestedHours)
    local assignment = Medical.GetWorkerAssignment(worker)
    local plan = Medical.GetOwnerPlan(worker and worker.ownerUsername)

    if not assignment or assignment.assigned ~= true or assignment.doctorCovered ~= true or not plan then
        return 0
    end

    local available = math.max(0, tonumber(plan.remainingTreatmentHours) or 0)
    local consumed = math.min(requestedHours, available)

    plan.remainingTreatmentHours = available - consumed
    plan.usedTreatmentHours = math.max(0, tonumber(plan.usedTreatmentHours) or 0) + consumed

    return consumed
end

function Medical.IsAssignedToInfirmary(worker)
    local assignment = Medical.GetWorkerAssignment(worker)
    return assignment and assignment.assigned == true
end

function Medical.IsDoctorCovered(worker)
    local assignment = Medical.GetWorkerAssignment(worker)
    return assignment and assignment.doctorCovered == true
end

return Medical
