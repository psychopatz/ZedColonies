DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Validation = Internal.ProjectValidation or {}

Internal.ProjectValidation = Validation

function Buildings.CanReleaseBuilderFromProject(worker, project, options)
    options = type(options) == "table" and options or {}
    if not worker or not project then
        return false
    end
    if tostring(project.status or "") ~= "Active" then
        return false
    end
    if tostring(project.assignedBuilderID or "") ~= tostring(worker.workerID or "") then
        return false
    end

    local allowedProjectID = tostring(options.allowedProjectID or "")
    if allowedProjectID ~= "" and tostring(project.projectID or "") == allowedProjectID then
        return true
    end

    return tostring(project.materialState or "") == "Stalled"
end

function Buildings.CanWorkerBuild(worker, options)
    options = type(options) == "table" and options or {}
    local allowedProjectID = tostring(options.allowedProjectID or "")
    local allowProjectRelease = options.allowProjectRelease == true
    local labourConfig = Validation.GetColonyConfig()
    if not worker or not worker.workerID then
        return false, "Builder not found."
    end
    if tostring(worker.state or "") == tostring(labourConfig.States and labourConfig.States.Dead or "Dead") then
        return false, "That worker is dead."
    end
    if labourConfig.NormalizeJobType and labourConfig.NormalizeJobType(worker.jobType) ~= tostring(labourConfig.JobTypes and labourConfig.JobTypes.Builder or "Builder") then
        return false, "That worker is not assigned to Builder."
    end
    if Validation.GetWorkerConstructionLevel(worker) <= 0 then
        return false, "That worker has no Construction skill."
    end
    local currentProject = Buildings.GetWorkerProject(worker.ownerUsername, worker.workerID)
    if currentProject and tostring(currentProject.projectID or "") ~= allowedProjectID then
        if not (allowProjectRelease and Buildings.CanReleaseBuilderFromProject and Buildings.CanReleaseBuilderFromProject(worker, currentProject, options)) then
            return false, "That builder already has an active project."
        end
    end
    local registry = Validation.GetRegistry()
    if registry and registry.WorkerHasRequiredTools and not registry.WorkerHasRequiredTools(worker) then
        return false, "That builder is missing required tools."
    end
    return true, nil
end

return Buildings