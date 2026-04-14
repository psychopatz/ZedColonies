require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/ColonySim/DC_Colony_Sim"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DT/Common/Faction/TradingSys/DynamicTrading_Factions"

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

local function isScriptItem(fullType)
    if not fullType or fullType == "" or not getScriptManager then
        return false
    end
    local scriptItem = getScriptManager():getItem(fullType)
    return scriptItem ~= nil
end

local function isDebugEquipmentFullType(Config, fullType, requirementKey)
    if not Config or not fullType or fullType == "" then
        return false
    end

    if requirementKey and requirementKey ~= ""
        and Config.ItemMatchesEquipmentRequirement
        and Config.ItemMatchesEquipmentRequirement(fullType, requirementKey) then
        return true
    end

    if Config.IsColonyToolFullType and Config.IsColonyToolFullType(fullType) then
        return true
    end

    return false
end

Network.Handlers.DebugGiveEquipmentItem = function(player, args)
    if not player then
        return
    end

    if not canUseDebugRecruit(player) then
        if Internal.syncNotice then
            Internal.syncNotice(player, "Debug item spawning is unavailable for this player.", "error", true)
        end
        return
    end

    args = args or {}
    local Config = getConfig()
    local fullType = tostring(args.fullType or "")
    local requirementKey = tostring(args.requirementKey or "")
    local count = math.max(1, math.min(50, math.floor(tonumber(args.count) or 1)))

    if fullType == "" then
        if Internal.syncNotice then
            Internal.syncNotice(player, "No debug equipment item was selected.", "error", true)
        end
        return
    end

    if not isScriptItem(fullType) then
        if Internal.syncNotice then
            Internal.syncNotice(player, "Debug equipment item does not exist: " .. fullType, "error", true)
        end
        return
    end

    if not isDebugEquipmentFullType(Config, fullType, requirementKey) then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That item is not registered as colony equipment: " .. fullType, "error", true)
        end
        return
    end

    local inventory = player:getInventory()
    if not inventory then
        if Internal.syncNotice then
            Internal.syncNotice(player, "No player inventory found.", "error", true)
        end
        return
    end

    if Internal.addInventoryItem then
        Internal.addInventoryItem(inventory, fullType, count)
    else
        inventory:AddItems(fullType, count)
    end

    if Internal.syncNotice then
        local displayName = fullType
        local scriptItem = getScriptManager and getScriptManager():getItem(fullType) or nil
        if scriptItem and scriptItem.getDisplayName then
            displayName = scriptItem:getDisplayName()
        end
        Internal.syncNotice(
            player,
            "Debug added " .. tostring(count) .. " " .. tostring(displayName) .. ".",
            "info",
            false
        )
    end
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

    if Config and Config.IsRecruitableArchetype and not Config.IsRecruitableArchetype(args.archetypeID or args.profession) then
        if Internal.syncRecruitAttemptResult then
            Internal.syncRecruitAttemptResult(player, {
                success = false,
                sourceNPCID = sourceNPCID,
                reasonCode = "non_recruitable",
                message = "That kind of trader won't join a colony labour roster."
            })
        end
        return
    end

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
