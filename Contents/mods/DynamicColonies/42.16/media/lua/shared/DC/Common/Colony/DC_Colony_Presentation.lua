require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Base/DC_Base"

DC_Colony = DC_Colony or {}
DC_Colony.Presentation = DC_Colony.Presentation or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Presentation = DC_Colony.Presentation

if isClient() and not isServer() then
    return Presentation
end

Presentation.tickCounter = Presentation.tickCounter or 0

local function getActivePlayers()
    if DTNPCManager and DTNPCManager.GetActivePlayers then
        return DTNPCManager.GetActivePlayers()
    end

    local players = {}
    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            players[#players + 1] = onlinePlayers:get(i)
        end
        return players
    end

    local player = Config.GetPlayerObject()
    if player then
        players[1] = player
    end
    return players
end

local function isProjectionRuntimeAvailable()
    return DTNPCServerCore and DTNPCServerCore.RespawnNPC and DTNPCServerCore.FindZombieByUUID
end

local function getProjectionCoords(npcData, worker)
    if type(npcData) == "table" then
        local workCoords = type(npcData.workCoords) == "table" and npcData.workCoords or nil
        local x = tonumber(npcData.anchorX) or tonumber(npcData.lastX) or tonumber(workCoords and workCoords.x)
        local y = tonumber(npcData.anchorY) or tonumber(npcData.lastY) or tonumber(workCoords and workCoords.y)
        local z = tonumber(npcData.anchorZ) or tonumber(npcData.lastZ) or tonumber(workCoords and workCoords.z)
        if x and y then
            return x, y, z or 0
        end
    end

    if worker and worker.workX and worker.workY then
        return worker.workX, worker.workY, worker.workZ or 0
    end

    return nil, nil, nil
end

local function pruneProjectionRegistration(uuid, zombie)
    if not uuid or not DTNPCManager then return end
    local changed = false

    if DTNPCManager.Data then
        if DTNPCManager.Data[uuid] ~= nil then
            DTNPCManager.Data[uuid] = nil
            changed = true
        end
    end
    if DTNPCManager.PendingRegistrations then
        if DTNPCManager.PendingRegistrations[uuid] ~= nil then
            DTNPCManager.PendingRegistrations[uuid] = nil
            changed = true
        end
    end

    if zombie and DTNPCManager.OutfitIDToUUID then
        local outfitID = zombie:getPersistentOutfitID()
        if DTNPCManager.OutfitIDToUUID[outfitID] ~= nil then
            DTNPCManager.OutfitIDToUUID[outfitID] = nil
            changed = true
        end
    end

    if DTNPC_SpatialHash and DTNPC_SpatialHash.RemoveNPC then
        DTNPC_SpatialHash.RemoveNPC(uuid)
    end
    if DTNPC_DistanceFrequency and DTNPC_DistanceFrequency.RemoveNPC then
        DTNPC_DistanceFrequency.RemoveNPC(uuid)
    end

    if changed and DTNPCManager.Save then
        DTNPCManager.Save()
    end
end

function Presentation.BuildProjectionData(worker)
    if not worker then return nil end

    if DC_Base and DC_Base.BuildHomeProjectionData then
        local homeProjection = DC_Base.BuildHomeProjectionData(worker)
        if homeProjection then
            return homeProjection
        end
    end

    return {
        uuid = Config.GetProjectionUUID(worker.workerID),
        name = worker.name,
        archetypeID = Config.NormalizeArchetypeID(worker.archetypeID or worker.profession),
        isFemale = worker.isFemale,
        identitySeed = worker.identitySeed or 1,
        visualID = worker.visualID or ZombRand(1000000),
        lastX = worker.workX,
        lastY = worker.workY,
        lastZ = worker.workZ or 0,
        workCoords = { x = worker.workX, y = worker.workY, z = worker.workZ or 0 },
        homeCoords = { x = worker.homeX or worker.workX, y = worker.homeY or worker.workY, z = worker.homeZ or worker.workZ or 0 },
        status = "Working",
        state = "Guard",
        tasks = {},
        master = nil,
        masterID = nil,
        anchorX = worker.workX,
        anchorY = worker.workY,
        anchorZ = worker.workZ or 0
    }
end

function Presentation.RemoveProjection(worker)
    if not isProjectionRuntimeAvailable() or not worker then return end

    local uuid = Config.GetProjectionUUID(worker.workerID)
    local zombie = DTNPCServerCore.FindZombieByUUID(uuid)
    if zombie then
        zombie:removeFromWorld()
        zombie:removeFromSquare()
    end

    if DTNPCManager and DTNPCManager.RemoveData then
        DTNPCManager.RemoveData(uuid, nil, nil, nil, "labour-projection")
    end
end

local function canProjectWorker(worker)
    if worker
        and DC_Base
        and DC_Base.GetBaseState
        and DC_Base.GetEligibleVisibleHomeWorkers then
        local baseState = DC_Base.GetBaseState(worker.ownerUsername)
        if baseState and baseState.baseMode == "Settled" then
            local eligible = DC_Base.GetEligibleVisibleHomeWorkers(worker.ownerUsername)
            local maxVisible = (DC_Base.Constants and DC_Base.Constants.MaxVisibleHomeWorkers) or 4
            for index = 1, math.min(#eligible, maxVisible) do
                if eligible[index] and tostring(eligible[index].workerID or "") == tostring(worker.workerID or "") then
                    return true
                end
            end
        end
    end

    return worker
        and Config.IsOwnerOnline
        and Config.IsOwnerOnline(worker.ownerUsername)
        and worker.jobEnabled
        and worker.state == Config.States.Working
        and worker.presenceState == Config.PresenceStates.Scavenging
        and worker.workX and worker.workY
end

local function isPlayerNearWorker(worker, players)
    local projectionData = Presentation.BuildProjectionData(worker)
    if worker and DC_Base and DC_Base.IsPlayerNearBase then
        for _, player in ipairs(players or {}) do
            if player and DC_Base.IsPlayerNearBase(worker.ownerUsername, player) then
                return true
            end
        end
    end

    local workX, workY, wz = getProjectionCoords(projectionData, worker)
    if not workX or not workY then
        return false
    end

    for _, player in ipairs(players or {}) do
        if player then
            local dx = player:getX() - workX
            local dy = player:getY() - workY
            local dz = math.abs((player:getZ() or 0) - wz)
            local dist = math.sqrt(dx * dx + dy * dy)
            if dz <= 1 and dist <= Config.PROJECTION_RANGE then
                return true
            end
        end
    end
    return false
end

function Presentation.SyncWorker(worker, players)
    if not isProjectionRuntimeAvailable() or not worker then
        return
    end

    if not canProjectWorker(worker) then
        Presentation.RemoveProjection(worker)
        return
    end

    if not isPlayerNearWorker(worker, players) then
        Presentation.RemoveProjection(worker)
        return
    end

    local uuid = Config.GetProjectionUUID(worker.workerID)
    local zombie = DTNPCServerCore.FindZombieByUUID(uuid)
    local npcData = Presentation.BuildProjectionData(worker)
    if not npcData then return end
    local targetX, targetY, targetZ = getProjectionCoords(npcData, worker)
    if not targetX or not targetY then
        Presentation.RemoveProjection(worker)
        return
    end

    if zombie then
        zombie:setX(targetX)
        zombie:setY(targetY)
        zombie:setZ(targetZ or 0)
        npcData.currentOutfitID = zombie:getPersistentOutfitID()
        DTNPC.AttachData(zombie, npcData)
        if DTNPCServerCore.SyncToAllClients then
            DTNPCServerCore.SyncToAllClients(zombie, npcData)
        end
        pruneProjectionRegistration(uuid, zombie)
        return
    end

    local spawnedZombie = DTNPCServerCore.RespawnNPC(npcData, uuid)
    pruneProjectionRegistration(uuid, spawnedZombie)
end

function Presentation.SyncAllWorkers()
    if not isProjectionRuntimeAvailable() then
        return
    end

    local players = getActivePlayers()
    Registry.ForEachWorkerRaw(function(worker)
        Presentation.SyncWorker(worker, players)
    end)
end

function Presentation.OnTick()
    Presentation.tickCounter = Presentation.tickCounter + 1
    if Presentation.tickCounter < Config.PRESENTATION_TICK_RATE then
        return
    end

    Presentation.tickCounter = 0
    Presentation.SyncAllWorkers()
end

Events.OnTick.Add(Presentation.OnTick)

return Presentation
