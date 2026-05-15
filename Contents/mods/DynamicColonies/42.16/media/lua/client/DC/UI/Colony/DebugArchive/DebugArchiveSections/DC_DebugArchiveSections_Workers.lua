require "DC/UI/Colony/DebugArchive/DebugArchiveRender/DC_DebugArchiveRender_Common"

DC_DebugArchiveSections_Workers = DC_DebugArchiveSections_Workers or {}

local Render = DC_DebugArchiveRender
local Section = DC_DebugArchiveSections_Workers

function Section.Build(window, snapshot)
    local lines = {}
    local workerSummary = snapshot and snapshot.workers or {}

    Render.AppendHeader(lines, "Workers")
    Render.AppendLine(lines, "Total", Render.FormatInt(workerSummary and workerSummary.totalCount or 0))
    Render.AppendLine(lines, "States", Render.FormatCountRows(workerSummary and workerSummary.stateCounts or {}, 16))
    Render.AppendLine(lines, "Jobs", Render.FormatCountRows(workerSummary and workerSummary.jobCounts or {}, 16))

    if #(workerSummary and workerSummary.workers or {}) <= 0 then
        Render.AppendMuted(lines, "No workers registered for this colony.")
        return table.concat(lines)
    end

    for _, worker in ipairs(workerSummary.workers or {}) do
        Render.AppendSubHeader(lines, tostring(worker and worker.name or worker and worker.workerID or "Worker"))
        Render.AppendLine(lines, "Worker ID", worker and worker.workerID or "")
        Render.AppendLine(lines, "State", worker and worker.state or "")
        Render.AppendLine(lines, "Presence", worker and worker.presenceState or "")
        Render.AppendLine(lines, "Job", worker and worker.jobType or "")
        Render.AppendLine(lines, "Assigned Site", worker and worker.assignedSiteID or "")
        Render.AppendLine(lines, "Assigned Project", worker and worker.assignedProjectID or "")
        Render.AppendLine(lines, "HP", Render.FormatInt(worker and worker.hp or 0) .. " / " .. Render.FormatInt(worker and worker.maxHp or 0))
        Render.AppendLine(lines, "Energy", Render.FormatInt(worker and worker.energyCurrent or 0) .. " / " .. Render.FormatInt(worker and worker.energyMax or 0))
        Render.AppendLine(lines, "Calories", Render.FormatInt(worker and worker.totalCaloriesAvailable or 0))
        Render.AppendLine(lines, "Hydration", Render.FormatInt(worker and worker.totalHydrationAvailable or 0))
        Render.AppendLine(lines, "Work Progress", Render.FormatPercent(worker and worker.workTarget and tonumber(worker.workTarget) and tonumber(worker.workTarget) > 0 and ((tonumber(worker.workProgress) or 0) / math.max(1, tonumber(worker.workTarget) or 1)) or 0))
        Render.AppendLine(lines, "Carry", Render.FormatWeight(worker and worker.inventoryUsedWeight or 0) .. " / " .. Render.FormatWeight(worker and worker.inventoryMaxWeight or 0))
        Render.AppendLine(lines, "Output Count", Render.FormatInt(worker and worker.outputCount or 0))
        Render.AppendLine(lines, "Tool State", worker and worker.toolState or "")
        Render.AppendLine(lines, "Housing", worker and worker.housingState or "")
        if tostring(worker and worker.deathCause or "") ~= "" then
            Render.AppendLine(lines, "Death Cause", worker and worker.deathCause or "")
        end
    end

    return table.concat(lines)
end

return Section
