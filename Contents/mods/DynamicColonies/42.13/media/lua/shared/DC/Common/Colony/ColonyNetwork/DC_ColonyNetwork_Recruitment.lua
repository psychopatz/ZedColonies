require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/DC_Colony_Sites"
require "DC/Common/Colony/DC_Colony_Sim"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DC/Common/Faction/TradingSys/DynamicTrading_Factions"
require "DC/Common/Faction/TradingSys/RosterLogic/DC_RosterLogic"
require "DC/Common/Faction/TradingSys/DynamicTrading_Stock"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Sites = DC_Colony.Sites
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

local function getCurrentDay()
    local Config = getConfig()
    if not Config then
        return 0
    end

    return math.floor((Config.GetCurrentHour() or 0) / Config.HOURS_PER_DAY)
end

local function syncRadarRoster(player)
    if not player or not Internal.sendResponse then
        return
    end

    local rosterData = ModData.get("DynamicTrading_Roster") or {}
    local factionData = ModData.get("DynamicTrading_Factions") or {}
    local minimalSouls = {}

    if rosterData.Souls then
        for uuid, soul in pairs(rosterData.Souls) do
            if soul.status == "Trading" then
                minimalSouls[uuid] = soul
            end
        end
    end

    Internal.sendResponse(player, "DynamicTrading_V2", "SyncRoster", {
        roster = {
            FactionMembers = rosterData.FactionMembers,
            Souls = minimalSouls,
            Traders = rosterData.Traders
        },
        factions = factionData
    })
end
Internal.syncRadarRoster = syncRadarRoster

local function normalizeRecruitID(value)
    if value == nil then
        return nil
    end

    local text = tostring(value)
    if text == "" then
        return nil
    end

    return text
end

local function getRecruitSourceSoul(uuid)
    if not uuid or not DynamicTrading_Roster then
        return nil
    end

    if DynamicTrading_Roster.GetSoul then
        local soul = DynamicTrading_Roster.GetSoul(uuid)
        if soul then
            return soul
        end
    end

    if DynamicTrading_Roster.GetSoulRegistry then
        return DynamicTrading_Roster.GetSoulRegistry(uuid)
    end

    return nil
end

local function resolveRecruitSourceUUID(args)
    if type(args) ~= "table" then
        return nil
    end

    local traderUUID = normalizeRecruitID(args.traderUUID)
    local sourceNPCID = normalizeRecruitID(args.sourceNPCID)

    if traderUUID and getRecruitSourceSoul(traderUUID) then
        return traderUUID
    end
    if sourceNPCID and getRecruitSourceSoul(sourceNPCID) then
        return sourceNPCID
    end

    return traderUUID or sourceNPCID
end

local function detachRecruitedSourceNPC(args)
    local traderUUID = resolveRecruitSourceUUID(args)
    if not traderUUID then
        return nil, nil
    end

    local soul = getRecruitSourceSoul(traderUUID)
    local factionID = soul and soul.factionID or (args and args.factionID) or nil
    local removed = false

    if DTNPCManager and DTNPCManager.SetNPCStatus then
        DTNPCManager.SetNPCStatus(traderUUID, "Away", nil, nil)
    end

    if DynamicTrading_Stock and DynamicTrading_Stock.ClearStock then
        DynamicTrading_Stock.ClearStock(traderUUID)
    end

    if DynamicTrading_Roster and DynamicTrading_Roster.RemoveSpecificSoul and DynamicTrading_Roster.RemoveSpecificSoul(traderUUID) then
        removed = true
    end

    if DynamicTrading_Roster and DynamicTrading_Roster.RemoveTrader and DynamicTrading_Roster.RemoveTrader(traderUUID) then
        removed = true
    end

    if removed and factionID and DynamicTrading_Factions and DynamicTrading_Factions.GetFaction then
        local faction = DynamicTrading_Factions.GetFaction(factionID)
        if faction and not faction.playerOwned then
            faction.memberCount = math.max(0, (tonumber(faction.memberCount) or 0) - 1)
        end
    end

    if removed then
        ModData.transmit("DynamicTrading_Roster")
        ModData.transmit("DynamicTrading_Stock")
        if factionID then
            ModData.transmit("DynamicTrading_Factions")
        end
    end

    return traderUUID, soul
end
Internal.detachRecruitedSourceNPC = detachRecruitedSourceNPC

local function createWorkerFromRecruitArgs(owner, args, sourceSoul)
    local recruitUUID = resolveRecruitSourceUUID(args)
    sourceSoul = sourceSoul or getRecruitSourceSoul(recruitUUID)

    local Config = getConfig()
    local Registry = getRegistry()
    local archetypeID = Config.NormalizeArchetypeID(args.archetypeID or args.profession or (sourceSoul and sourceSoul.archetypeID))
    local resolvedSourceNPCID = args.sourceNPCID and tostring(args.sourceNPCID) or recruitUUID
    local isFemale = args.isFemale
    if isFemale == nil and sourceSoul and sourceSoul.isFemale ~= nil then
        isFemale = sourceSoul.isFemale
    end
    local worker = Registry.CreateWorker(owner, {
        jobType = args.jobType or Config.GetDefaultJobForArchetype(archetypeID),
        profession = args.jobType or Config.GetDefaultJobForArchetype(archetypeID),
        archetypeID = archetypeID,
        name = args.name or (sourceSoul and sourceSoul.name),
        isFemale = isFemale,
        identitySeed = args.identitySeed or (sourceSoul and sourceSoul.identitySeed),
        homeX = args.homeX or args.spawnX or args.x,
        homeY = args.homeY or args.spawnY or args.y,
        homeZ = args.homeZ or args.spawnZ or args.z or 0,
        presenceState = Config.PresenceStates.Home,
        state = Config.States.Idle,
        jobEnabled = false,
        sourceNPCID = resolvedSourceNPCID and tostring(resolvedSourceNPCID) or nil,
        sourceNPCType = args.sourceNPCType or "ConversationUI"
    })

    if args.x and args.y then
        Sites.AssignSiteForWorker(worker, args.x, args.y, args.z or 0, args.radius)
    end

    return worker
end

Internal.createWorkerFromRecruitArgs = createWorkerFromRecruitArgs

Network.Handlers.AttemptRecruitWorker = function(player, args)
    if not player then return end
    args = args or {}

    local Config = getConfig()
    local Registry = getRegistry()
    local Sim = getSim()
    local Presentation = getPresentation()
    local owner = Config.GetOwnerUsername(player)
    local sourceNPCID = args.sourceNPCID and tostring(args.sourceNPCID) or resolveRecruitSourceUUID(args)
    if not sourceNPCID then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            reasonCode = "missing_target",
            message = "I can't sort out who you're trying to recruit right now."
        })
        return
    end

    local existingWorker = Registry.FindWorkerBySourceID(owner, sourceNPCID)
    if existingWorker then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            alreadyRecruited = true,
            sourceNPCID = sourceNPCID,
            workerID = existingWorker.workerID,
            reasonCode = "already_recruited",
            message = "I'm already part of your labour roster."
        })
        Internal.syncWorkerDetail(player, existingWorker.workerID)
        Internal.syncWorkerList(player)
        return
    end

    local recruitSourceUUID = resolveRecruitSourceUUID(args)
    local reputation = Internal.getEffectiveRecruitReputation(player, recruitSourceUUID or sourceNPCID, args.factionID)
    if reputation < Config.RECRUIT_REQUIRED_REPUTATION then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            sourceNPCID = sourceNPCID,
            reasonCode = "low_reputation",
            reputation = reputation,
            requiredReputation = Config.RECRUIT_REQUIRED_REPUTATION,
            message = "We aren't close enough for that yet. Earn more trust first."
        })
        return
    end

    local currentDay = getCurrentDay()
    local attemptState = Registry.GetRecruitAttempt(owner, sourceNPCID)
    if attemptState and tonumber(attemptState.lastAttemptDay) == currentDay then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            sourceNPCID = sourceNPCID,
            reasonCode = "cooldown",
            reputation = reputation,
            currentDay = currentDay,
            nextAttemptDay = currentDay + 1,
            message = "I've already given you my answer for today. Ask me again tomorrow."
        })
        return
    end

    local chance = math.max(0, math.min(100, tonumber(Config.RECRUIT_DAILY_CHANCE) or 0))
    local roll = ZombRand(100)
    local succeeded = roll < chance

    Registry.SetRecruitAttempt(owner, sourceNPCID, {
        lastAttemptDay = currentDay,
        lastRoll = roll,
        lastChance = chance,
        lastSuccess = succeeded
    })

    if not succeeded then
        Registry.Save()
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            sourceNPCID = sourceNPCID,
            reasonCode = "rolled_failed",
            reputation = reputation,
            chance = chance,
            roll = roll,
            currentDay = currentDay,
            nextAttemptDay = currentDay + 1,
            message = "Not today. Give me until tomorrow and ask again."
        })
        return
    end

    local _, sourceSoul = detachRecruitedSourceNPC(args)

    local worker = createWorkerFromRecruitArgs(owner, args, sourceSoul)
    if DynamicTrading_Factions and DynamicTrading_Factions.OnColonyWorkerCreated then
        DynamicTrading_Factions.OnColonyWorkerCreated(owner, worker)
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
    Internal.syncRecruitAttemptResult(player, {
        success = true,
        sourceNPCID = sourceNPCID,
        recruitedTraderUUID = recruitSourceUUID or sourceNPCID,
        workerID = worker.workerID,
        reasonCode = "recruited",
        reputation = reputation,
        chance = chance,
        roll = roll,
        currentDay = currentDay,
        message = "Alright. I'll join your labour roster."
    })
    Internal.syncWorkerDetail(player, worker.workerID)
    Internal.syncWorkerList(player)
    Internal.syncOwnedFactionStatus(player)
    syncRadarRoster(player)
end

return Network
