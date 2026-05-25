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

local function buildWorkerPresentationSignature(worker)
    if type(worker) ~= "table" then
        return ""
    end

    return table.concat({
        tostring(worker.ownerUsername or ""),
        tostring(worker.workerID or ""),
        tostring(worker.housingState or ""),
        tostring(worker.housingBuildingID or ""),
        tostring(worker.housingBuildingType or ""),
        tostring(worker.housingBuildingLevel or ""),
        tostring(worker.housingRecoveryMultiplier or ""),
        tostring(worker.infirmaryBuildingID or ""),
        tostring(worker.infirmaryBuildingType or ""),
        tostring(worker.infirmaryBuildingLevel or ""),
        tostring(worker.infirmaryBedAssigned == true),
        tostring(worker.doctorCovered == true),
        tostring(worker.assignedProjectID or ""),
        tostring(worker.assignedProjectBuildingType or ""),
        tostring(worker.assignedProjectBuildingID or ""),
        tostring(worker.assignedProjectTargetLevel or ""),
        tostring(worker.assignedProjectMaterialState or ""),
        tostring(worker.assignedProjectProgress or ""),
        tostring(worker.assignedProjectRequired or ""),
        tostring(worker.homeX or ""),
        tostring(worker.homeY or ""),
        tostring(worker.homeZ or ""),
        tostring(worker.workX or ""),
        tostring(worker.workY or ""),
        tostring(worker.workZ or ""),
    }, "|")
end

function Buildings.ApplyWorkerState(worker, options)
    if not worker or not worker.workerID then
        return
    end
    options = type(options) == "table" and options or {}

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

    local nextSignature = buildWorkerPresentationSignature(worker)
    if tostring(worker._dtWorkerPresentationSignature or "") == nextSignature then
        return
    end
    worker._dtWorkerPresentationSignature = nextSignature

    if options.allowResidentSync == true
        and DC_Colony and DC_Colony.ResidentBridge and DC_Colony.ResidentBridge.OnWorkerStateApplied then
        DC_Colony.ResidentBridge.OnWorkerStateApplied(worker)
    end
end
