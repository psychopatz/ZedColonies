function DC_BuildingProjectModal:canUseDebug()
    if DynamicTrading and DynamicTrading.Debug then
        return true
    end

    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    local player = nil
    if getSpecificPlayer then
        player = getSpecificPlayer(0)
    elseif getPlayer then
        player = getPlayer()
    end

    if player and player.getAccessLevel then
        local accessLevel = player:getAccessLevel()
        if accessLevel and accessLevel ~= "" and accessLevel ~= "None" then
            return true
        end
    end

    return false
end
