DC_Base = DC_Base or {}
DC_Base.Internal = DC_Base.Internal or {}

local Base = DC_Base
local Internal = Base.Internal
local Config = DC_Colony.Config
local Registry = DC_Colony.Registry

local function isWorkerVisibleAtBase(worker)
    if not worker then
        return false
    end
    if tostring(worker.presenceState or "") ~= tostring(Config.PresenceStates.Home) then
        return false
    end
    local state = tostring(worker.state or "")
    if state == tostring(Config.States.Dead) then
        return false
    end
    return state == tostring(Config.States.Idle)
        or state == tostring(Config.States.Resting)
        or state == tostring(Config.States.Incapacitated)
end

local function hashWorkerID(workerID)
    local text = tostring(workerID or "")
    local total = 0
    for index = 1, #text do
        total = total + string.byte(text, index)
    end
    return total
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function resolveRect(rect)
    local x1 = math.min(tonumber(rect and rect[1]) or 0, tonumber(rect and rect[3]) or 0)
    local x2 = math.max(tonumber(rect and rect[1]) or 0, tonumber(rect and rect[3]) or 0)
    local y1 = math.min(tonumber(rect and rect[2]) or 0, tonumber(rect and rect[4]) or 0)
    local y2 = math.max(tonumber(rect and rect[2]) or 0, tonumber(rect and rect[4]) or 0)
    local z = math.floor(tonumber(rect and rect[5]) or 0)
    return x1, y1, x2, y2, z
end

function Base.GetEligibleVisibleHomeWorkers(ownerUsername)
    local workers = {}
    if not Registry or not Registry.GetWorkersForOwnerRaw then
        return workers
    end

    for _, worker in ipairs(Registry.GetWorkersForOwnerRaw(ownerUsername) or {}) do
        if isWorkerVisibleAtBase(worker) then
            workers[#workers + 1] = worker
        end
    end

    table.sort(workers, function(a, b)
        return tostring(a and a.workerID or "") < tostring(b and b.workerID or "")
    end)
    return workers
end

function Base.IsPlayerNearBase(ownerUsername, player)
    local baseZone = Base.GetBaseZone(ownerUsername)
    if not baseZone or not player then
        return false
    end

    local x = math.floor(player:getX())
    local y = math.floor(player:getY())
    local z = math.floor(player:getZ() or 0)
    if DC_ZoneData.isInsideZone(baseZone, x, y, z) then
        return true
    end

    local buffer = Base.Constants.NearbyEdgeBuffer
    for _, rect in ipairs(baseZone.rects or {}) do
        local x1, y1, x2, y2, rz = resolveRect(rect)
        if z == rz
            and x >= (x1 - buffer)
            and x <= (x2 + buffer)
            and y >= (y1 - buffer)
            and y <= (y2 + buffer) then
            return true
        end
    end

    return false
end

function Base.BuildHomeProjectionData(worker)
    if not worker then
        return nil
    end
    if tostring(worker.presenceState or "") ~= tostring(Config.PresenceStates.Home) then
        return nil
    end

    local owner = Internal.GetOwnerUsername(worker.ownerUsername)
    local baseState = Base.GetBaseState(owner)
    local baseZone = Base.GetBaseZone(owner)
    if not baseState
        or baseState.baseMode ~= Base.Constants.Modes.Settled
        or not baseZone
        or not baseZone.rects
        or not baseZone.rects[1] then
        return nil
    end

    local x1, y1, x2, y2, z = resolveRect(baseZone.rects[1])
    local hash = hashWorkerID(worker.workerID)
    local width = math.max(1, x2 - x1)
    local height = math.max(1, y2 - y1)
    local hqX = math.floor(tonumber(baseState.hqX) or x1)
    local hqY = math.floor(tonumber(baseState.hqY) or y1)
    local baseX = x1 + (hash % (width + 1))
    local baseY = y1 + (math.floor(hash / 7) % (height + 1))
    local targetX = clamp(math.floor((hqX + baseX) / 2), x1, x2)
    local targetY = clamp(math.floor((hqY + baseY) / 2), y1, y2)

    return {
        uuid = Config.GetProjectionUUID(worker.workerID),
        name = worker.name,
        archetypeID = Config.NormalizeArchetypeID(worker.archetypeID or worker.profession),
        isFemale = worker.isFemale,
        identitySeed = worker.identitySeed or 1,
        visualID = worker.visualID or (hash + 1000),
        lastX = targetX,
        lastY = targetY,
        lastZ = z,
        workCoords = { x = targetX, y = targetY, z = z },
        homeCoords = { x = baseState.hqX or targetX, y = baseState.hqY or targetY, z = baseState.hqZ or z },
        status = "Resting",
        state = "Idle",
        tasks = {},
        master = nil,
        masterID = nil,
        anchorX = targetX,
        anchorY = targetY,
        anchorZ = z,
        dcBaseProjection = true,
    }
end

return Base
