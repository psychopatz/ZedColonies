local System = DC_System
local Internal = System.Internal

local function buildFactionOption(ui)
    local status = System.GetOwnedFactionStatus and System.GetOwnedFactionStatus() or nil
    if not status or status.faction or status.canCreate ~= true then
        return nil
    end

    return {
        text = "Create Faction",
        message = "",
        onSelect = function(conversationUI)
            local _, msg = System.PromptCreateFaction()
            if msg and msg ~= "" then
                conversationUI:speak(msg)
            end
            conversationUI:updateOptions(conversationUI.baseOptions or {})
        end
    }
end

function System.BuildConversationOptions(ui, options)
    local merged = {}
    for _, option in ipairs(options or {}) do
        merged[#merged + 1] = option
    end

    if ui and ui.isCompanionConversation then
        return merged
    end

    local recruitOption = Internal.BuildRecruitOption and Internal.BuildRecruitOption(ui) or nil
    if recruitOption then
        merged[#merged + 1] = recruitOption
    end

    local factionOption = buildFactionOption(ui)
    if factionOption then
        merged[#merged + 1] = factionOption
    end

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

    merged[#merged + 1] = {
        text = "DEBUG: Open Colony Management",
        message = "",
        onSelect = function(conversationUI)
            System.OpenWindow()
            conversationUI:updateOptions(conversationUI.baseOptions or {})
        end
    }

    return merged
end
