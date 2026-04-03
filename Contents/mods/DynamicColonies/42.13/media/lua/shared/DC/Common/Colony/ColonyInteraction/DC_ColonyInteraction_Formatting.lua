DC_Colony = DC_Colony or {}
DC_Colony.Interaction = DC_Colony.Interaction or {}

local Interaction = DC_Colony.Interaction

Interaction.normalizeText = function(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "[^%w]+", "")
    return text
end

Interaction.formatDecimal = function(value, decimals)
    local places = tonumber(decimals) or 1
    return string.format("%." .. tostring(places) .. "f", tonumber(value) or 0)
end

Interaction.formatDurationHours = function(hoursLeft)
    if hoursLeft == nil then
        return "n/a"
    end

    local safeHours = math.max(0, tonumber(hoursLeft) or 0)
    if safeHours <= 0 then
        return "now"
    end
    if safeHours < 1 then
        return "< 1h"
    end

    local roundedHours = math.floor(safeHours + 0.5)
    local days = math.floor(roundedHours / 24)
    local hours = roundedHours % 24
    if days <= 0 then
        return tostring(roundedHours) .. "h"
    end
    if hours <= 0 then
        return tostring(days) .. "d"
    end
    return tostring(days) .. "d " .. tostring(hours) .. "h"
end

Interaction.formatWholeAmount = function(value)
    return string.format("%.0f", math.max(0, tonumber(value) or 0))
end

Interaction.prettifyContextLabel = function(rawText)
    local text = tostring(rawText or "")
    if text == "" then
        return nil
    end

    text = string.gsub(text, "_", " ")
    text = string.gsub(text, "(%l)(%u)", "%1 %2")
    text = string.gsub(text, "(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest or "")
    end)
    return text
end

return DC_Colony.Interaction
