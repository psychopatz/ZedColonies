DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Validation = Internal.ProjectValidation or {}

Internal.ProjectValidation = Validation

function Buildings.GetWorkerProject(ownerUsername, workerID)
    for _, project in pairs(Buildings.GetProjectsForOwner(ownerUsername)) do
        if project.status == "Active" and tostring(project.assignedBuilderID or "") == tostring(workerID or "") then
            return project
        end
    end
    return nil
end

function Buildings.GetProjectForWorker(worker)
    if not worker or not worker.workerID then
        return nil
    end
    return Buildings.GetWorkerProject(worker.ownerUsername, worker.workerID)
end

function Buildings.GetProjectByID(ownerUsername, projectID)
    local owner = Validation.GetOwnerUsername(ownerUsername)
    local wanted = tostring(projectID or "")
    if wanted == "" then
        return nil
    end

    for _, project in pairs(Buildings.GetProjectsForOwner(owner)) do
        if tostring(project and project.projectID or "") == wanted then
            return project
        end
    end

    return nil
end

return Buildings