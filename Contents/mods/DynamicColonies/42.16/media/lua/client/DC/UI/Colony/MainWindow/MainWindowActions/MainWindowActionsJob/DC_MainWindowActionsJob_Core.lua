DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal
local JobActions = Internal.JobActions or {}

JobActions.FlavorText = DC_Colony and DC_Colony.UI and DC_Colony.UI.MainWindowActionsJobFlavorText or {}

function JobActions.isFunction(value)
    return type(value) == "function"
end

function JobActions.debugJobAction(message)
    if DynamicTrading and DynamicTrading.LogDebug then
        DynamicTrading.LogDebug("DynamicColonies", "Job", "Client", tostring(message))
    elseif DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DynamicColonies", "Job", "Client", tostring(message))
    end
end

function JobActions.getConfig()
    local config = Internal.Config
    if type(config) ~= "table" then
        config = (DC_Colony and DC_Colony.Config) or {}
        Internal.Config = config
    end
    return config
end

function JobActions.formatReserveValue(value)
    if JobActions.isFunction(Internal.formatReserveValue) then
        return Internal.formatReserveValue(value)
    end
    return tostring(math.floor((tonumber(value) or 0) + 0.5))
end

function JobActions.getReserveDaysLeft(storedAmount, dailyNeed)
    if JobActions.isFunction(Internal.getReserveDaysLeft) then
        return Internal.getReserveDaysLeft(storedAmount, dailyNeed)
    end
    local perDay = tonumber(dailyNeed) or 0
    if perDay <= 0 then
        return nil
    end
    return math.max(0, (tonumber(storedAmount) or 0) / perDay)
end

function JobActions.getSelectedWorkerForAction(window)
    return window.selectedWorker or window.selectedWorkerSummary or nil
end

function JobActions.getLocalPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
end

function JobActions.getLocalUsername()
    local player = JobActions.getLocalPlayer()
    if player and player.getUsername then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then
            return username
        end
    end
    return nil
end

function JobActions.copyShallow(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = entry
    end
    return copy
end

function JobActions.getTravelHours(config, worker)
    return math.max(
        0,
        tonumber(config.GetScavengeTravelHours and config.GetScavengeTravelHours(worker))
            or tonumber(config.DEFAULT_SCAVENGE_TRAVEL_HOURS)
            or 0
    )
end

return JobActions
