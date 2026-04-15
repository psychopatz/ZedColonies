require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/DC_Colony_Sites"
require "DC/Common/Colony/ColonySim/DC_Colony_Sim"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DT/Common/Faction/TradingSys/DynamicTrading_Factions"
require "DT/Common/Faction/TradingSys/RosterLogic/DT_RosterLogic"
require "DT/Common/Faction/TradingSys/DynamicTrading_Stock"

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

local function getRecruitDepartureTarget(args, sourceSoul)
    args = type(args) == "table" and args or {}
    sourceSoul = type(sourceSoul) == "table" and sourceSoul or {}

    local x = tonumber(args.baseX)
        or tonumber(args.homeX)
        or tonumber(sourceSoul.homeX)
        or tonumber(sourceSoul.homeCoords and sourceSoul.homeCoords.x)
        or tonumber(args.x)
    local y = tonumber(args.baseY)
        or tonumber(args.homeY)
        or tonumber(sourceSoul.homeY)
        or tonumber(sourceSoul.homeCoords and sourceSoul.homeCoords.y)
        or tonumber(args.y)
    local z = tonumber(args.baseZ)
        or tonumber(args.homeZ)
        or tonumber(sourceSoul.homeZ)
        or tonumber(sourceSoul.homeCoords and sourceSoul.homeCoords.z)
        or tonumber(args.z)
        or 0

    if not x or not y then
        return nil, nil, nil
    end

    return math.floor(x), math.floor(y), math.floor(z)
end

local function getAdjustedRecruitDepartureTarget(targetX, targetY, targetZ, zombie, sourceSoul)
    if not zombie or not targetX or not targetY then
        return targetX, targetY, targetZ
    end

    local zx = zombie:getX()
    local zy = zombie:getY()
    local zz = zombie:getZ()
    local dx = targetX - zx
    local dy = targetY - zy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 3 then
        return targetX, targetY, targetZ
    end

    local soulHomeX = tonumber(sourceSoul and sourceSoul.homeCoords and sourceSoul.homeCoords.x)
        or tonumber(sourceSoul and sourceSoul.homeX)
    local soulHomeY = tonumber(sourceSoul and sourceSoul.homeCoords and sourceSoul.homeCoords.y)
        or tonumber(sourceSoul and sourceSoul.homeY)
    local soulHomeZ = tonumber(sourceSoul and sourceSoul.homeCoords and sourceSoul.homeCoords.z)
        or tonumber(sourceSoul and sourceSoul.homeZ)
        or targetZ
    if soulHomeX and soulHomeY then
        local homeDx = soulHomeX - zx
        local homeDy = soulHomeY - zy
        local homeDist = math.sqrt(homeDx * homeDx + homeDy * homeDy)
        if homeDist > 3 then
            return math.floor(soulHomeX), math.floor(soulHomeY), math.floor(soulHomeZ or 0)
        end
    end

    local nearestPlayer = nil
    local nearestDist = nil
    local activePlayers = DTNPCManager and DTNPCManager.GetActivePlayers and DTNPCManager.GetActivePlayers() or {}
    for _, player in ipairs(activePlayers) do
        if player and math.abs((player:getZ() or 0) - zz) <= 1 then
            local pdx = zx - player:getX()
            local pdy = zy - player:getY()
            local playerDist = math.sqrt(pdx * pdx + pdy * pdy)
            if not nearestDist or playerDist < nearestDist then
                nearestDist = playerDist
                nearestPlayer = player
            end
        end
    end

    if nearestPlayer then
        local awayX = zx - nearestPlayer:getX()
        local awayY = zy - nearestPlayer:getY()
        local awayLen = math.sqrt(awayX * awayX + awayY * awayY)
        if awayLen > 0.001 then
            local travel = 12
            return math.floor(zx + ((awayX / awayLen) * travel)),
                math.floor(zy + ((awayY / awayLen) * travel)),
                math.floor(zz or targetZ or 0)
        end
    end

    return math.floor(zx + 12), math.floor(zy), math.floor(zz or targetZ or 0)
end

local function getRecruitGoodbyeText(args, sourceSoul)
    local lines = {
        "I'll head to your base now.",
        "I'll meet you back at base.",
        "I'll get moving. See you at the base.",
        "Alright. I'll make my way there.",
    }
    local seed = tonumber(args and args.identitySeed)
        or tonumber(sourceSoul and sourceSoul.identitySeed)
        or 1
    local index = (math.abs(math.floor(seed)) % #lines) + 1
    return lines[index]
end

local function copyRecruitArgs(args)
    local copy = {}
    if type(args) ~= "table" then
        return copy
    end

    for key, value in pairs(args) do
        copy[key] = value
    end

    return copy
end

local function markRecruitmentDeparture(uuid, args, sourceSoul, owner, pendingResult)
    if not uuid or not DTNPCManager or not DTNPCManager.TryStartLiveDeparture then
        return false
    end

    local targetX, targetY, targetZ = getRecruitDepartureTarget(args, sourceSoul)
    if not targetX or not targetY then
        return false
    end

    local npcData = (DTNPCManager.Data and DTNPCManager.Data[uuid]) or sourceSoul
    if not npcData then
        return false
    end

    npcData.colonyRecruitmentDeparture = true
    npcData.colonyRecruitmentOwner = owner and tostring(owner) or nil
    npcData.colonyRecruitmentOwnerOnlineID = pendingResult and pendingResult.ownerOnlineID or nil
    npcData.colonyRecruitmentSourceFactionID = npcData.factionID or (args and args.factionID) or nil
    npcData.colonyRecruitmentRemoveSource = true
    npcData.colonyRecruitmentPending = true
    npcData.colonyRecruitmentPendingArgs = copyRecruitArgs(args)
    npcData.colonyRecruitmentPendingResult = copyRecruitArgs(pendingResult)

    local walkHours = SandboxVars
        and SandboxVars.DynamicTrading
        and SandboxVars.DynamicTrading.NPCTradingWalkHours
        or 1.0

    local zombie = DTNPCServerCore and DTNPCServerCore.FindZombieByUUID and DTNPCServerCore.FindZombieByUUID(uuid) or nil
    targetX, targetY, targetZ = getAdjustedRecruitDepartureTarget(targetX, targetY, targetZ, zombie, sourceSoul)

    local recruitReturnStatus = DTNPCManager
        and DTNPCManager.COLONY_RECRUITMENT_RETURN_STATUS
        or "ColonyRecruitment"

    if DTNPCManager.TryStartLiveDeparture(uuid, recruitReturnStatus, walkHours, targetX, targetY, targetZ) == true then
        if zombie and (not DTNPCProtect or not DTNPCProtect.PushCompanionNotice) then
            pcall(require, "DT/V2/NPC/Sys/DTNPC_Protect")
        end
        if zombie and DTNPCProtect and DTNPCProtect.PushCompanionNotice then
            DTNPCProtect.PushCompanionNotice(zombie, npcData, getRecruitGoodbyeText(args, sourceSoul), "positive")
        end
        return true
    end

    npcData.colonyRecruitmentDeparture = nil
    npcData.colonyRecruitmentOwner = nil
    npcData.colonyRecruitmentOwnerOnlineID = nil
    npcData.colonyRecruitmentSourceFactionID = nil
    npcData.colonyRecruitmentRemoveSource = nil
    npcData.colonyRecruitmentPending = nil
    npcData.colonyRecruitmentPendingArgs = nil
    npcData.colonyRecruitmentPendingResult = nil
    return false
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

local function detachRecruitedSourceNPC(args, owner, pendingResult)
    local traderUUID = resolveRecruitSourceUUID(args)
    if not traderUUID then
        return nil, nil
    end

    local soul = getRecruitSourceSoul(traderUUID)
    local factionID = soul and soul.factionID or (args and args.factionID) or nil
    local removed = false

    if markRecruitmentDeparture(traderUUID, args, soul, owner, pendingResult) then
        return traderUUID, soul, true
    end

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

local function resolveRecruitSourceHealth(args, sourceSoul)
    local config = getConfig()
    local defaultMax = math.max(1, tonumber(config and config.DEFAULT_WORKER_MAX_HP) or 100)
    local combatHealth = sourceSoul and sourceSoul.combatHealth or nil

    local maxHp = tonumber(args and args.maxHp)
        or tonumber(args and args.healthMax)
        or tonumber(combatHealth and combatHealth.max)
        or tonumber(sourceSoul and sourceSoul.combatHealthMax)
        or nil
    local hp = tonumber(args and args.hp)
        or tonumber(args and args.health)
        or tonumber(combatHealth and combatHealth.current)
        or tonumber(sourceSoul and sourceSoul.combatHealthCurrent)
        or nil

    if hp == nil then
        local fallbackHealth = tonumber(sourceSoul and sourceSoul.health)
        if fallbackHealth and fallbackHealth > 1 then
            hp = fallbackHealth
        end
    end

    if maxHp ~= nil then
        maxHp = math.max(1, math.floor(maxHp + 0.5))
    end
    if hp ~= nil then
        local clampMax = maxHp or defaultMax
        hp = math.max(0, math.min(clampMax, math.floor(hp + 0.5)))
    end

    return hp, maxHp
end

local function createWorkerFromRecruitArgs(owner, args, sourceSoul)
    local recruitUUID = resolveRecruitSourceUUID(args)
    sourceSoul = sourceSoul or getRecruitSourceSoul(recruitUUID)

    local Config = getConfig()
    local Registry = getRegistry()
    local archetypeID = Config.NormalizeArchetypeID(args.archetypeID or args.profession or (sourceSoul and sourceSoul.archetypeID))
    local resolvedSourceNPCID = args.sourceNPCID and tostring(args.sourceNPCID) or recruitUUID
    local hp, maxHp = resolveRecruitSourceHealth(args, sourceSoul)
    local isFemale = args.isFemale
    if isFemale == nil and sourceSoul and sourceSoul.isFemale ~= nil then
        isFemale = sourceSoul.isFemale
    end
    local worker = Registry.CreateWorker(owner, {
        jobType = args.jobType or Config.JobTypes.Unemployed or Config.GetDefaultJobForArchetype(archetypeID),
        profession = args.jobType or Config.JobTypes.Unemployed or Config.GetDefaultJobForArchetype(archetypeID),
        archetypeID = archetypeID,
        name = args.name or (sourceSoul and sourceSoul.name),
        isFemale = isFemale,
        identitySeed = args.identitySeed or (sourceSoul and sourceSoul.identitySeed),
        visualID = args.visualID or (sourceSoul and sourceSoul.visualID),
        homeX = args.homeX or args.spawnX or args.x,
        homeY = args.homeY or args.spawnY or args.y,
        homeZ = args.homeZ or args.spawnZ or args.z or 0,
        presenceState = Config.PresenceStates.Home,
        state = Config.States.Idle,
        jobEnabled = false,
        hp = hp,
        maxHp = maxHp,
        sourceNPCID = resolvedSourceNPCID and tostring(resolvedSourceNPCID) or nil,
        sourceNPCType = args.sourceNPCType or "ConversationUI",
        sourceLoadout = args.loadout or (sourceSoul and (sourceSoul.loadout or sourceSoul)),
        loadout = args.loadout or (sourceSoul and (sourceSoul.loadout or sourceSoul)),
    })

    if args.x and args.y then
        Sites.AssignSiteForWorker(worker, args.x, args.y, args.z or 0, args.radius)
    end

    return worker
end

Internal.createWorkerFromRecruitArgs = createWorkerFromRecruitArgs

local function getOwnerPlayers(owner, preferredOnlineID)
    local Config = getConfig()
    local ownerText = owner and tostring(owner) or nil
    local players = {}
    local seen = {}
    local preferredID = tonumber(preferredOnlineID)

    if not Config or not ownerText then
        return players
    end

    local function tryAdd(player)
        if not player then
            return
        end
        local username = Config.GetOwnerUsername(player)
        local playerOnlineID = player.getOnlineID and tonumber(player:getOnlineID()) or nil
        if preferredID and playerOnlineID and playerOnlineID == preferredID then
            local key = tostring(playerOnlineID)
            if seen[key] then
                return
            end
            seen[key] = true
            players[#players + 1] = player
            return
        end

        if tostring(username or "") ~= ownerText then
            return
        end
        local key = playerOnlineID and tostring(playerOnlineID) or tostring(player)
        if seen[key] then
            return
        end
        seen[key] = true
        players[#players + 1] = player
    end

    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            tryAdd(onlinePlayers:get(i))
        end
    end

    if getSpecificPlayer then
        tryAdd(getSpecificPlayer(0))
    end
    tryAdd(getPlayer and getPlayer() or nil)
    if #players == 0 and Config.GetPlayerObject then
        tryAdd(Config.GetPlayerObject())
    end
    return players
end

local function finishRecruitment(owner, args, sourceSoul, resultData, players)
    args = args or {}
    resultData = resultData or {}

    local Config = getConfig()
    local Registry = getRegistry()
    local Sim = getSim()
    local Presentation = getPresentation()
    if not Config or not Registry then
        return nil
    end

    local sourceNPCID = resultData.sourceNPCID
        or (args.sourceNPCID and tostring(args.sourceNPCID))
        or resolveRecruitSourceUUID(args)
    if not sourceNPCID then
        return nil
    end

    local recruitSourceUUID = resultData.recruitSourceUUID or resolveRecruitSourceUUID(args) or sourceNPCID
    local worker = Registry.FindWorkerBySourceID(owner, sourceNPCID)
    if not worker then
        worker = createWorkerFromRecruitArgs(owner, args, sourceSoul)
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
        Presentation.SyncWorker(worker, players or {})
    end

    DynamicTrading.Log(
        "DColony",
        "Recruit",
        "Success",
        "finishRecruitment owner=" .. tostring(owner)
            .. " sourceNPCID=" .. tostring(sourceNPCID)
            .. " workerID=" .. tostring(worker and worker.workerID)
            .. " players=" .. tostring(players and #players or 0)
            .. " completedAfterDeparture=" .. tostring(resultData.completedAfterDeparture == true)
    )

    local successMessage = nil
    if resultData.debugBypass then
        successMessage = resultData.completedAfterDeparture
            and "For testing, I made it to base and joined your labour roster."
            or "For testing, I'll join your labour roster."
    else
        successMessage = resultData.completedAfterDeparture
            and "I made it to base and joined your labour roster."
            or "Alright. You've earned it. I'll join your labour roster."
    end

    for _, player in ipairs(players or {}) do
        Internal.syncRecruitAttemptResult(player, {
            success = true,
            sourceNPCID = sourceNPCID,
            traderUUID = recruitSourceUUID,
            recruitedTraderUUID = recruitSourceUUID,
            workerID = worker.workerID,
            reasonCode = resultData.debugBypass and "debug_recruited" or "recruited",
            reputation = resultData.reputation,
            chance = resultData.chance,
            roll = resultData.roll,
            currentDay = resultData.currentDay,
            message = successMessage
        })
        Internal.syncWorkerDetail(player, worker.workerID)
        Internal.syncWorkerList(player)
        Internal.syncOwnedFactionStatus(player)
        syncRadarRoster(player)
    end

    return worker
end

Internal.completePendingV2Recruitment = function(uuid, npcData, reason)
    if not npcData or npcData.colonyRecruitmentPending ~= true then
        DynamicTrading.Log(
            "DColony",
            "Recruit",
            "Warn",
            "completePendingV2Recruitment skipped uuid=" .. tostring(uuid)
                .. " pending=" .. tostring(npcData and npcData.colonyRecruitmentPending == true)
        )
        return false
    end

    local owner = npcData.colonyRecruitmentOwner
    if not owner or owner == "" then
        DynamicTrading.Log(
            "DColony",
            "Recruit",
            "Warn",
            "completePendingV2Recruitment missing owner uuid=" .. tostring(uuid)
        )
        return false
    end

    local args = copyRecruitArgs(npcData.colonyRecruitmentPendingArgs)
    if not args.traderUUID and uuid then
        args.traderUUID = tostring(uuid)
    end
    if not args.sourceNPCID and uuid then
        args.sourceNPCID = tostring(uuid)
    end

    local resultData = copyRecruitArgs(npcData.colonyRecruitmentPendingResult)
    resultData.sourceNPCID = resultData.sourceNPCID or args.sourceNPCID or uuid
    resultData.recruitSourceUUID = resultData.recruitSourceUUID or args.traderUUID or uuid
    resultData.departureReason = reason
    resultData.completedAfterDeparture = true
    resultData.ownerOnlineID = resultData.ownerOnlineID or npcData.colonyRecruitmentOwnerOnlineID

    local ownerPlayers = getOwnerPlayers(owner, resultData.ownerOnlineID)
    DynamicTrading.Log(
        "DColony",
        "Recruit",
        "Info",
        "completePendingV2Recruitment uuid=" .. tostring(uuid)
            .. " owner=" .. tostring(owner)
            .. " ownerOnlineID=" .. tostring(resultData.ownerOnlineID)
            .. " players=" .. tostring(#ownerPlayers)
            .. " reason=" .. tostring(reason)
    )

    local worker = finishRecruitment(owner, args, npcData, resultData, ownerPlayers)
    if not worker then
        DynamicTrading.Log(
            "DColony",
            "Recruit",
            "Warn",
            "completePendingV2Recruitment failed to create worker uuid=" .. tostring(uuid)
                .. " owner=" .. tostring(owner)
        )
        return false
    end

    npcData.colonyRecruitmentPending = nil
    npcData.colonyRecruitmentPendingArgs = nil
    npcData.colonyRecruitmentPendingResult = nil
    npcData.colonyRecruitmentCompleted = true
    npcData.colonyRecruitmentOwnerOnlineID = nil
    DynamicTrading.Log(
        "DColony",
        "Recruit",
        "Success",
        "completePendingV2Recruitment finished uuid=" .. tostring(uuid)
            .. " workerID=" .. tostring(worker.workerID)
    )
    return true
end

local function isRecruitableRequest(args, sourceSoul)
    local Config = getConfig()
    if not Config or not Config.IsRecruitableArchetype then
        return true
    end

    local archetypeID = args and (args.archetypeID or args.profession) or nil
    if not archetypeID and sourceSoul then
        archetypeID = sourceSoul.archetypeID or sourceSoul.profession
    end

    return Config.IsRecruitableArchetype(archetypeID)
end

local function canBypassRecruitRestrictions(player)
    local accessLevel = nil
    if player and player.getAccessLevel then
        accessLevel = player:getAccessLevel()
    end
    local hasElevatedAccess = accessLevel and accessLevel ~= "" and accessLevel ~= "None"
    local isSinglePlayer = (not isClient or not isClient()) and not hasElevatedAccess

    if isSinglePlayer then
        return isDebugEnabled and isDebugEnabled() == true
    end

    if DynamicTrading and DynamicTrading.Debug then
        return true
    end

    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    return hasElevatedAccess == true
end

Network.Handlers.AttemptRecruitWorker = function(player, args)
    if not player then return end
    args = args or {}

    local Config = getConfig()
    local Registry = getRegistry()
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

    local debugBypassRequested = args.debugRecruitBypass == true
    local debugBypass = debugBypassRequested and canBypassRecruitRestrictions(player)
    if debugBypassRequested and not debugBypass then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            sourceNPCID = sourceNPCID,
            reasonCode = "debug_unavailable",
            message = "Debug recruit is unavailable."
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
    local recruitSourceSoul = getRecruitSourceSoul(recruitSourceUUID)
    if recruitSourceSoul and recruitSourceSoul.colonyRecruitmentPending == true then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            pending = true,
            sourceNPCID = sourceNPCID,
            traderUUID = recruitSourceUUID or sourceNPCID,
            reasonCode = "departure_started",
            message = "I'm already heading to your base."
        })
        return
    end

    if not debugBypass and not isRecruitableRequest(args, recruitSourceSoul) then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            sourceNPCID = sourceNPCID,
            reasonCode = "non_recruitable",
            message = "That kind of trader won't join a colony labour roster."
        })
        return
    end

    local reputation = Internal.getEffectiveRecruitReputation(player, recruitSourceUUID or sourceNPCID, args.factionID) or 0
    if not debugBypass and reputation < Config.RECRUIT_REQUIRED_REPUTATION then
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
    local chance = 100
    local roll = 0
    local succeeded = true

    if not debugBypass then
        local attemptState = Registry.GetRecruitAttempt(owner, sourceNPCID)
        if attemptState and tonumber(attemptState.lastAttemptDay) == currentDay then
            local nagCount = (tonumber(attemptState.nagCount) or 0) + 1
            attemptState.nagCount = nagCount
            Registry.SetRecruitAttempt(owner, sourceNPCID, attemptState)
            if Registry and Registry.Save then
                Registry.Save()
            end

            local nagWarningRepeats = tonumber(Config.RECRUIT_NAG_WARNING_REPEATS) or 1
            if nagCount > nagWarningRepeats then
                local penalty = tonumber(Config.RECRUIT_NAG_REPUTATION_PENALTY) or 0
                if penalty ~= 0 and Internal.modifyRecruitReputation then
                    Internal.modifyRecruitReputation(player, recruitSourceUUID or sourceNPCID, args.factionID, penalty)
                end

                local updatedReputation = Internal.getEffectiveRecruitReputation(player, recruitSourceUUID or sourceNPCID, args.factionID)
                Internal.syncRecruitAttemptResult(player, {
                    success = false,
                    sourceNPCID = sourceNPCID,
                    traderUUID = recruitSourceUUID or sourceNPCID,
                    reasonCode = "nag_penalty",
                    reputation = updatedReputation,
                    currentDay = currentDay,
                    nextAttemptDay = currentDay + 1,
                    nagCount = nagCount,
                    penalty = penalty,
                    message = "I already answered you. Keep pushing and you'll lose my trust. Ask again tomorrow."
                })
                return
            end

            Internal.syncRecruitAttemptResult(player, {
                success = false,
                sourceNPCID = sourceNPCID,
                traderUUID = recruitSourceUUID or sourceNPCID,
                reasonCode = "cooldown",
                reputation = reputation,
                currentDay = currentDay,
                nextAttemptDay = currentDay + 1,
                nagCount = nagCount,
                message = "I've already given you my answer for today. Ask me again tomorrow."
            })
            return
        end

        chance = Config.GetRecruitChanceForReputation and Config.GetRecruitChanceForReputation(reputation)
            or math.max(0, math.min(100, tonumber(Config.RECRUIT_DAILY_CHANCE) or 0))
        roll = ZombRand(100)
        succeeded = roll < chance

        Registry.SetRecruitAttempt(owner, sourceNPCID, {
            lastAttemptDay = currentDay,
            lastRoll = roll,
            lastChance = chance,
            lastSuccess = succeeded,
            nagCount = 0
        })

        if not succeeded then
            Registry.Save()
            Internal.syncRecruitAttemptResult(player, {
                success = false,
                sourceNPCID = sourceNPCID,
                traderUUID = recruitSourceUUID or sourceNPCID,
                reasonCode = "rolled_failed",
                reputation = reputation,
                chance = chance,
                roll = roll,
                currentDay = currentDay,
                nextAttemptDay = currentDay + 1,
                message = "You've earned the right to ask, but not today. Give me until tomorrow and ask again."
            })
            return
        end
    end

    local resultData = {
        sourceNPCID = sourceNPCID,
        recruitSourceUUID = recruitSourceUUID or sourceNPCID,
        ownerOnlineID = player.getOnlineID and player:getOnlineID() or nil,
        debugBypass = debugBypass,
        reputation = reputation,
        chance = chance,
        roll = roll,
        currentDay = currentDay
    }

    local _, sourceSoul, departureStarted = detachRecruitedSourceNPC(args, owner, resultData)
    if departureStarted then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            pending = true,
            sourceNPCID = sourceNPCID,
            traderUUID = recruitSourceUUID or sourceNPCID,
            reasonCode = "departure_started",
            reputation = reputation,
            chance = chance,
            roll = roll,
            currentDay = currentDay,
            message = debugBypass
                and "For testing, I'll head to your base now."
                or "Alright. You've earned it. I'll head to your base now."
        })
        return
    end

    local worker = finishRecruitment(owner, args, sourceSoul, resultData, { player })
    if not worker then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            sourceNPCID = sourceNPCID,
            traderUUID = recruitSourceUUID or sourceNPCID,
            reasonCode = "recruit_failed",
            message = "I can't join your labour roster right now."
        })
    end
end

return Network
