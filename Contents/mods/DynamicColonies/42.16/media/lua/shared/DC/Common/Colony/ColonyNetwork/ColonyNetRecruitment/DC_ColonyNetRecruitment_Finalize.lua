DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Recruit = Network.Recruitment or {}

function Recruit.createWorkerFromRecruitArgs(owner, args, sourceSoul)
    local recruitUUID = Recruit.resolveRecruitSourceUUID(args)
    sourceSoul = sourceSoul or Recruit.getRecruitSourceSoul(recruitUUID)

    local Config = Recruit.getConfig()
    local Registry = Recruit.getRegistry()
    local Sites = Recruit.Sites
    local archetypeID = Config.NormalizeArchetypeID(args.archetypeID or args.profession or (sourceSoul and sourceSoul.archetypeID))
    local resolvedSourceNPCID = args.sourceNPCID and tostring(args.sourceNPCID) or recruitUUID
    local hp, maxHp = Recruit.resolveRecruitSourceHealth(args, sourceSoul)
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

function Recruit.getOwnerPlayers(owner, preferredOnlineID)
    local Config = Recruit.getConfig()
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

function Recruit.finishRecruitment(owner, args, sourceSoul, resultData, players)
    args = args or {}
    resultData = resultData or {}

    local Config = Recruit.getConfig()
    local Registry = Recruit.getRegistry()
    local Sim = Recruit.getSim()
    local Presentation = Recruit.getPresentation()
    local flavor = Recruit.FlavorText or {}
    if not Config or not Registry then
        return nil
    end

    local sourceNPCID = resultData.sourceNPCID
        or (args.sourceNPCID and tostring(args.sourceNPCID))
        or Recruit.resolveRecruitSourceUUID(args)
    if not sourceNPCID then
        return nil
    end

    local recruitSourceUUID = resultData.recruitSourceUUID or Recruit.resolveRecruitSourceUUID(args) or sourceNPCID
    local worker = Registry.FindWorkerBySourceID(owner, sourceNPCID)
    if not worker then
        worker = Recruit.createWorkerFromRecruitArgs(owner, args, sourceSoul)
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
            and tostring(flavor.successTestingArrived or "For testing, I made it to base and joined your labour roster.")
            or tostring(flavor.successTestingImmediate or "For testing, I'll join your labour roster.")
    else
        successMessage = resultData.completedAfterDeparture
            and tostring(flavor.successArrived or "I made it to base and joined your labour roster.")
            or tostring(flavor.successImmediate or "Alright. You've earned it. I'll join your labour roster.")
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
        Recruit.syncRadarRoster(player)
    end

    return worker
end

Internal.createWorkerFromRecruitArgs = Recruit.createWorkerFromRecruitArgs

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

    local args = Recruit.copyRecruitArgs(npcData.colonyRecruitmentPendingArgs)
    if not args.traderUUID and uuid then
        args.traderUUID = tostring(uuid)
    end
    if not args.sourceNPCID and uuid then
        args.sourceNPCID = tostring(uuid)
    end

    local resultData = Recruit.copyRecruitArgs(npcData.colonyRecruitmentPendingResult)
    resultData.sourceNPCID = resultData.sourceNPCID or args.sourceNPCID or uuid
    resultData.recruitSourceUUID = resultData.recruitSourceUUID or args.traderUUID or uuid
    resultData.departureReason = reason
    resultData.completedAfterDeparture = true
    resultData.ownerOnlineID = resultData.ownerOnlineID or npcData.colonyRecruitmentOwnerOnlineID

    local ownerPlayers = Recruit.getOwnerPlayers(owner, resultData.ownerOnlineID)
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

    local worker = Recruit.finishRecruitment(owner, args, npcData, resultData, ownerPlayers)
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

return Recruit