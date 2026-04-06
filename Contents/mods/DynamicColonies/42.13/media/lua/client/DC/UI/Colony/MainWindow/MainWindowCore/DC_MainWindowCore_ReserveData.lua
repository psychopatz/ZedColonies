DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

require "DC/Common/Colony/ColonyInteraction/DC_Colony_Interaction"

local Internal = DC_MainWindow.Internal

local function isFunction(value)
    return type(value) == "function"
end

local function formatReserveValue(value)
    if isFunction(Internal.formatReserveValue) then
        return Internal.formatReserveValue(value)
    end
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

function Internal.getReserveDaysLeft(storedAmount, dailyNeed)
    local perDay = tonumber(dailyNeed) or 0
    if perDay <= 0 then
        return nil
    end

    local days = (tonumber(storedAmount) or 0) / perDay
    return math.max(0, days)
end

function Internal.getReserveHoursLeft(storedAmount, hourlyNeed)
    local perHour = tonumber(hourlyNeed) or 0
    if perHour <= 0 then
        return nil
    end

    return math.max(0, (tonumber(storedAmount) or 0) / perHour)
end

function Internal.getNextRefillHours(caloriesHoursLeft, hydrationHoursLeft)
    if caloriesHoursLeft and hydrationHoursLeft then
        return math.min(caloriesHoursLeft, hydrationHoursLeft)
    end
    return caloriesHoursLeft or hydrationHoursLeft
end

function Internal.getReserveBarData(storedAmount, dailyNeed)
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

function Internal.getNutritionBarData(unitLabel, currentBufferAmount, carryoverAmount, provisionReserveAmount, dailyNeed)
    local unitName = tostring(unitLabel or "Nutrition")
    local currentBuffer = math.max(0, tonumber(currentBufferAmount) or 0)
    local carryover = math.max(0, tonumber(carryoverAmount) or 0)
    local provisionReserve = math.max(0, tonumber(provisionReserveAmount) or 0)
    local data = Internal.getReserveBarData(currentBuffer, dailyNeed)
    data.carryover = carryover
    data.provisionReserve = provisionReserve
    data.currentBuffer = currentBuffer
    data.daysLeft = Internal.getReserveDaysLeft(currentBuffer + carryover + provisionReserve, dailyNeed)
    data.summaryText = unitName .. " Reserve " .. formatReserveValue(provisionReserve)
        .. " | Carryover " .. formatReserveValue(carryover)
    return data
end

function Internal.getHealthBarData(currentHp, maxHp, worker)
    local safeMax = math.max(1, tonumber(maxHp) or 100)
    local safeCurrent = math.max(0, math.min(safeMax, tonumber(currentHp) or safeMax))
    local treatmentActive = worker and worker.selfTreatmentActive == true and (tonumber(worker.selfTreatmentHealRemaining) or 0) > 0
    local treatmentLabel = treatmentActive and tostring(worker.selfTreatmentLabel or "bandage") or nil
    local treatmentHealRemaining = treatmentActive and math.max(0, tonumber(worker.selfTreatmentHealRemaining) or 0) or 0
    local captionText = safeCurrent <= 0 and "dead" or "current hp"
    if treatmentActive then
        captionText = tostring(treatmentLabel) .. " healing +" .. formatReserveValue(treatmentHealRemaining) .. " hp left"
    end
    return {
        stored = safeCurrent,
        usage = safeMax,
        fillRatio = safeCurrent / safeMax,
        overflow = 0,
        daysLeft = nil,
        captionText = captionText,
        summaryText = formatReserveValue(safeCurrent) .. " / " .. formatReserveValue(safeMax),
        treatmentActive = treatmentActive,
        treatmentTierID = worker and worker.selfTreatmentTierID or nil,
        treatmentLabel = treatmentLabel,
        treatmentItemFullType = worker and worker.selfTreatmentItemFullType or nil,
        treatmentHealRemaining = treatmentHealRemaining,
        treatmentRegenPerHour = treatmentActive and math.max(0, tonumber(worker.selfTreatmentRegenPerHour) or 0) or 0,
        treatmentOverlayText = treatmentActive and ("+" .. formatReserveValue(treatmentHealRemaining) .. " hp") or nil,
    }
end

function Internal.getWorkerProgressData(worker, profile)
    local interaction = DC_Colony and DC_Colony.Interaction or nil
    if not interaction or not interaction.GetProgressDescriptor then
        return nil
    end

    local data = interaction.GetProgressDescriptor(worker, profile)
    if not data then
        return nil
    end

    data.stored = tonumber(data.progressAmount) or tonumber(data.progressHours) or 0
    data.usage = tonumber(data.workTarget) or tonumber(data.cycleHours) or 0
    data.overflow = 0
    data.daysLeft = nil
    return data
end

function Internal.getScavengeSearchProgressData(worker, profile)
    return Internal.getWorkerProgressData(worker, profile)
end
