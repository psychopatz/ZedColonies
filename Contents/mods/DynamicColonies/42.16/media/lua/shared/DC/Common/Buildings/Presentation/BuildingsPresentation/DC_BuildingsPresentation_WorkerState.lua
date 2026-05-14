DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Presentation = Buildings.Internal.Presentation or {}
local modules = Presentation.Modules or {}

Buildings.Internal.Presentation = Presentation
Presentation.Modules = modules

if modules.WorkerState then
    return
end

modules.WorkerState = true

function Buildings.ApplyWorkerState(worker)
    if not worker or not worker.workerID then
        return
    end

    local housing = Buildings.GetWorkerHousing(worker.ownerUsername, worker.workerID)
    local infirmary = Buildings.GetWorkerInfirmary and Buildings.GetWorkerInfirmary(worker.ownerUsername, worker.workerID) or nil
    worker.housingState = housing.housingState
    worker.housingBuildingID = housing.buildingID
    worker.housingBuildingType = housing.buildingType
    worker.housingBuildingLevel = housing.buildingLevel
    worker.housingRecoveryMultiplier = housing.recoveryMultiplier
    worker.infirmaryBuildingID = infirmary and infirmary.buildingID or nil
    worker.infirmaryBuildingType = infirmary and infirmary.buildingType or nil
    worker.infirmaryBuildingLevel = infirmary and infirmary.buildingLevel or 0
    worker.infirmaryBedAssigned = infirmary and infirmary.assigned == true or false
    worker.doctorCovered = infirmary and infirmary.doctorCovered == true or false
    if DC_Colony and DC_Colony.Energy and DC_Colony.Energy.SetRecoverySources then
        DC_Colony.Energy.SetRecoverySources(worker, {
            base = 1.0,
            housing = housing.recoveryMultiplier
        })
    end

    local project = Buildings.GetProjectForWorker(worker)
    if project then
        worker.assignedProjectID = project.projectID
        worker.assignedProjectBuildingType = project.buildingType
        worker.assignedProjectBuildingID = project.buildingID
        worker.assignedProjectTargetLevel = project.targetLevel
        worker.assignedProjectMaterialState = project.materialState
        worker.assignedProjectProgress = project.progressWorkPoints
        worker.assignedProjectRequired = project.requiredWorkPoints
        worker.workProgress = project.progressWorkPoints
        worker.workTarget = project.requiredWorkPoints
        worker.workCycleHours = project.requiredWorkPoints
    else
        worker.assignedProjectID = nil
        worker.assignedProjectBuildingType = nil
        worker.assignedProjectBuildingID = nil
        worker.assignedProjectTargetLevel = nil
        worker.assignedProjectMaterialState = nil
        worker.assignedProjectProgress = nil
        worker.assignedProjectRequired = nil
    end

    if Buildings.RealBase and Buildings.RealBase.ApplyWorkerAnchors then
        Buildings.RealBase.ApplyWorkerAnchors(worker)
    end
    if DC_Colony and DC_Colony.ResidentBridge and DC_Colony.ResidentBridge.OnWorkerStateApplied then
        DC_Colony.ResidentBridge.OnWorkerStateApplied(worker)
    end
end
