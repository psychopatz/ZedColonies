DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Shared = Internal.ColonyNetShared or {}
local Config = Shared.Config or {}
local Registry = Shared.Registry or {}

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

function Internal.syncWorkerDetail(player, workerID, knownVersion, includeWorkerLedgers)
    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerDetailsForOwner(
        owner,
        workerID,
        false,
        includeWorkerLedgers ~= false
    )
    local version = Shared.buildWorkerDetailVersion(worker, workerID, includeWorkerLedgers == true)
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWorkerDetails", {
            workerID = workerID,
            version = version,
            includeWorkerLedgers = includeWorkerLedgers == true,
            unchanged = true
        })
        return
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWorkerDetails", {
        workerID = workerID,
        version = version,
        includeWorkerLedgers = includeWorkerLedgers == true,
        worker = worker
    })
end

function Internal.syncWarehouse(player, knownVersion, includeLedgers)
    local owner = Config.GetOwnerUsername(player)
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    local warehouse = Warehouse and Warehouse.GetClientSnapshot and Warehouse.GetClientSnapshot(owner, includeLedgers == true) or nil
    local version = Shared.buildWarehouseVersion(warehouse, owner, includeLedgers == true)
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWarehouse", {
            version = version,
            includeLedgers = includeLedgers == true,
            unchanged = true
        })
        return
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWarehouse", {
        version = version,
        includeLedgers = includeLedgers == true,
        warehouse = warehouse
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