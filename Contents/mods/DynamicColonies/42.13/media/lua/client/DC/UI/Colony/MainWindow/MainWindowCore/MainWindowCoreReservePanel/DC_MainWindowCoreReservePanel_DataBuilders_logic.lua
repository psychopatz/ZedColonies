DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
Internal.ReservePanel = Internal.ReservePanel or {}
local ReservePanel = Internal.ReservePanel

function ReservePanel.buildFallbackReserveData(currentAmount, maxAmount, summaryText, captionText)
    local safeMax = math.max(1, tonumber(maxAmount) or 100)
    local safeCurrent = math.max(0, math.min(safeMax, tonumber(currentAmount) or 0))
    return {
        stored = safeCurrent,
        usage = safeMax,
        fillRatio = safeCurrent / safeMax,
        overflow = 0,
        daysLeft = nil,
        summaryText = tostring(summaryText or (tostring(math.floor(safeCurrent + 0.5)) .. " / " .. tostring(math.floor(safeMax + 0.5)))),
        captionText = tostring(captionText or "")
    }
end

function ReservePanel.buildReserveBarData(storedAmount, dailyNeed)
    local stored = math.max(0, tonumber(storedAmount) or 0)
    local usage = math.max(0, tonumber(dailyNeed) or 0)
    if usage <= 0 then
        return {
            stored = stored,
            usage = usage,
            fillRatio = 0,
            overflow = 0,
            daysLeft = nil
        }
    end

    local rawRatio = stored / usage
    return {
        stored = stored,
        usage = usage,
        fillRatio = math.max(0, math.min(1, rawRatio)),
        overflow = math.max(0, stored - usage),
        daysLeft = math.max(0, rawRatio)
    }
end

function ReservePanel.buildNutritionBarData(unitLabel, currentBufferAmount, carryoverAmount, provisionReserveAmount, dailyNeed)
    if ReservePanel.isFunction(Internal.getNutritionBarData) then
        return Internal.getNutritionBarData(unitLabel, currentBufferAmount, carryoverAmount, provisionReserveAmount, dailyNeed)
    end

    local unitName = tostring(unitLabel or "Nutrition")
    local currentBuffer = math.max(0, tonumber(currentBufferAmount) or 0)
    local carryover = math.max(0, tonumber(carryoverAmount) or 0)
    local provisionReserve = math.max(0, tonumber(provisionReserveAmount) or 0)
    local data = ReservePanel.buildReserveBarData(currentBuffer, dailyNeed)
    data.carryover = carryover
    data.provisionReserve = provisionReserve
    data.currentBuffer = currentBuffer
    if tonumber(dailyNeed) and tonumber(dailyNeed) > 0 then
        data.daysLeft = math.max(0, (currentBuffer + carryover + provisionReserve) / tonumber(dailyNeed))
    end
    data.summaryText = unitName .. " Reserve " .. ReservePanel.formatReserveValue(provisionReserve)
        .. " | Carryover " .. ReservePanel.formatReserveValue(carryover)
    return data
end

function ReservePanel.buildHealthBarData(currentHp, maxHp, worker)
    if ReservePanel.isFunction(Internal.getHealthBarData) then
        return Internal.getHealthBarData(currentHp, maxHp, worker)
    end

    local safeMax = math.max(1, tonumber(maxHp) or 100)
    local safeCurrent = math.max(0, math.min(safeMax, tonumber(currentHp) or safeMax))
    local treatmentActive = worker and worker.selfTreatmentActive == true and (tonumber(worker.selfTreatmentHealRemaining) or 0) > 0
    local treatmentLabel = treatmentActive and tostring(worker.selfTreatmentLabel or "bandage") or nil
    local treatmentHealRemaining = treatmentActive and math.max(0, tonumber(worker.selfTreatmentHealRemaining) or 0) or 0
    return {
        stored = safeCurrent,
        usage = safeMax,
        fillRatio = safeCurrent / safeMax,
        overflow = 0,
        daysLeft = nil,
        captionText = treatmentActive
            and (tostring(treatmentLabel) .. " healing +" .. ReservePanel.formatReserveValue(treatmentHealRemaining) .. " hp left")
            or (safeCurrent <= 0 and "dead" or "current hp"),
        summaryText = ReservePanel.formatReserveValue(safeCurrent) .. " / " .. ReservePanel.formatReserveValue(safeMax),
        treatmentActive = treatmentActive,
        treatmentTierID = worker and worker.selfTreatmentTierID or nil,
        treatmentLabel = treatmentLabel,
        treatmentItemFullType = worker and worker.selfTreatmentItemFullType or nil,
        treatmentHealRemaining = treatmentHealRemaining,
        treatmentRegenPerHour = treatmentActive and math.max(0, tonumber(worker.selfTreatmentRegenPerHour) or 0) or 0,
        treatmentOverlayText = treatmentActive and ("+" .. ReservePanel.formatReserveValue(treatmentHealRemaining) .. " hp") or nil,
    }
end
