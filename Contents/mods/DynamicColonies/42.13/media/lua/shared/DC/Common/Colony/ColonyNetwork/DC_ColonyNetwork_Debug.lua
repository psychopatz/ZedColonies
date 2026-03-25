require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/DC_Colony_Sim"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DC/Common/Faction/TradingSys/DynamicTrading_Factions"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}

local function getConfig()
    return DC_Colony and DC_Colony.Config or nil
end

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getSim()
    return DC_Colony and DC_Colony.Sim or nil
end

local function getPresentation()
    return DC_Colony and DC_Colony.Presentation or nil
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
    local sourceNPCID = args.sourceNPCID and tostring(args.sourceNPCID) or (args.traderUUID and tostring(args.traderUUID) or nil)
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
        if DynamicTrading_Factions and DynamicTrading_Factions.OnColonyWorkerCreated then
            DynamicTrading_Factions.OnColonyWorkerCreated(owner, worker)
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
