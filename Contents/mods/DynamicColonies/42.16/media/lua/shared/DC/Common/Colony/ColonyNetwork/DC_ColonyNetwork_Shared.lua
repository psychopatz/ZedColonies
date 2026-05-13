require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Network = DC_Colony.Network
local Internal = Network.Internal or {}

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}

if not Internal.sanitizeNetworkArgs then
    local function sanitizeNetworkKey(key)
        local keyType = type(key)
        if keyType == "string" or keyType == "number" then
            return key
        end
        if keyType == "boolean" then
            return tostring(key)
        end
        return nil
    end

    local function sanitizeNetworkValue(value, seen, depth)
        local valueType = type(value)
        if valueType == "nil" then
            return nil
        end
        if valueType == "string" or valueType == "boolean" then
            return value
        end
        if valueType == "number" then
            if value ~= value then
                return 0
            end
            return value
        end
        if valueType == "userdata" then
            return tostring(value)
        end
        if valueType ~= "table" then
            return nil
        end

        local safeDepth = math.floor(tonumber(depth) or 0)
        if safeDepth > 32 then
            return nil
        end

        seen = seen or {}
        if seen[value] then
            return nil
        end
        seen[value] = true

        local copy = {}
        for key, child in pairs(value) do
            local safeKey = sanitizeNetworkKey(key)
            local safeChild = sanitizeNetworkValue(child, seen, safeDepth + 1)
            if safeKey ~= nil and safeChild ~= nil then
                copy[safeKey] = safeChild
            end
        end

        seen[value] = nil
        return copy
    end

    function Internal.sanitizeNetworkArgs(args)
        local safeArgs = sanitizeNetworkValue(args or {}, nil, 0)
        if type(safeArgs) == "table" then
            return safeArgs
        end
        return {}
    end
end

local function buildVersionToken(value, seen)
    local valueType = type(value)
    if valueType ~= "table" then
        return tostring(valueType) .. ":" .. tostring(value)
    end

    seen = seen or {}
    if seen[value] then
        return "<cycle>"
    end
    seen[value] = true

    local keys = {}
    for key, _ in pairs(value) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    local parts = { "{" }
    for _, key in ipairs(keys) do
        parts[#parts + 1] = tostring(key)
        parts[#parts + 1] = "="
        parts[#parts + 1] = buildVersionToken(value[key], seen)
        parts[#parts + 1] = ";"
    end
    parts[#parts + 1] = "}"
    seen[value] = nil
    return table.concat(parts)
end

local function getWorkerListVersion(ownerUsername)
    local workersData = Registry.GetWorkersData and Registry.GetWorkersData(ownerUsername, false) or nil
    if workersData and workersData.version then
        return "workers:" .. tostring(workersData.version)
    end

    local colonyData = Registry.GetColonyData and Registry.GetColonyData(ownerUsername, false) or nil
    local versions = colonyData and colonyData.versions or nil
    return "workers:" .. tostring(versions and versions.workers or 1)
end

local function getWorkerLedgerCount(worker, key)
    local ledger = worker and worker[key] or nil
    return type(ledger) == "table" and #ledger or 0
end

local function buildWorkerDetailVersion(worker, workerID, includeWorkerLedgers)
    if not worker then
        return table.concat({
            "worker",
            tostring(workerID or "missing"),
            "missing",
            includeWorkerLedgers == true and "full" or "summary"
        }, ":")
    end

    local parts = {
        "worker",
        tostring(worker.workerID or workerID or ""),
        tostring(math.max(1, math.floor(tonumber(worker.detailVersion) or 1))),
        tostring(worker.state or ""),
        tostring(worker.presenceState or ""),
        tostring(worker.jobType or ""),
        tostring(worker.jobEnabled == true),
        tostring(worker.assignedSiteID or ""),
        tostring(worker.travelHoursRemaining or 0),
        tostring(worker.workProgress or 0),
        tostring(worker.moneyStored or 0),
        tostring(worker.toolState or ""),
    }

    if includeWorkerLedgers == true then
        parts[#parts + 1] = "full"
        parts[#parts + 1] = tostring(getWorkerLedgerCount(worker, "nutritionLedger"))
        parts[#parts + 1] = tostring(getWorkerLedgerCount(worker, "toolLedger"))
        parts[#parts + 1] = tostring(getWorkerLedgerCount(worker, "haulLedger"))
        parts[#parts + 1] = tostring(getWorkerLedgerCount(worker, "outputLedger"))
    else
        parts[#parts + 1] = "summary"
    end

    return table.concat(parts, ":")
end

local function buildWarehouseVersion(warehouse, ownerUsername, includeLedgers)
    if not warehouse then
        return table.concat({
            "warehouse",
            tostring(ownerUsername or "missing"),
            "missing",
            includeLedgers == true and "full" or "summary"
        }, ":")
    end

    local base = {
        "warehouse",
        tostring(warehouse.ownerUsername or ownerUsername or ""),
        tostring(math.max(1, math.floor(tonumber(warehouse.version) or 1))),
    }

    if includeLedgers == true then
        base[#base + 1] = tostring(math.max(1, math.floor(tonumber(warehouse.itemsVersion) or 1)))
        base[#base + 1] = "full"
    else
        base[#base + 1] = "summary"
    end

    return table.concat(base, ":")
end

if not Internal.sendResponse then
    function Internal.sendResponse(player, module, command, args)
        local safeArgs = Internal.sanitizeNetworkArgs and Internal.sanitizeNetworkArgs(args) or (args or {})
        if DynamicTrading and DynamicTrading.ServerHelpers and DynamicTrading.ServerHelpers.SendResponse then
            DynamicTrading.ServerHelpers.SendResponse(player, module, command, safeArgs)
            return
        end

        if isServer() then
            sendServerCommand(player, module, command, safeArgs)
        else
            triggerEvent("OnServerCommand", module, command, safeArgs)
        end
    end
end

function Internal.syncWorkerList(player, knownVersion)
    local owner = Config.GetOwnerUsername(player)
    local workers = Registry.GetWorkerSummariesForOwner(owner)
    local version = getWorkerListVersion(owner)
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
    local version = buildWorkerDetailVersion(worker, workerID, includeWorkerLedgers == true)
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
    local version = buildWarehouseVersion(warehouse, owner, includeLedgers == true)
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
    local version = buildVersionToken(snapshot or { ownerUsername = owner, missing = true })
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

function Network.HandleCommand(player, command, args)
    local handler = Network.Handlers[command]
    if handler then
        return handler(player, args or {})
    end
end

return Network
