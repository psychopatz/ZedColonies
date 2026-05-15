require "DC/UI/Colony/DebugArchive/DebugArchiveRender/DC_DebugArchiveRender_Common"

DC_DebugArchiveSections_Raw = DC_DebugArchiveSections_Raw or {}

local Render = DC_DebugArchiveRender
local Section = DC_DebugArchiveSections_Raw

local function joinList(values, limit)
    local parts = {}
    local appliedLimit = math.max(0, math.floor(tonumber(limit) or 0))
    local maxIndex = appliedLimit > 0 and math.min(appliedLimit, #(values or {})) or #(values or {})
    for index = 1, maxIndex do
        parts[#parts + 1] = tostring(values[index] or "")
    end
    if appliedLimit > 0 and #(values or {}) > appliedLimit then
        parts[#parts + 1] = "..."
    end
    return table.concat(parts, ", ")
end

function Section.Build(window, snapshot)
    local lines = {}
    local raw = snapshot and snapshot.rawState or {}

    Render.AppendHeader(lines, "Raw State")
    Render.AppendLine(lines, "Owner", raw and raw.ownerUsername or "")
    Render.AppendLine(lines, "Colony ID", raw and raw.colonyID or "")
    Render.AppendLine(lines, "Colony Name", raw and raw.colonyName or "")
    Render.AppendLine(lines, "Leader", raw and raw.leaderUsername or "")
    Render.AppendLine(lines, "Members", joinList(raw and raw.memberUsernames or {}, 16))
    Render.AppendLine(lines, "Worker IDs", joinList(raw and raw.workerIDs or {}, 24))
    Render.AppendLine(lines, "Site IDs", joinList(raw and raw.siteIDs or {}, 24))

    Render.AppendSubHeader(lines, "Counts")
    for key, value in pairs(raw and raw.counts or {}) do
        Render.AppendLine(lines, key, Render.FormatInt(value))
    end

    Render.AppendSubHeader(lines, "Versions")
    for key, value in pairs(raw and raw.versions or {}) do
        Render.AppendLine(lines, key, value)
    end

    if raw and raw.recruitAttempts then
        Render.AppendSubHeader(lines, "Recruit Attempts")
        for key, value in pairs(raw.recruitAttempts) do
            Render.AppendLine(lines, key, value)
        end
    end

    if raw and raw.permissions then
        Render.AppendSubHeader(lines, "Permissions")
        for key, value in pairs(raw.permissions) do
            Render.AppendLine(lines, key, value)
        end
    end

    return table.concat(lines)
end

return Section
