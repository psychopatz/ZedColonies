local System = DC_System
local Internal = System.Internal

local function getReputationAPI()
    if DT_Reputation and DT_Reputation.GetEffectiveRep then
        return DT_Reputation
    end
    if DC_Reputation and DC_Reputation.GetEffectiveRep then
        return DC_Reputation
    end
    return nil
end

function System.RecruitFromConversation(ui)
    local args = System.BuildRecruitArgs(ui)
    if not args then
        return false, "I can't add this NPC to labour from the current conversation."
    end

    if not System.SendCommand("DebugRecruitWorker", args) then
        return false, "The labour recruit command could not be sent."
    end

    return true, ""
end

function System.AttemptRecruitFromConversation(ui)
    local args = System.BuildRecruitArgs(ui)
    if not args then
        return false, "I can't work out who you're trying to recruit right now."
    end

    local config = Internal.GetConfig()
    if config and config.IsRecruitableArchetype and not config.IsRecruitableArchetype(args.archetypeID) then
        return false, "That kind of trader won't join a colony labour roster."
    end

    local reputationAPI = getReputationAPI()
    if reputationAPI and reputationAPI.Save then
        reputationAPI.Save()
    end

    if not System.SendCommand("AttemptRecruitWorker", args) then
        return false, "The recruit request couldn't be sent."
    end

    return true, nil
end

local function buildRecruitOption(ui)
    if not ui or not ui.interactionObj then
        return nil
    end

    local config = Internal.GetConfig()
    local recruitArgs = System.BuildRecruitArgs(ui)
    if not recruitArgs then
        return nil
    end

    if config and config.IsRecruitableArchetype and not config.IsRecruitableArchetype(recruitArgs.archetypeID) then
        return nil
    end

    local reputation = System.GetConversationEffectiveReputation(ui)
    local requiredReputation = tonumber(config.RECRUIT_REQUIRED_REPUTATION or 80) or 80
    local chance = config.GetRecruitChanceForReputation and config.GetRecruitChanceForReputation(reputation)
        or math.max(0, math.min(100, tonumber(config.RECRUIT_DAILY_CHANCE) or 0))

    local sourceNPCID = System.GetConversationSourceNPCID(ui)
    local cached = sourceNPCID and System.recruitResultCache[tostring(sourceNPCID)] or nil
    local currentDay = System.GetCurrentDay()
    if cached and cached.nextAttemptDay and currentDay >= tonumber(cached.nextAttemptDay) then
        cached = nil
        System.recruitResultCache[tostring(sourceNPCID)] = nil
    end

    local buttonText = "Recruit To Colony (" .. tostring(chance) .. "% chance)"
    local promptMessage = "Would you consider joining my colony?"
    if cached and cached.alreadyRecruited then
        buttonText = "Already In Colony Roster"
        promptMessage = "Let's talk about your place in the colony."
    elseif cached and cached.currentDay and tonumber(cached.currentDay) == currentDay then
        buttonText = "Recruit To Colony (Asked Today)"
        promptMessage = "I wanted to ask again about joining my colony."
    elseif reputation < requiredReputation then
        buttonText = "Recruit To Colony (Need " .. tostring(requiredReputation) .. " Rep)"
    end

    return {
        text = buttonText,
        message = promptMessage,
        onSelect = function(conversationUI)
            if cached and cached.alreadyRecruited then
                System.OpenWindow()
                conversationUI:updateOptions(conversationUI.baseOptions or {})
                return
            end

            if reputation < requiredReputation then
                conversationUI:speak(cached and cached.message or "We aren't close enough for that yet. Earn more trust first.")
                conversationUI:updateOptions(conversationUI.baseOptions or {})
                return
            end

            local ok, msg = System.AttemptRecruitFromConversation(conversationUI)
            if not ok and msg and msg ~= "" then
                conversationUI:speak(msg)
                conversationUI:updateOptions(conversationUI.baseOptions or {})
                return
            end

            if msg and msg ~= "" then
                conversationUI:speak(msg)
            end
        end
    }
end

Internal.BuildRecruitOption = buildRecruitOption
