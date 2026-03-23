DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal

function Internal.formatReserveValue(value)
    return string.format("%.0f", tonumber(value) or 0)
end

function Internal.formatDecimal(value, decimals)
    local places = tonumber(decimals) or 2
    return string.format("%." .. tostring(places) .. "f", tonumber(value) or 0)
end

function Internal.formatBool(value)
    return value and "Yes" or "No"
end

function Internal.formatCoords(x, y, z)
    if x == nil or y == nil then
        return "Unassigned"
    end

    return "("
        .. tostring(math.floor(tonumber(x) or 0))
        .. ", "
        .. tostring(math.floor(tonumber(y) or 0))
        .. ", "
        .. tostring(math.floor(tonumber(z) or 0))
        .. ")"
end

function Internal.formatActivityTimestamp(worldHour)
    local safeHour = math.max(0, tonumber(worldHour) or 0)
    local hoursPerDay = math.max(1, tonumber(Internal.Config and Internal.Config.HOURS_PER_DAY) or 24)
    local day = math.floor(safeHour / hoursPerDay) + 1
    local hourOfDayFloat = safeHour % hoursPerDay
    local hourOfDay = math.floor(hourOfDayFloat)
    local minutes = math.floor(((hourOfDayFloat - hourOfDay) * 60) + 0.5)

    if minutes >= 60 then
        minutes = minutes - 60
        hourOfDay = hourOfDay + 1
        if hourOfDay >= hoursPerDay then
            hourOfDay = hourOfDay - hoursPerDay
            day = day + 1
        end
    end

    return string.format("D%d %02d:%02d", day, hourOfDay, minutes)
end

function Internal.formatDurationHours(hoursLeft)
    if hoursLeft == nil then
        return "n/a"
    end

    local safeHours = math.max(0, tonumber(hoursLeft) or 0)
    if safeHours <= 0 then
        return "empty now"
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

function Internal.formatDaysAndEta(daysLeft, hoursLeft)
    if daysLeft == nil then
        return "n/a"
    end

    return Internal.formatDecimal(daysLeft, 2) .. "d (" .. Internal.formatDurationHours(hoursLeft) .. ")"
end

