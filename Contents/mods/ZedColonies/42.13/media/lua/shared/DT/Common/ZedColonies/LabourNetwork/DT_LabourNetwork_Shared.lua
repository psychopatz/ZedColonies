require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry"

DT_Labour = DT_Labour or {}
DT_Labour.Network = DT_Labour.Network or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry
local Network = DT_Labour.Network
local Internal = Network.Internal or {}

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}

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
    Internal.sendResponse(player, Config.COMMAND_MODULE, "LabourNotice", {
        message = tostring(message or ""),
        severity = severity or "info",
        popup = popup == true
    })
end

function Internal.syncWorkerList(player)
    local owner = Config.GetOwnerUsername(player)
    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncPlayerWorkers", {
        workers = Registry.GetWorkerSummariesForOwner(owner)
    })
end

function Internal.syncWorkerDetail(player, workerID, includeWarehouseLedgers)
    local owner = Config.GetOwnerUsername(player)
    local worker = Registry.GetWorkerDetailsForOwner(owner, workerID, includeWarehouseLedgers ~= false)
    Internal.sendResponse(player, Config.COMMAND_MODULE, "SyncWorkerDetails", {
        worker = worker
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
