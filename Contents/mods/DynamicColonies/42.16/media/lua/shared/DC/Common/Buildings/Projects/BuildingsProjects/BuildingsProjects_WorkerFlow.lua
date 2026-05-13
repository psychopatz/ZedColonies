DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Projects = Internal.Projects or {}

Internal.Projects = Projects

function Buildings.AssignNextReadyProjectToWorker(worker)
    if not worker or not worker.workerID then
        return nil
    end
    if Buildings.GetProjectForWorker and Buildings.GetProjectForWorker(worker) then
        return nil
    end

    local labourConfig = Projects.GetColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(worker.ownerUsername) or tostring(worker.ownerUsername or "local")
    if Buildings.RefreshOwnerProjectMaterials then
        Buildings.RefreshOwnerProjectMaterials(owner)
    end

    local candidates = {}
    for _, project in pairs(Buildings.GetProjectsForOwner(owner) or {}) do
        if tostring(project and project.status or "") == "Active"
            and tostring(project and project.assignedBuilderID or "") == ""
            and tostring(project and project.materialState or "") ~= "Stalled" then
            candidates[#candidates + 1] = project
        end
    end

    table.sort(candidates, function(a, b)
        local aHours = tonumber(a and a.startedWorldHours) or 0
        local bHours = tonumber(b and b.startedWorldHours) or 0
        if math.abs(aHours - bHours) > 0.0001 then
            return aHours < bHours
        end
        return Projects.GetProjectSequence(a) < Projects.GetProjectSequence(b)
    end)

    local nextProject = candidates[1]
    if not nextProject then
        return nil
    end

    nextProject.assignedBuilderID = worker.workerID
    Buildings.Save()
    return nextProject
end

function Buildings.ProcessWorkerProject(worker, currentHour, workableHours, speedMultiplier)
    local project = Buildings.GetProjectForWorker(worker)
    if not project or project.status ~= "Active" then
        return {
            hadProject = false,
            didWork = false,
            completed = false
        }
    end

    local materialStatus = Buildings.RefreshProjectMaterialState and Buildings.RefreshProjectMaterialState(project) or nil
    if materialStatus and materialStatus.hasAll ~= true then
        return {
            hadProject = true,
            didWork = false,
            completed = false,
            waitingForMaterials = true,
            materialStatus = materialStatus,
            project = project
        }
    end

    local config = Projects.Config or Buildings.Config
    local progressGain = math.max(
        0,
        (math.max(0, tonumber(workableHours) or 0) * config.GetBuilderBaseWorkPointsPerHour() * math.max(0.01, tonumber(speedMultiplier) or 1))
    )
    project.progressWorkPoints = math.max(0, tonumber(project.progressWorkPoints) or 0) + progressGain

    local result = {
        hadProject = true,
        didWork = progressGain > 0,
        completed = false,
        project = project
    }

    if project.progressWorkPoints + 0.0001 >= math.max(1, tonumber(project.requiredWorkPoints) or 1) then
        result.completed = true
        result.instance = Buildings.CompleteProject(project)
        result.nextProject = Buildings.AssignNextReadyProjectToWorker(worker)

        local skills = Projects.GetSkills()
        if skills and skills.GrantXP then
            result.xpResult = skills.GrantXP(worker, "Construction", project.xpReward or 0)
        end
    end

    return result
end

return Buildings