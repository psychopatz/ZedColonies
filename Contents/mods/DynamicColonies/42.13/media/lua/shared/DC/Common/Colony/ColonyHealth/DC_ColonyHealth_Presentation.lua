DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}

local Health = DC_Colony.Health

local function formatReserveValue(value)
    if DC_MainWindow and DC_MainWindow.Internal and DC_MainWindow.Internal.formatReserveValue then
        return DC_MainWindow.Internal.formatReserveValue(value)
    end
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

function Health.GetBarColor()
    return { r = 0.86, g = 0.33, b = 0.33 } -- Red for Health
end

function Health.GetBarData(worker)
    local currentValue = Health.GetCurrent(worker)
    local maxValue = Health.GetMax(worker)

    return {
        stored = currentValue,
        usage = maxValue,
        fillRatio = Health.GetRatio(worker),
        overflow = 0,
        daysLeft = nil,
        captionText = "health points",
        summaryText = formatReserveValue(currentValue)
            .. " / "
            .. formatReserveValue(maxValue)
    }
end

return Health
