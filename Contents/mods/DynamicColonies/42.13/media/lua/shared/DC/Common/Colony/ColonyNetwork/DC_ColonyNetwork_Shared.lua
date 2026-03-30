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

function Internal.sendResponse(player, module, command, args)
    if DynamicTrading and DynamicTrading.ServerHelpers and DynamicTrading.ServerHelpers.SendResponse then
        DynamicTrading.ServerHelpers.SendResponse(player, module, command, args)
        return
    end

    if isServer() then
        sendServerCommand(player, module, command, args)
    else
        triggerEvent("OnServerCommand", module, command, args)
    end
end

function Internal.syncNotice(player, message, severity, popup)
    Internal.sendResponse(player, Config.COMMAND_MODULE, "ColonyNotice", {
        message = tostring(message or ""),
        severity = severity or "info",
        popup = popup == true
    })
end

function Internal.syncWorkerList(player, knownVersion)
    local owner = Config.GetOwnerUsername(player)
    local workers = Registry.GetWorkerSummariesForOwner(owner)
    local version = buildVersionToken(workers)
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
    local version = buildVersionToken(worker or { workerID = workerID, missing = true })
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWorkerDetails", {
            workerID = workerID,
            version = version,
            unchanged = true
        })
        return
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWorkerDetails", {
        workerID = workerID,
        version = version,
        worker = worker
    })
end

function Internal.syncWarehouse(player, knownVersion, includeLedgers)
    local owner = Config.GetOwnerUsername(player)
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    local warehouse = Warehouse and Warehouse.GetClientSnapshot and Warehouse.GetClientSnapshot(owner, includeLedgers == true) or nil
    local version = buildVersionToken(warehouse or { ownerUsername = owner, missing = true })
    if knownVersion and tostring(knownVersion) == version then
        Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWarehouse", {
            version = version,
            unchanged = true
        })
        return
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWarehouse", {
        version = version,
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
