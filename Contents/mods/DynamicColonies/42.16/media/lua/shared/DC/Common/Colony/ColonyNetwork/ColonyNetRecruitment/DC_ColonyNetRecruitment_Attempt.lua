DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Recruit = Network.Recruitment or {}

Network.Handlers = Network.Handlers or {}

function Recruit.canBypassRecruitRestrictions(player)
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
    if not player then
        return
    end
    args = args or {}

    local Config = Recruit.getConfig()
    local Registry = Recruit.getRegistry()
    local flavor = Recruit.FlavorText or {}
    local owner = Config.GetOwnerUsername(player)
    local sourceNPCID = args.sourceNPCID and tostring(args.sourceNPCID) or Recruit.resolveRecruitSourceUUID(args)
    if not sourceNPCID then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            reasonCode = "missing_target",
            message = tostring(flavor.missingTarget or "I can't sort out who you're trying to recruit right now.")
        })
        return
    end

    local debugBypassRequested = args.debugRecruitBypass == true
    local debugBypass = debugBypassRequested and Recruit.canBypassRecruitRestrictions(player)
    if debugBypassRequested and not debugBypass then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            sourceNPCID = sourceNPCID,
            reasonCode = "debug_unavailable",
            message = tostring(flavor.debugUnavailable or "Debug recruit is unavailable.")
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
            message = tostring(flavor.alreadyRecruited or "I'm already part of your labour roster.")
        })
        Internal.syncWorkerDetail(player, existingWorker.workerID)
        Internal.syncWorkerList(player)
        return
    end

    local recruitSourceUUID = Recruit.resolveRecruitSourceUUID(args)
    local recruitSourceSoul = Recruit.getRecruitSourceSoul(recruitSourceUUID)
    if recruitSourceSoul and recruitSourceSoul.colonyRecruitmentPending == true then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            pending = true,
            sourceNPCID = sourceNPCID,
            traderUUID = recruitSourceUUID or sourceNPCID,
            reasonCode = "departure_started",
            message = tostring(flavor.departureStarted or "I'm already heading to your base.")
        })
        return
    end

    if not debugBypass and not Recruit.isRecruitableRequest(args, recruitSourceSoul) then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            sourceNPCID = sourceNPCID,
            reasonCode = "non_recruitable",
            message = tostring(flavor.nonRecruitable or "That kind of trader won't join a colony labour roster.")
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
            message = tostring(flavor.lowReputation or "We aren't close enough for that yet. Earn more trust first.")
        })
        return
    end

    local currentDay = Recruit.getCurrentDay()
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
                    message = tostring(flavor.nagPenalty or "I already answered you. Keep pushing and you'll lose my trust. Ask again tomorrow.")
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
                message = tostring(flavor.cooldown or "I've already given you my answer for today. Ask me again tomorrow.")
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
                message = tostring(flavor.rolledFailed or "You've earned the right to ask, but not today. Give me until tomorrow and ask again.")
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

    local _, sourceSoul, departureStarted = Recruit.detachRecruitedSourceNPC(args, owner, resultData)
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
                and tostring(flavor.departureStartedTesting or "For testing, I'll head to your base now.")
                or tostring(flavor.departureStartedSuccess or "Alright. You've earned it. I'll head to your base now.")
        })
        return
    end

    local worker = Recruit.finishRecruitment(owner, args, sourceSoul, resultData, { player })
    if not worker then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            sourceNPCID = sourceNPCID,
            traderUUID = recruitSourceUUID or sourceNPCID,
            reasonCode = "recruit_failed",
            message = tostring(flavor.recruitFailed or "I can't join your labour roster right now.")
        })
    end
end

return Network