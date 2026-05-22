local Config = DC_Colony.Config
local Internal = DC_Colony.Sim.Internal

Internal.getBaseTravelHours = function()
    return math.max(
        0,
        tonumber(Config.GetScavengeTravelHours and Config.GetScavengeTravelHours())
            or tonumber(Config.DEFAULT_SCAVENGE_TRAVEL_HOURS)
            or 0
    )
end

Internal.buildTravelPoint = function(source, fallbackX, fallbackY, fallbackZ)
    if type(source) == "table" then
        local x = tonumber(source.x)
        local y = tonumber(source.y)
        if x ~= nil and y ~= nil then
            return {
                x = math.floor(x),
                y = math.floor(y),
                z = math.floor(tonumber(source.z) or 0),
            }
        end
    end

    if tonumber(fallbackX) == nil or tonumber(fallbackY) == nil then
        return nil
    end

    return {
        x = math.floor(tonumber(fallbackX) or 0),
        y = math.floor(tonumber(fallbackY) or 0),
        z = math.floor(tonumber(fallbackZ) or 0),
    }
end

Internal.getDistanceTravelHoursBetweenPoints = function(fromPoint, toPoint, options)
    options = type(options) == "table" and options or {}

    local origin = Internal.buildTravelPoint(fromPoint)
    local destination = Internal.buildTravelPoint(toPoint)
    local baseHours = math.max(0, tonumber(options.baseHours) or Internal.getBaseTravelHours() or 0)
    local baselineDistanceTiles = math.max(1, tonumber(options.baselineDistanceTiles) or 450)
    local zTileWeight = math.max(0, tonumber(options.zTileWeight) or 90)
    local minHours = math.max(0, tonumber(options.minHours) or math.min(0.10, baseHours))
    local maxHours = math.max(minHours, tonumber(options.maxHours) or math.max(baseHours, minHours))

    if not origin or not destination then
        return math.max(minHours, baseHours)
    end

    local dx = destination.x - origin.x
    local dy = destination.y - origin.y
    local dz = math.abs((tonumber(destination.z) or 0) - (tonumber(origin.z) or 0))
    local effectiveDistance = math.sqrt((dx * dx) + (dy * dy)) + (dz * zTileWeight)

    if effectiveDistance <= 0 then
        return minHours
    end

    local hours = (effectiveDistance / baselineDistanceTiles) * math.max(baseHours, 0.01)
    if options.roundToMinutes ~= false then
        hours = math.ceil(hours * 60) / 60
    end

    return math.max(minHours, math.min(maxHours, hours))
end

Internal.getWorkerTravelHours = function(worker, targetPoint, options)
    options = type(options) == "table" and options or {}
    if Internal.ensureWorkerHome then
        Internal.ensureWorkerHome(worker)
    end

    local origin = Internal.buildTravelPoint(nil, worker and worker.homeX or nil, worker and worker.homeY or nil, worker and worker.homeZ or nil)
    if not origin then
        origin = Internal.buildTravelPoint(nil, worker and worker.workX or nil, worker and worker.workY or nil, worker and worker.workZ or nil)
    end

    return Internal.getDistanceTravelHoursBetweenPoints(origin, targetPoint, options)
end

Internal.getRequiredTravelReserveForHours = function(worker, profile, travelHours, multiplier)
    local factor = math.max(0, tonumber(multiplier) or 1)
    local hours = math.max(0, tonumber(travelHours) or Internal.getBaseTravelHours())
    return math.max(0, tonumber(Config.GetEffectiveHourlyCaloriesNeed(worker, profile)) or 0) * hours * factor,
        math.max(0, tonumber(Config.GetEffectiveHourlyHydrationNeed(worker, profile)) or 0) * hours * factor
end
