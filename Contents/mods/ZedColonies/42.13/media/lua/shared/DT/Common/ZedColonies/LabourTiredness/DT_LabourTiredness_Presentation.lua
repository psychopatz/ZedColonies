DT_Labour = DT_Labour or {}
DT_Labour.Tiredness = DT_Labour.Tiredness or {}

local Config = DT_Labour.Config
local Tiredness = DT_Labour.Tiredness

local function formatReserveValue(value)
    if DT_MainWindow and DT_MainWindow.Internal and DT_MainWindow.Internal.formatReserveValue then
        return DT_MainWindow.Internal.formatReserveValue(value)
    end
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

local function formatDurationHours(value)
    if DT_Labour and DT_Labour.Interaction and DT_Labour.Interaction.formatDurationHours then
        return DT_Labour.Interaction.formatDurationHours(value)
    end
    return string.format("%.1fh", math.max(0, tonumber(value) or 0))
end

function Tiredness.GetBarColor()
    return { r = 0.69, g = 0.33, b = 0.86 }
end

function Tiredness.GetBarData(worker)
    local currentValue = Tiredness.GetCurrent(worker)
    local maxValue = Tiredness.GetMax(worker)
    local recoveryMultiplier = Tiredness.GetRecoveryMultiplier and Tiredness.GetRecoveryMultiplier(worker) or 1.0
    local isResting = Tiredness.IsForcedRest(worker)
    local captionText = "work readiness"
    local presenceState = tostring(worker and worker.presenceState or "")

    if isResting then
        if presenceState == tostring((Config.PresenceStates or {}).AwayToHome or "AwayToHome") then
            captionText = "heading home to rest"
        else
            captionText = "resting at home"
        end
    end

    return {
        stored = currentValue,
        usage = maxValue,
        fillRatio = Tiredness.GetRatio(worker),
        overflow = 0,
        daysLeft = nil,
        captionText = captionText,
        summaryText = formatReserveValue(currentValue)
            .. " / "
            .. formatReserveValue(maxValue)
            .. " | Regen x"
            .. string.format("%.2f", recoveryMultiplier)
    }
end

function Tiredness.GetRestingProgressDescriptor(worker)
    if not worker or not Tiredness.IsForcedRest(worker) then
        return nil
    end

    local currentValue = Tiredness.GetCurrent(worker)
    local maxValue = Tiredness.GetMax(worker)
    local recoveryPerHour = Tiredness.GetHomeRecoveryPerHour and Tiredness.GetHomeRecoveryPerHour(worker) or 0
    local remainingValue = math.max(0, maxValue - currentValue)
    local remainingWorldHours = recoveryPerHour > 0 and (remainingValue / recoveryPerHour) or nil

    return {
        label = "Resting",
        displayText = "Resting",
        fillRatio = Tiredness.GetRatio(worker),
        captionText = "Ready in " .. formatDurationHours(remainingWorldHours),
        summaryText = formatReserveValue(currentValue)
            .. " / "
            .. formatReserveValue(maxValue)
            .. " energy",
        progressAmount = currentValue,
        workTarget = maxValue,
        remainingWorldHours = remainingWorldHours,
        color = Tiredness.GetBarColor()
    }
end

return Tiredness
