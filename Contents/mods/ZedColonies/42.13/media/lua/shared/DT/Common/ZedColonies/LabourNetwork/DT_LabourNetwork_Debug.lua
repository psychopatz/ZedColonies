require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry"
require "DT/Common/ZedColonies/DT_Labour_Sim"
require "DT/Common/ZedColonies/DT_Labour_Presentation"
require "DT/Common/Faction/TradingSys/DynamicTrading_Factions"

DT_Labour = DT_Labour or {}
DT_Labour.Network = DT_Labour.Network or {}

local Network = DT_Labour.Network
local Internal = Network.Internal or {}

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}

local function getConfig()
    return DT_Labour and DT_Labour.Config or nil
end

local function getRegistry()
    return DT_Labour and DT_Labour.Registry or nil
end

local function getSim()
    return DT_Labour and DT_Labour.Sim or nil
end

local function getPresentation()
    return DT_Labour and DT_Labour.Presentation or nil
end

local function canUseDebugRecruit(player)
    if DynamicTrading and DynamicTrading.Debug then
        return true
    end

    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    if player and player.getAccessLevel then
        local accessLevel = player:getAccessLevel()
        if accessLevel and accessLevel ~= "" and accessLevel ~= "None" then
            return true
        end
    end

    return false
end

Network.Handlers.DebugRecruitWorker = function(player, args)
    if not player or not canUseDebugRecruit(player) then return end
    args = args or {}

    local Config = getConfig()
    local Registry = getRegistry()
    local Sim = getSim()
    local Presentation = getPresentation()
    local owner = Config.GetOwnerUsername(player)
    local sourceNPCID = args.sourceNPCID and tostring(args.sourceNPCID) or nil
    local worker = sourceNPCID and Registry.FindWorkerBySourceID(owner, sourceNPCID) or nil
    local recruitedTraderUUID = args.traderUUID or sourceNPCID or nil

    if not worker then
        if Internal.detachRecruitedSourceNPC then
            local resolvedUUID = Internal.detachRecruitedSourceNPC(args)
            if resolvedUUID then
                recruitedTraderUUID = resolvedUUID
            end
        end
        worker = Internal.createWorkerFromRecruitArgs(owner, args)
        if DynamicTrading_Factions and DynamicTrading_Factions.OnLabourWorkerCreated then
            DynamicTrading_Factions.OnLabourWorkerCreated(owner, worker)
        end
    end

    if Registry and Registry.Save then
        Registry.Save()
    end
    if Sim and Sim.ProcessWorker then
        Sim.ProcessWorker(worker, (Config.GetCurrentWorldHours and Config.GetCurrentWorldHours()) or Config.GetCurrentHour())
    end
    if Presentation and Presentation.SyncWorker then
        Presentation.SyncWorker(worker, { player })
    end
    if Internal.syncRecruitAttemptResult then
        Internal.syncRecruitAttemptResult(player, {
            success = true,
            sourceNPCID = sourceNPCID,
            recruitedTraderUUID = recruitedTraderUUID and tostring(recruitedTraderUUID) or nil,
            workerID = worker.workerID,
            reasonCode = "recruited",
            message = "For testing, I'll join your labour roster."
        })
    end
    Internal.syncWorkerDetail(player, worker.workerID)
    Internal.syncWorkerList(player)
    if Internal.syncOwnedFactionStatus then
        Internal.syncOwnedFactionStatus(player)
    end
    if Internal.syncRadarRoster then
        Internal.syncRadarRoster(player)
    end
end

return Network
