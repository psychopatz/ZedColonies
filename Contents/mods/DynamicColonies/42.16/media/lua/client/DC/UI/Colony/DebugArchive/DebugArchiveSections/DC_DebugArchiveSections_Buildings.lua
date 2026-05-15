require "DC/UI/Colony/DebugArchive/DebugArchiveRender/DC_DebugArchiveRender_Common"

DC_DebugArchiveSections_Buildings = DC_DebugArchiveSections_Buildings or {}

local Render = DC_DebugArchiveRender
local Section = DC_DebugArchiveSections_Buildings

function Section.Build(window, snapshot)
    local lines = {}
    local buildings = snapshot and snapshot.buildings or {}

    Render.AppendHeader(lines, "Buildings")
    Render.AppendLine(lines, "Building Types", Render.FormatInt(buildings and buildings.buildings and #buildings.buildings or 0))
    Render.AppendLine(lines, "Active Projects", Render.FormatInt(buildings and buildings.activeProjects and #buildings.activeProjects or 0))
    Render.AppendLine(lines, "Housing Capacity", Render.FormatInt(buildings and buildings.housing and buildings.housing.capacity or 0))
    Render.AppendLine(lines, "Medical Capacity", Render.FormatInt(buildings and buildings.medical and buildings.medical.totalCapacity or 0))

    Render.AppendSubHeader(lines, "Built Structures")
    if #(buildings and buildings.buildings or {}) <= 0 then
        Render.AppendMuted(lines, "No buildings registered.")
    else
        for _, definition in ipairs(buildings.buildings or {}) do
            Render.AppendMuted(lines,
                tostring(definition and definition.displayName or definition and definition.buildingType or "Building")
                .. " | Count " .. Render.FormatInt(definition and definition.currentCount or 0)
                .. " | Max Level " .. Render.FormatInt(definition and definition.maxLevel or 0))
            for _, instance in ipairs(definition.instances or {}) do
                Render.AppendMuted(lines,
                    "  - "
                    .. tostring(instance and instance.displayName or instance and instance.buildingID or "Instance")
                    .. " | ID " .. tostring(instance and instance.buildingID or "")
                    .. " | L" .. Render.FormatInt(instance and instance.level or 0)
                    .. " | Plot " .. tostring(instance and instance.plotX or 0) .. "," .. tostring(instance and instance.plotY or 0))
            end
        end
    end

    Render.AppendSubHeader(lines, "Active Projects")
    if #(buildings and buildings.activeProjects or {}) <= 0 then
        Render.AppendMuted(lines, "No active projects.")
    else
        for _, project in ipairs(buildings.activeProjects or {}) do
            Render.AppendMuted(lines,
                tostring(project and project.displayName or project and project.projectID or "Project")
                .. " | " .. tostring(project and project.status or "unknown")
                .. " | " .. tostring(project and project.mode or "build")
                .. " | Work " .. Render.FormatInt(project and project.progressWorkPoints or 0)
                .. " / " .. Render.FormatInt(project and project.requiredWorkPoints or 0)
                .. " | Materials " .. tostring(project and project.materialState or "unknown")
                .. " | Builder " .. tostring(project and project.assignedBuilderName or "Unassigned"))
        end
    end

    return table.concat(lines)
end

return Section
