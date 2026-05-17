require "DC/Common/Zone/DC_ZoneDataStore"

DC_Colony = DC_Colony or {}
DC_Colony.Defense = DC_Colony.Defense or {}

local Defense = DC_Colony.Defense

local function getStore()
    return DC_ZoneDataStore
end

Defense.Runtime = Defense.Runtime or {
    colonies = {}
}

Defense.ALERT_TTL_MS = Defense.ALERT_TTL_MS or 8000

local function getConfig()
    return DC_Colony and DC_Colony.Config or nil
end

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function normalizeOwner(ownerUsername)
    local config = getConfig()
    if config and config.GetOwnerUsername then
        return config.GetOwnerUsername(ownerUsername)
    end
    return tostring(ownerUsername or "local")
end

local function getColonyID(ownerUsername)
    local owner = normalizeOwner(ownerUsername)
    local registry = getRegistry()
    local colonyID = registry and registry.GetColonyIDForOwner and registry.GetColonyIDForOwner(owner, false) or nil
    return tostring(colonyID or owner or "local")
end

local function nowMillis()
    return getTimeInMillis and getTimeInMillis() or 0
end

local function floorNumber(value)
    if tonumber(value) == nil then
        return nil
    end
    return math.floor(tonumber(value) or 0)
end

local function buildPoint(x, y, z)
    local px = floorNumber(x)
    local py = floorNumber(y)
    if px == nil or py == nil then
        return nil
    end

    return {
        x = px,
        y = py,
        z = floorNumber(z) or 0,
    }
end

local function copyPoint(point)
    if type(point) ~= "table" then
        return nil
    end
    return buildPoint(point.x, point.y, point.z)
end

local function isLivingWorker(worker)
    if type(worker) ~= "table" then
        return false
    end

    local config = getConfig()
    local states = config and config.States or {}
    local state = tostring(worker.state or "")
    if state == tostring(states.Dead or "Dead") then
        return false
    end
    if tonumber(worker.hp) ~= nil and tonumber(worker.hp) <= 0 then
        return false
    end
    return true
end

local function isWorkerIncapacitated(worker)
    local config = getConfig()
    local states = config and config.States or {}
    return tostring(worker and worker.state or "") == tostring(states.Incapacitated or "Incapacitated")
end

local function getWorkerPresenceState(worker)
    local config = getConfig()
    local states = config and config.PresenceStates or {}
    return tostring(worker and worker.presenceState or states.Home or "Home")
end

function Defense.GetRuntime(ownerUsername)
    local owner = normalizeOwner(ownerUsername)
    local runtime = Defense.Runtime.colonies[owner]
    if type(runtime) ~= "table" then
        runtime = {
            ownerUsername = owner,
            colonyID = getColonyID(owner),
            zoneRevision = "0",
            perimeterPosts = nil,
            alert = nil,
            lastThreat = nil,
        }
        Defense.Runtime.colonies[owner] = runtime
    end

    runtime.colonyID = getColonyID(owner)
    local store = getStore()
    runtime.zoneRevision = tostring(store and store.GetColonyVersion and store.GetColonyVersion(runtime.colonyID) or 0)
    return runtime
end

function Defense.InvalidateOwner(ownerUsername)
    local owner = normalizeOwner(ownerUsername)
    local runtime = Defense.Runtime.colonies[owner]
    if type(runtime) ~= "table" then
        return false
    end

    runtime.perimeterPosts = nil
    local store = getStore()
    runtime.zoneRevision = tostring(store and store.GetColonyVersion and store.GetColonyVersion(runtime.colonyID) or 0)
    return true
end

local function resolveSourcePoint(source)
    if type(source) ~= "table" then
        return nil
    end

    if type(source.point) == "table" then
        return copyPoint(source.point)
    end
    if type(source.target) == "table" and source.target.getX and source.target.getY then
        return buildPoint(source.target:getX(), source.target:getY(), source.target.getZ and source.target:getZ() or 0)
    end
    if source.getX and source.getY then
        return buildPoint(source:getX(), source:getY(), source.getZ and source:getZ() or 0)
    end
    return buildPoint(source.x, source.y, source.z)
end

function Defense.ClearExpiredAlerts(ownerUsername)
    local runtime = Defense.GetRuntime(ownerUsername)
    local alert = runtime and runtime.alert or nil
    if type(alert) ~= "table" then
        return false
    end

    if (tonumber(alert.expiresAt) or 0) > nowMillis() then
        return false
    end

    runtime.alert = nil
    return true
end

function Defense.GetAlert(ownerUsername)
    local runtime = Defense.GetRuntime(ownerUsername)
    Defense.ClearExpiredAlerts(ownerUsername)
    if type(runtime.alert) ~= "table" then
        return nil
    end
    return runtime.alert
end

function Defense.RaiseAlert(ownerUsername, source)
    local runtime = Defense.GetRuntime(ownerUsername)
    if type(runtime) ~= "table" then
        return nil
    end

    local point = resolveSourcePoint(source)
    local previous = type(runtime.alert) == "table" and runtime.alert or nil
    local expiresAt = nowMillis() + math.max(1000, math.floor(tonumber(Defense.ALERT_TTL_MS) or 8000))
    local count = math.max(0, tonumber(previous and previous.count) or 0) + 1

    runtime.alert = {
        ownerUsername = runtime.ownerUsername,
        colonyID = runtime.colonyID,
        x = point and point.x or previous and previous.x or nil,
        y = point and point.y or previous and previous.y or nil,
        z = point and point.z or previous and previous.z or 0,
        reason = tostring(source and source.reason or previous and previous.reason or "threat"),
        count = count,
        expiresAt = expiresAt,
        zoneRevision = runtime.zoneRevision,
        source = tostring(source and source.source or "colony"),
    }

    runtime.lastThreat = {
        point = point and copyPoint(point) or nil,
        seenAt = nowMillis(),
        reason = runtime.alert.reason,
    }

    return runtime.alert
end

function Defense.GetZoneRevision(ownerUsername)
    local runtime = Defense.GetRuntime(ownerUsername)
    return runtime and tostring(runtime.zoneRevision or "0") or "0"
end

function Defense.BuildAnchorRevision(worker, homeCoords, workCoords, dutyMode)
    local pointA = homeCoords or {}
    local pointB = workCoords or {}
    local owner = worker and worker.ownerUsername or nil
    return table.concat({
        tostring(Defense.GetZoneRevision(owner)),
        tostring(worker and worker.workerID or ""),
        tostring(dutyMode or ""),
        tostring(pointA.x or "nil"),
        tostring(pointA.y or "nil"),
        tostring(pointA.z or "nil"),
        tostring(pointB.x or "nil"),
        tostring(pointB.y or "nil"),
        tostring(pointB.z or "nil"),
        tostring(worker and worker.assignedProjectBuildingID or ""),
        tostring(worker and worker.housingBuildingID or ""),
        tostring(worker and worker.infirmaryBuildingID or ""),
    }, "|")
end

function Defense.GetWorkerDutyMode(worker)
    local config = getConfig()
    local states = config and config.States or {}
    local jobTypes = config and config.JobTypes or {}
    local normalizedJob = config and config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")
    local state = tostring(worker and worker.state or "")
    local presenceState = getWorkerPresenceState(worker)

    if not isLivingWorker(worker) then
        return "rest"
    end

    if isWorkerIncapacitated(worker) then
        return "rest"
    end

    if presenceState ~= tostring((config and config.PresenceStates and config.PresenceStates.Home) or "Home") then
        if normalizedJob == tostring(jobTypes.Guard or "Guard") then
            return "guard"
        end
        if state == tostring(states.Working or "Working") then
            return "work"
        end
        if state == tostring(states.Resting or "Resting") then
            return "rest"
        end
    end

    if worker and worker.infirmaryBedAssigned == true and (tonumber(worker.hp) or 0) < (tonumber(worker.maxHp) or 0) then
        return "patient"
    end

    if state == tostring(states.Resting or "Resting") then
        return "rest"
    end

    if normalizedJob == tostring(jobTypes.Guard or "Guard") then
        return "guard"
    end

    if state == tostring(states.Working or "Working") then
        return "work"
    end

    return "idle"
end

function Defense.CanWorkerFight(worker, dutyMode)
    if dutyMode ~= "guard" then
        return false
    end
    if not isLivingWorker(worker) or isWorkerIncapacitated(worker) then
        return false
    end
    return true
end

function Defense.BuildWorkerRuntime(worker, homeCoords, workCoords)
    local dutyMode = Defense.GetWorkerDutyMode(worker)
    local canFight = Defense.CanWorkerFight(worker, dutyMode)
    local behaviorState = "ColonyCower"

    if dutyMode == "guard" then
        behaviorState = "Patrol"
    elseif dutyMode == "work" or dutyMode == "patient" then
        behaviorState = "ColonyWork"
    end

    return {
        dcDutyMode = dutyMode,
        dcCanFight = canFight == true,
        dcGuardPostIndex = math.max(1, math.floor(tonumber(worker and worker.dcGuardPostIndex) or 1)),
        dcAnchorRevision = Defense.BuildAnchorRevision(worker, homeCoords, workCoords, dutyMode),
        dcBehaviorState = behaviorState,
    }
end

return Defense
