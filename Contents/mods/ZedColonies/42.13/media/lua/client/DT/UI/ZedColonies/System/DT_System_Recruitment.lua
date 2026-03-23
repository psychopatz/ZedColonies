local System = DT_System
local Internal = System.Internal

function System.RecruitFromConversation(ui)
    local args = System.BuildRecruitArgs(ui)
    if not args then
        return false, "I can't add this NPC to labour from the current conversation."
    end

    if not System.SendCommand("DebugRecruitWorker", args) then
        return false, "The labour recruit command could not be sent."
    end

    System.OpenWindow()
    return true, "For testing, I'll join your labour roster as a " .. tostring(args.archetypeID or "General") .. "."
end

function System.AttemptRecruitFromConversation(ui)
    local args = System.BuildRecruitArgs(ui)
    if not args then
        return false, "I can't work out who you're trying to recruit right now."
    end

    if DT_Reputation and DT_Reputation.Save then
        DT_Reputation.Save()
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
    local reputation = System.GetConversationEffectiveReputation(ui)
    if reputation < (config.RECRUIT_REQUIRED_REPUTATION or 100) then
        return nil
    end

    local sourceNPCID = System.GetConversationSourceNPCID(ui)
    local cached = sourceNPCID and System.recruitResultCache[tostring(sourceNPCID)] or nil
    local currentDay = System.GetCurrentDay()
    if cached and cached.nextAttemptDay and currentDay >= tonumber(cached.nextAttemptDay) then
        cached = nil
        System.recruitResultCache[tostring(sourceNPCID)] = nil
    end

    local buttonText = "Recruit To Labour (" .. tostring(config.RECRUIT_DAILY_CHANCE or 0) .. "%)"
    if cached and cached.alreadyRecruited then
        buttonText = "Already In Labour Roster"
    elseif cached and (cached.reasonCode == "cooldown" or cached.reasonCode == "rolled_failed") then
        buttonText = "Recruit To Labour (Try Tomorrow)"
    end

    return {
        text = buttonText,
        message = "",
        onSelect = function(conversationUI)
            if cached and cached.alreadyRecruited then
                System.OpenWindow()
                conversationUI:updateOptions(conversationUI.baseOptions or {})
                return
            end

            if cached and (cached.reasonCode == "cooldown" or cached.reasonCode == "rolled_failed") then
                conversationUI:speak(cached.message or "Ask me again tomorrow.")
                conversationUI:updateOptions(conversationUI.baseOptions or {})
                return
            end

            local _, msg = System.AttemptRecruitFromConversation(conversationUI)
            if msg and msg ~= "" then
                conversationUI:speak(msg)
            end
        end
    }
end

Internal.BuildRecruitOption = buildRecruitOption
