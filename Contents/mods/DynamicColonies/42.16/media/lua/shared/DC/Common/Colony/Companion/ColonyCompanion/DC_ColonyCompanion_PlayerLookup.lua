DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.GetPlayerUsername(player)
    if player and player.getUsername then
        local username = player:getUsername()
        if username and username ~= "" then
            return tostring(username)
        end
    end
    return nil
end

function Internal.GetPlayerOnlineID(player)
    if player and player.getOnlineID then
        return tonumber(player:getOnlineID())
    end
    return nil
end

function Internal.GetOnlinePlayerByUsername(username)
    local target = tostring(username or "")
    if target == "" then
        return nil
    end

    local localPlayer = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    if localPlayer and localPlayer.getUsername and tostring(localPlayer:getUsername() or "") == target then
        return localPlayer
    end

    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players then
        for index = 0, players:size() - 1 do
            local player = players:get(index)
            if player and player.getUsername and tostring(player:getUsername() or "") == target then
                return player
            end
        end
    end

    return nil
end

function Internal.IsOnlinePlayerValid(username)
    local player = Internal.GetOnlinePlayerByUsername(username)
    if not player then
        return false, nil
    end
    if player.isDead and player:isDead() then
        return false, player
    end
    return true, player
end