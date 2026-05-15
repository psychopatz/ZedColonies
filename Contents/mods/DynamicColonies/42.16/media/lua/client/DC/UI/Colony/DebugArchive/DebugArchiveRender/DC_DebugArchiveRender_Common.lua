DC_DebugArchiveRender = DC_DebugArchiveRender or {}

local Render = DC_DebugArchiveRender

local function formatInt(value)
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

local function formatFloat(value, decimals)
    decimals = math.max(0, math.floor(tonumber(decimals) or 1))
    return string.format("%." .. tostring(decimals) .. "f", tonumber(value) or 0)
end

local function formatWeight(value)
    return formatFloat(value, 2) .. " W"
end

local function formatPercent(value)
    return formatInt((tonumber(value) or 0) * 100) .. "%"
end

local function appendLine(lines, label, value)
    lines[#lines + 1] = " <RGB:0.72,0.72,0.72> " .. tostring(label or "") .. ": <RGB:1,1,1> " .. tostring(value or "") .. " <LINE> "
end

local function appendHeader(lines, title)
    lines[#lines + 1] = " <RGB:1,1,1> <SIZE:Medium> " .. tostring(title or "") .. " <LINE> "
end

local function appendSubHeader(lines, title)
    lines[#lines + 1] = " <LINE> <RGB:0.92,0.92,0.92> " .. tostring(title or "") .. " <LINE> "
end

local function appendMuted(lines, text)
    lines[#lines + 1] = " <RGB:0.68,0.68,0.68> " .. tostring(text or "") .. " <LINE> "
end

local function appendBlank(lines)
    lines[#lines + 1] = " <LINE> "
end

local function formatCountRows(rows, limit)
    local parts = {}
    local appliedLimit = math.max(0, math.floor(tonumber(limit) or 0))
    local maxIndex = appliedLimit > 0 and math.min(appliedLimit, #(rows or {})) or #(rows or {})
    for index = 1, maxIndex do
        local row = rows[index]
        parts[#parts + 1] = tostring(row and row.key or "?") .. "=" .. formatInt(row and row.count or 0)
    end
    if appliedLimit > 0 and #(rows or {}) > appliedLimit then
        parts[#parts + 1] = "..."
    end
    return table.concat(parts, ", ")
end

Render.FormatInt = formatInt
Render.FormatFloat = formatFloat
Render.FormatWeight = formatWeight
Render.FormatPercent = formatPercent
Render.AppendLine = appendLine
Render.AppendHeader = appendHeader
Render.AppendSubHeader = appendSubHeader
Render.AppendMuted = appendMuted
Render.AppendBlank = appendBlank
Render.FormatCountRows = formatCountRows

return Render
