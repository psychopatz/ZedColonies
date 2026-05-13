DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Materials = Internal.ProjectMaterials or {}

Internal.ProjectMaterials = Materials

function Buildings.GetProjectMaterialStatus(project, sourcePlayer, availableCounts)
    return Materials.BuildProjectMaterialStatus(project, sourcePlayer, availableCounts)
end

function Buildings.RefreshProjectMaterialState(project)
    if not project or tostring(project.status or "") ~= "Active" then
        return Materials.BuildProjectMaterialStatus(project)
    end

    Materials.EnsureProjectMaterialTracking(project)
    Materials.PullProjectMaterialsFromWarehouse(project)

    local materialStatus = Materials.BuildProjectMaterialStatus(project)
    project.materialState = materialStatus.hasAll and "Ready" or "Stalled"
    project.materialProgressRatio = materialStatus.progressRatio
    return materialStatus
end

function Buildings.RefreshOwnerProjectMaterials(ownerUsername)
    local owner = Materials.GetOwnerUsername(ownerUsername)
    local changed = false

    for _, project in pairs(Buildings.GetProjectsForOwner(owner)) do
        if tostring(project.status or "") == "Active" then
            local beforeState = tostring(project.materialState or "")
            local beforeRatio = tonumber(project.materialProgressRatio) or -1
            local beforeCounts = Materials.NormalizeMaterialCountMap(project.materialCounts)
            local beforeTotal = 0
            for _, count in pairs(beforeCounts) do
                beforeTotal = beforeTotal + count
            end

            local materialStatus = Buildings.RefreshProjectMaterialState(project)
            local afterTotal = 0
            for _, count in pairs(project.materialCounts or {}) do
                afterTotal = afterTotal + (tonumber(count) or 0)
            end

            if beforeState ~= tostring(project.materialState or "")
                or math.abs(beforeRatio - (tonumber(project.materialProgressRatio) or 0)) > 0.0001
                or beforeTotal ~= afterTotal
                or (materialStatus and materialStatus.hasAll and beforeState ~= "Ready") then
                changed = true
            end
        end
    end

    if changed then
        Buildings.Save()
    end

    return changed
end

return Buildings