local System = DC_System
local Internal = System.Internal

local function cloneOptions(options)
    local merged = {}
    for _, option in ipairs(options or {}) do
        merged[#merged + 1] = option
    end
    if type(options) == "table" then
        for key, value in pairs(options) do
            if type(key) ~= "number" then
                merged[key] = value
            end
        end
    end
    return merged
end

local function buildFactionOption(ui)
    local status = System.GetOwnedFactionStatus and System.GetOwnedFactionStatus() or nil
    if not status or status.faction or status.canCreate ~= true then
        return nil
    end

    return {
        text = "Spread your Created Faction",
        message = "I actually have a faction, Tell them that were open for business and looking for members!",
        onSelect = function(conversationUI)
            local _, msg = System.PromptCreateFaction()
            if msg and msg ~= "" then
                conversationUI:speak(msg)
            end
            conversationUI:updateOptions(conversationUI.baseOptions or {})
        end
    }
end

local function appendDebugChatOptions(ui, merged)
    if not ui or not ui.interactionObj or not System.CanUseDebug() then
        return merged
    end

    local archetypeID = System.ResolveArchetype(ui.target)

    merged[#merged + 1] = {
        text = "DEBUG: Recruit To Colony (" .. archetypeID .. ")",
        message = "",
        onSelect = function(conversationUI)
            local _, msg = System.RecruitFromConversation(conversationUI)
            if msg and msg ~= "" then
                conversationUI:speak(msg)
            end
            conversationUI:updateOptions(conversationUI.baseOptions or {})
        end
    }

    return merged
end

function System.BuildConversationOptions(ui, options)
    local merged = cloneOptions(options)
    local menuID = type(options) == "table" and tostring(options._dtMenu or "root") or "root"

    if menuID ~= "root" then
        return merged
    end

    local factionOption = buildFactionOption(ui)
    if factionOption then
        merged[#merged + 1] = factionOption
    end

    return merged
end

function System.BuildConversationChatOptions(ui, options)
    local merged = cloneOptions(options)
    merged._dtMenu = "chat"

    local recruitOption = Internal.BuildRecruitOption and Internal.BuildRecruitOption(ui) or nil
    if recruitOption then
        merged[#merged + 1] = recruitOption
    end

    appendDebugChatOptions(ui, merged)
    return merged
end
