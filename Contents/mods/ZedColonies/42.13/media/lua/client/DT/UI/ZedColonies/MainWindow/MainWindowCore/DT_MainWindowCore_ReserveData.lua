DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

require "DT/Common/ZedColonies/LabourInteraction/DT_Labour_Interaction"

local Internal = DT_MainWindow.Internal

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

function Internal.getHealthBarData(currentHp, maxHp)
    local safeMax = math.max(1, tonumber(maxHp) or 100)
    local safeCurrent = math.max(0, math.min(safeMax, tonumber(currentHp) or safeMax))
    return {
        stored = safeCurrent,
        usage = safeMax,
        fillRatio = safeCurrent / safeMax,
        overflow = 0,
        daysLeft = nil,
        captionText = safeCurrent <= 0 and "dead" or "current hp",
        summaryText = formatReserveValue(safeCurrent) .. " / " .. formatReserveValue(safeMax)
    }
end

function Internal.getWorkerProgressData(worker, profile)
    local interaction = DT_Labour and DT_Labour.Interaction or nil
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
