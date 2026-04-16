DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal
local Config = Internal.Config

function Internal.GetActualFactionForUsername(username)
    if not DynamicTrading_Factions or not DynamicTrading_Factions.GetPlayerFaction then
        return nil
    end
    return DynamicTrading_Factions.GetPlayerFaction(tostring(username or ""))
end

function Internal.IsUsernameInWorkerColony(worker, username)
    local normalizedUsername = tostring(username or "")
    if not worker or normalizedUsername == "" then
        return false
    end

    local owner = Config.GetOwnerUsername and Config.GetOwnerUsername(worker.ownerUsername) or tostring(worker.ownerUsername or "")
    if normalizedUsername == owner then
        return true
    end

    local faction = Internal.GetActualFactionForUsername(normalizedUsername)
    if type(faction) ~= "table" then
        return false
    end

    if tostring(faction.leadershipState or "Active") ~= "Active" then
        return false
    end
    if tostring(faction.leaderUsername or "") ~= owner then
        return false
    end
    for _, memberUsername in ipairs(faction.memberUsernames or {}) do
        if tostring(memberUsername or "") == normalizedUsername then
            return true
        end
    end

    return false
end