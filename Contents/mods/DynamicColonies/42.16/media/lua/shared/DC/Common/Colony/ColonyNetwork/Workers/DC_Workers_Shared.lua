DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Workers = Network.Workers or {}
local Internal = Network.Internal or {}

Workers.Shared = Workers.Shared or {}
Network.Workers = Workers
Network.Internal = Internal
Network.Handlers = Network.Handlers or {}

local Shared = Workers.Shared

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getConfig()
    return DC_Colony and DC_Colony.Config or nil
end

local function getSim()
    return DC_Colony and DC_Colony.Sim or nil
end

local function getPresentation()
    return DC_Colony and DC_Colony.Presentation or nil
end

local function copyPoint(point)
    if type(point) ~= "table" then
        return nil
    end

    return {
        x = math.floor(tonumber(point.x) or 0),
        y = math.floor(tonumber(point.y) or 0),
        z = math.floor(tonumber(point.z) or 0)
    }
end

local function hasPoint(point)
    return type(point) == "table"
        and tonumber(point.x) ~= nil
        and tonumber(point.y) ~= nil
end

local function findWorkerUUID(worker)
    local uuid = tostring(worker and worker.residentSoulUUID or "")
    if uuid ~= "" then
        return uuid
    end

    local companionData = type(worker and worker.companion) == "table" and worker.companion or nil
    uuid = companionData and tostring(companionData.uuid or "") or ""
    if uuid ~= "" then
        return uuid
    end

    return nil
end

local function resetWorkerCompanionState(worker)
    local companionData = type(worker and worker.companion) == "table" and worker.companion or nil
    if not companionData then
        return
    end

    companionData.stage = nil
    companionData.awaitingDespawn = false
    companionData.currentOrder = nil
    companionData.returnReason = nil
    companionData.returnTravelHours = nil
    companionData.commandInvalidSinceMs = nil
end

local function teleportLiveNPCToPoint(uuid, point)
    if not uuid or not hasPoint(point) or not DTNPCServerCore or not DTNPCServerCore.GetNPCDataByUUID then
        return false
    end

    local zombie, npcData = DTNPCServerCore.GetNPCDataByUUID(uuid)
    if not zombie or zombie:isDead() then
        return false
    end

    local x = math.floor(tonumber(point.x) or 0)
    local y = math.floor(tonumber(point.y) or 0)
    local z = math.floor(tonumber(point.z) or 0)

    zombie:setX(x)
    zombie:setY(y)
    zombie:setZ(z)
    zombie:setLastX(x)
    zombie:setLastY(y)

    if zombie.setUseless and not zombie:isUseless() then
        zombie:setUseless(true)
    end

    if type(npcData) == "table" then
        npcData.lastX = x
        npcData.lastY = y
        npcData.lastZ = z
        if DTNPC and DTNPC.AttachData then
            DTNPC.AttachData(zombie, npcData)
        end
        if DTNPCServerCore.SyncToAllClients then
            DTNPCServerCore.SyncToAllClients(zombie, npcData)
        end
        if DTNPCServerCore.BroadcastPosition then
            DTNPCServerCore.BroadcastPosition(zombie, npcData)
        end
    end

    return true
end

local function syncCompanionWorker(player, worker)
    local companion = DC_Colony and DC_Colony.Companion or nil
    if companion and companion.SyncActiveNPCFromWorker then
        companion.SyncActiveNPCFromWorker(worker, true)
    end
    local residentBridge = DC_Colony and DC_Colony.ResidentBridge or nil
    if residentBridge and residentBridge.QueueWorkerSync then
        residentBridge.QueueWorkerSync(worker)
    end
end

local function getPlayerTransferOwner(player)
    local Config = getConfig()
    return Config and Config.GetOwnerUsername and Config.GetOwnerUsername(player) or tostring(player and player.getUsername and player:getUsername() or "local")
end

function Shared.normalizeItemIDs(args)
    local itemIDs = {}
    local seen = {}

    for _, itemID in ipairs(args and args.itemIDs or {}) do
        local key = tostring(itemID or "")
        if key ~= "" and not seen[key] then
            seen[key] = true
            itemIDs[#itemIDs + 1] = itemID
        end
    end

    if args and args.itemID then
        local key = tostring(args.itemID or "")
        if key ~= "" and not seen[key] then
            itemIDs[#itemIDs + 1] = args.itemID
        end
    end

    return itemIDs
end

function Shared.beginItemTransferLocks(player, itemIDs)
    Internal.ActiveSupplyItemTransfers = Internal.ActiveSupplyItemTransfers or {}
    local owner = getPlayerTransferOwner(player)
    local reserved = {}
    local rejected = {}

    for _, itemID in ipairs(itemIDs or {}) do
        local key = tostring(owner) .. "|" .. tostring(itemID or "")
        if Internal.ActiveSupplyItemTransfers[key] then
            rejected[#rejected + 1] = {
                itemID = itemID,
                reason = "already_processing",
            }
        else
            Internal.ActiveSupplyItemTransfers[key] = true
            reserved[#reserved + 1] = {
                itemID = itemID,
                key = key,
            }
        end
    end

    return reserved, rejected
end

function Shared.releaseItemTransferLocks(reserved)
    for _, lock in ipairs(reserved or {}) do
        if lock and lock.key and Internal.ActiveSupplyItemTransfers then
            Internal.ActiveSupplyItemTransfers[lock.key] = nil
        end
    end
end

function Shared.syncSupplyTransferResult(player, args, result)
    result = result or {}
    Internal.sendResponse(player, (getConfig() or {}).COMMAND_MODULE or "DColony", "SupplyTransferResult", {
        requestID = args and args.requestID or nil,
        requestKind = args and args.requestKind or nil,
        command = args and args.command or nil,
        acceptedItemIDs = result.acceptedItemIDs or {},
        rejected = result.rejected or {},
        movedCount = math.max(0, tonumber(result.movedCount) or #(result.acceptedItemIDs or {})),
        message = result.message,
        refreshPlayerInventory = result.refreshPlayerInventory == true,
    })
end

function Shared.normalizeLedgerIndexes(args)
    local indexes = {}
    local seen = {}

    for _, index in ipairs(args and args.ledgerIndexes or {}) do
        local normalized = math.floor(tonumber(index) or 0)
        if normalized > 0 and not seen[normalized] then
            seen[normalized] = true
            indexes[#indexes + 1] = normalized
        end
    end

    if args and args.ledgerIndex then
        local normalized = math.floor(tonumber(args.ledgerIndex) or 0)
        if normalized > 0 and not seen[normalized] then
            indexes[#indexes + 1] = normalized
        end
    end

    table.sort(indexes, function(a, b)
        return a > b
    end)

    return indexes
end

function Shared.normalizeLedgerQuantities(args)
    local quantities = {}
    local requests = args and args.ledgerRequests or nil

    for _, request in ipairs(requests or {}) do
        local index = math.floor(tonumber(request and request.ledgerIndex) or 0)
        local qty = math.max(1, math.floor(tonumber(request and request.qty) or 1))
        if index > 0 then
            quantities[index] = qty
        end
    end

    if args and args.ledgerIndex then
        local index = math.floor(tonumber(args.ledgerIndex) or 0)
        if index > 0 then
            quantities[index] = math.max(1, math.floor(tonumber(args.requestedQty) or quantities[index] or 1))
        end
    end

    return quantities
end

function Shared.getCurrentWorldHours()
    local Config = getConfig()
    if not Config then
        return 0
    end

    return (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour()
end

function Shared.saveAndRefreshProcessed(player, worker, syncProjection)
    local Registry = getRegistry()
    local Sim = getSim()

    if Registry and Registry.Save then
        Registry.Save()
    end
    if Sim and Sim.ProcessWorker then
        Sim.ProcessWorker(worker, Shared.getCurrentWorldHours())
    end
    syncCompanionWorker(player, worker)
    Internal.syncWorkerDetail(player, worker.workerID, nil, true)
    Internal.syncWorkerList(player)
    if syncProjection then
        Internal.syncWarehouse(player, nil, true)
    end
end

function Shared.saveAndRefreshSupplyTransfer(player, worker, syncProjection)
    local Registry = getRegistry()
    local Sim = getSim()

    if Registry and Registry.Save then
        Registry.Save()
    end
    if Sim and Sim.ProcessWorker then
        Sim.ProcessWorker(worker, Shared.getCurrentWorldHours())
    end
    syncCompanionWorker(player, worker)
    Internal.syncWorkerDetail(player, worker.workerID, nil, true)
    if syncProjection then
        Internal.syncWarehouse(player, nil, true)
    end
end

function Shared.saveAndRefreshBasic(player, worker, syncProjection)
    local Registry = getRegistry()

    if Registry and Registry.Save then
        Registry.Save()
    end
    syncCompanionWorker(player, worker)
    Internal.syncWorkerDetail(player, worker.workerID, nil, true)
    Internal.syncWorkerList(player)
    if syncProjection then
        Internal.syncWarehouse(player, nil, true)
    end
end

function Shared.ResetOwnerNPCsToBase(player)
    local Config = getConfig()
    local Registry = getRegistry()
    local residentBridge = DC_Colony and DC_Colony.ResidentBridge or nil
    local realBase = DC_ZoneRealBase or nil

    if not player or not Config or not Registry then
        return false, "Colony systems are unavailable right now."
    end

    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(player)
        or tostring(player and player.getUsername and player:getUsername() or "local")
    local basePoint = realBase and realBase.ResolveBaseTarget and realBase.ResolveBaseTarget(owner) or nil
    if not hasPoint(basePoint) then
        return false, "Place a player base zone first."
    end

    local presenceStates = Config.PresenceStates or {}
    local workerStates = Config.States or {}
    local homeState = tostring(presenceStates.Home or "Home")
    local idleState = tostring(workerStates.Idle or "Idle")
    local deadState = tostring(workerStates.Dead or "Dead")
    local incapacitatedState = tostring(workerStates.Incapacitated or "Incapacitated")
    local changedWorkerIDs = {}
    local livingCount = 0
    local teleportedCount = 0

    for _, worker in ipairs(Registry.GetWorkersForOwnerRaw(owner) or {}) do
        local state = tostring(worker and worker.state or "")
        local hp = tonumber(worker and worker.hp)
        if worker and state ~= deadState and (hp == nil or hp > 0) then
            livingCount = livingCount + 1

            worker.homeX = math.floor(tonumber(basePoint.x) or 0)
            worker.homeY = math.floor(tonumber(basePoint.y) or 0)
            worker.homeZ = math.floor(tonumber(basePoint.z) or 0)
            worker.presenceState = homeState
            worker.travelHoursRemaining = 0
            worker.returnReason = nil
            if state ~= incapacitatedState then
                worker.state = idleState
            end

            resetWorkerCompanionState(worker)

            if residentBridge and residentBridge.SyncWorker then
                residentBridge.SyncWorker(worker)
            end

            local targetPoint = copyPoint({
                x = worker.homeX,
                y = worker.homeY,
                z = worker.homeZ or 0
            }) or copyPoint(basePoint)
            local uuid = findWorkerUUID(worker)
            if teleportLiveNPCToPoint(uuid, targetPoint) then
                teleportedCount = teleportedCount + 1
            end

            changedWorkerIDs[#changedWorkerIDs + 1] = worker.workerID
        end
    end

    if livingCount <= 0 then
        return false, "No living colony NPCs were found to reset."
    end

    if Registry.Save then
        Registry.Save()
    end
    if DTNPCManager and DTNPCManager.CheckRosterSpawns then
        DTNPCManager.CheckRosterSpawns()
    end

    local message = "Reset " .. tostring(livingCount) .. " colony NPCs to your current base."
    local sent = 0
    if Internal.forEachOnlineOwnerPlayer then
        sent = Internal.forEachOnlineOwnerPlayer(owner, function(ownerPlayer)
            if Internal.syncNotice then
                Internal.syncNotice(ownerPlayer, message, "info", false)
            end
            if Internal.syncWorkerListFocused then
                Internal.syncWorkerListFocused(ownerPlayer, owner)
            elseif Internal.syncWorkerList then
                Internal.syncWorkerList(ownerPlayer)
            end
            if Internal.syncWorkerUpdated then
                for _, workerID in ipairs(changedWorkerIDs) do
                    Internal.syncWorkerUpdated(ownerPlayer, owner, workerID)
                end
            end
        end)
    end

    if sent <= 0 then
        if Internal.syncNotice then
            Internal.syncNotice(player, message, "info", false)
        end
        if Internal.syncWorkerListFocused then
            Internal.syncWorkerListFocused(player, owner)
        elseif Internal.syncWorkerList then
            Internal.syncWorkerList(player)
        end
        if Internal.syncWorkerUpdated then
            for _, workerID in ipairs(changedWorkerIDs) do
                Internal.syncWorkerUpdated(player, owner, workerID)
            end
        end
    end

    return true, message, {
        livingCount = livingCount,
        teleportedCount = teleportedCount,
    }
end

Network.Handlers.ResetAllOwnedNPCsToBase = function(player, _args)
    local ok, message = Shared.ResetOwnerNPCsToBase(player)
    if not ok and Internal.syncNotice then
        Internal.syncNotice(player, message or "Unable to reset colony NPCs to base.", "error", true)
    end
end

return Network
