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

local function syncCompanionWorker(player, worker)
    local companion = DC_Colony and DC_Colony.Companion or nil
    if companion and companion.SyncActiveNPCFromWorker then
        companion.SyncActiveNPCFromWorker(worker, true)
    end
    local residentBridge = DC_Colony and DC_Colony.ResidentBridge or nil
    if residentBridge and residentBridge.SyncWorker then
        local changed = residentBridge.SyncWorker(worker) == true
        if changed then
            local registry = DC_Colony and DC_Colony.Registry or nil
            if registry and registry.Save then
                registry.Save()
            end
            if DTNPCManager and DTNPCManager.CheckRosterSpawns then
                DTNPCManager.CheckRosterSpawns()
            end
        end
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

return Network
