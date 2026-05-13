DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
Companion.Internal = Companion.Internal or {}

local Internal = Companion.Internal
local UpdateLoop = Internal.UpdateLoop or {}

Internal.UpdateLoop = UpdateLoop

function UpdateLoop.SetTravelProgressMarker(companionData, currentHour, remainingHours)
    if not companionData then
        return
    end

    companionData.travelLastProgressHour = tonumber(currentHour) or companionData.travelLastProgressHour
    companionData.travelLastRemainingHours = math.max(0, tonumber(remainingHours) or 0)
end

function UpdateLoop.ApplyTravelProgressFailsafe(worker, companionData, currentHour, deltaHours)
    local remainingHours = math.max(0, tonumber(worker and worker.travelHoursRemaining) or 0)
    if remainingHours <= 0 then
        UpdateLoop.SetTravelProgressMarker(companionData, currentHour, remainingHours)
        return false
    end

    local lastProgressHour = tonumber(companionData and companionData.travelLastProgressHour) or nil
    local lastRemainingHours = tonumber(companionData and companionData.travelLastRemainingHours) or nil
    if lastProgressHour == nil or lastRemainingHours == nil or remainingHours < (lastRemainingHours - 0.0001) then
        UpdateLoop.SetTravelProgressMarker(companionData, currentHour, remainingHours)
        return false
    end

    local graceHours = math.max(0.25, math.min(1.0, tonumber(Internal.GetTravelHours and Internal.GetTravelHours()) or 1))
    if (tonumber(currentHour) or 0) - lastProgressHour < graceHours then
        return false
    end

    local forcedStep = math.max(0.05, tonumber(deltaHours) or 0)
    worker.travelHoursRemaining = math.max(0, remainingHours - forcedStep)
    UpdateLoop.SetTravelProgressMarker(companionData, currentHour, worker.travelHoursRemaining)
    Internal.Debug(
        "Companion travel failsafe advanced workerID=" .. tostring(worker and worker.workerID)
            .. " presenceState=" .. tostring(worker and worker.presenceState)
            .. " remaining=" .. tostring(worker and worker.travelHoursRemaining)
    )
    return true
end

return Companion