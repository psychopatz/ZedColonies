DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = Internal.ColonyNetShared or {}
local Config = Shared.Config or {}
local Registry = Shared.Registry or {}

local function stripLedgerEntryFields(entry)
    if type(entry) ~= "table" then
        return entry
    end

    entry.entryID = nil
    if entry.fullType then
        entry.displayName = nil
        entry.consumedOutputDisplayName = nil
    end
    entry.pending = nil
    entry.transferPending = nil
    return entry
end

local function stripLedgerEntries(entries)
    if type(entries) ~= "table" then
        return entries
    end

    for _, entry in ipairs(entries) do
        stripLedgerEntryFields(entry)
    end
    return entries
end

local function stripWorkerPacket(worker)
    if type(worker) ~= "table" then
        return worker
    end

    stripLedgerEntries(worker.nutritionLedger)
    stripLedgerEntries(worker.toolLedger)
    stripLedgerEntries(worker.haulLedger)
    stripLedgerEntries(worker.outputLedger)
    if type(worker.warehouse) == "table" and type(worker.warehouse.ledgers) == "table" then
        stripLedgerEntries(worker.warehouse.ledgers.provisions)
        stripLedgerEntries(worker.warehouse.ledgers.equipment)
        stripLedgerEntries(worker.warehouse.ledgers.output)
    end
    return worker
end

local function stripWarehousePacket(warehouse)
    if type(warehouse) ~= "table" or type(warehouse.ledgers) ~= "table" then
        return warehouse
    end

    stripLedgerEntries(warehouse.ledgers.provisions)
    stripLedgerEntries(warehouse.ledgers.equipment)
    stripLedgerEntries(warehouse.ledgers.output)
    return warehouse
end

function Internal.syncWorkerList(player, knownVersion)
    local owner = Config.GetOwnerUsername(player)
    local workers = Registry.GetWorkerSummariesForOwner and Registry.GetWorkerSummariesForOwner(owner) or {}
    local version = Shared.getWorkerListVersion(owner)
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncPlayerWorkers", {
            version = version,
            unchanged = true
        })
        return
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncPlayerWorkers", {
        version = version,
        workers = workers
    })
end

function Internal.syncWorkerDetail(player, workerID, knownVersion, includeWorkerLedgers, includeWarehouseLedgers, workerLedgerMask, warehouseLedgerMask)
    local owner = Config.GetOwnerUsername(player)
    local normalizedWorkerMask = Shared.normalizeWorkerLedgerMask(includeWorkerLedgers, workerLedgerMask)
    local normalizedWarehouseMask = Shared.normalizeWarehouseLedgerMask(includeWarehouseLedgers, warehouseLedgerMask)
    local worker = Registry.GetWorkerDetailsForOwner(
        owner,
        workerID,
        normalizedWarehouseMask,
        normalizedWorkerMask or (includeWorkerLedgers ~= false)
    )
    stripWorkerPacket(worker)
    local version = Shared.buildWorkerDetailVersion(worker, workerID, normalizedWorkerMask or (includeWorkerLedgers == true), normalizedWorkerMask, normalizedWarehouseMask)
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWorkerDetails", {
            workerID = workerID,
            version = version,
            includeWorkerLedgers = normalizedWorkerMask ~= nil or includeWorkerLedgers == true,
            includeWarehouseLedgers = normalizedWarehouseMask ~= nil or includeWarehouseLedgers == true,
            workerLedgerMask = normalizedWorkerMask,
            warehouseLedgerMask = normalizedWarehouseMask,
            unchanged = true
        })
        return
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWorkerDetails", {
        workerID = workerID,
        version = version,
        includeWorkerLedgers = normalizedWorkerMask ~= nil or includeWorkerLedgers == true,
        includeWarehouseLedgers = normalizedWarehouseMask ~= nil or includeWarehouseLedgers == true,
        workerLedgerMask = normalizedWorkerMask,
        warehouseLedgerMask = normalizedWarehouseMask,
        worker = worker
    })
end

function Internal.syncWarehouse(player, knownVersion, includeLedgers, ledgerMask)
    local owner = Config.GetOwnerUsername(player)
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    local normalizedMask = Shared.normalizeWarehouseLedgerMask(includeLedgers, ledgerMask)
    local warehouse = Warehouse and Warehouse.GetClientSnapshot and Warehouse.GetClientSnapshot(owner, normalizedMask ~= nil, normalizedMask) or nil
    stripWarehousePacket(warehouse)
    local version = Shared.buildWarehouseVersion(warehouse, owner, normalizedMask ~= nil, normalizedMask)
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWarehouse", {
            version = version,
            includeLedgers = normalizedMask ~= nil,
            ledgerMask = normalizedMask,
            unchanged = true
        })
        return
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWarehouse", {
        version = version,
        includeLedgers = normalizedMask ~= nil,
        ledgerMask = normalizedMask,
        warehouse = warehouse
    })
end

function Internal.syncResearchSnapshot(player, knownVersion)
    local owner = Config.GetOwnerUsername(player)
    local researchApi = DC_Colony and DC_Colony.Research or nil
    local snapshot = researchApi and researchApi.GetClientSnapshot and researchApi.GetClientSnapshot(owner) or nil
    local version = Shared.buildVersionToken(snapshot or { ownerUsername = owner, missing = true })
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncResearchSnapshot", {
            version = version,
            unchanged = true
        })
        return
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncResearchSnapshot", {
        version = version,
        snapshot = snapshot
    })
end

function Internal.syncResources(player, knownVersion)
    local owner = Config.GetOwnerUsername(player)
    local resourcesApi = DC_Colony and DC_Colony.Resources or nil
    local snapshot = resourcesApi and resourcesApi.GetClientSnapshot and resourcesApi.GetClientSnapshot(owner) or nil
    local version = Shared.buildVersionToken(snapshot or { ownerUsername = owner, missing = true })
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncResources", {
            version = version,
            unchanged = true
        })
        return
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncResources", {
        version = version,
        snapshot = snapshot
    })
end

function Internal.syncRecruitAttemptResult(player, result)
    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncRecruitAttemptResult", result or {})
end

function Internal.syncOwnedFactionStatus(player)
    if not DynamicTrading_Factions or not DynamicTrading_Factions.GetOwnedFactionStatus then
        return
    end

    local owner = Config.GetOwnerUsername(player)
    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncOwnedFactionStatus", {
        status = DynamicTrading_Factions.GetOwnedFactionStatus(owner)
    })
end

return Shared
