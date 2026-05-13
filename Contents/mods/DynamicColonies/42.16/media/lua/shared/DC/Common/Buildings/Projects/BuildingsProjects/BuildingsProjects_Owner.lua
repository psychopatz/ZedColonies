DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Projects = Internal.Projects or {}

Internal.Projects = Projects

function Buildings.EnsureInitialHeadquartersProject(ownerUsername)
    local labourConfig = Projects.GetColonyConfig()
    local owner = labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(ownerUsername) or tostring(ownerUsername or "local")
    if Buildings.OwnerHasHeadquarters and Buildings.OwnerHasHeadquarters(owner) then
        return nil
    end

    local hasAnyCompletedBuilding = false
    for _, instance in ipairs(Buildings.GetBuildingsForOwner(owner) or {}) do
        if math.floor(tonumber(instance and instance.level) or 0) > 0 then
            hasAnyCompletedBuilding = true
            break
        end
    end
    if hasAnyCompletedBuilding then
        return nil
    end

    for _, project in pairs(Buildings.GetProjectsForOwner(owner) or {}) do
        if tostring(project and project.status or "") == "Active" then
            return nil
        end
    end

    local plot, state = Buildings.GetPlotWithState(owner, 0, 0)
    local expectedState = Buildings.MapConstants
        and Buildings.MapConstants.PlotStates
        and Buildings.MapConstants.PlotStates.Empty
        or "Empty"
    local expectedKind = Buildings.MapConstants
        and Buildings.MapConstants.PlotKinds
        and Buildings.MapConstants.PlotKinds.HQOnly
        or "HQOnly"
    if not plot or tostring(state or "") ~= tostring(expectedState) then
        return nil
    end
    if plot.unlocked ~= true or tostring(plot.kind or "") ~= tostring(expectedKind) then
        return nil
    end

    local ok, _, project = Buildings.QueueProject(owner, "Headquarters", "build", 0, 0, nil, nil)
    if ok then
        return project
    end

    return nil
end

function Buildings.GetOwnerProjectList(ownerUsername)
    if Buildings.RefreshOwnerProjectMaterials then
        Buildings.RefreshOwnerProjectMaterials(ownerUsername)
    end

    local projects = {}
    for _, project in pairs(Buildings.GetProjectsForOwner(ownerUsername)) do
        if tostring(project.status or "") == "Active" then
            projects[#projects + 1] = project
        end
    end

    table.sort(projects, function(a, b)
        return tostring(a.projectID or "") < tostring(b.projectID or "")
    end)
    return projects
end

return Buildings