DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config

function Config.IsFoodOrDrinkItem(itemObj)
    if not itemObj then return false end
    local fullType = itemObj.getFullType and itemObj:getFullType() or nil
    local tags = Config.FindItemTags(fullType)
    return Config.HasMatchingTag(tags, "Food")
        or Config.HasMatchingTag(tags, "Container.Liquid")
        or (itemObj.getFluidContainer and itemObj:getFluidContainer() ~= nil)
end

function Config.IsToolItem(itemObj)
    if not itemObj then return false end
    local fullType = itemObj.getFullType and itemObj:getFullType() or nil
    return Config.IsColonyToolFullType(fullType)
end

function Config.GetPlayerObject()
    if getSpecificPlayer then
        return getSpecificPlayer(0)
    end
    if getPlayer then
        return getPlayer()
    end
    return nil
end

function Config.GetOnlineOwnerPlayer(ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for index = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(index)
            if player and Config.GetOwnerUsername(player) == owner then
                return player
            end
        end
    end

    local player = Config.GetPlayerObject()
    if player and Config.GetOwnerUsername(player) == owner then
        return player
    end

    return nil
end

function Config.IsOwnerOnline(ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    if owner == "local" then
        return Config.GetPlayerObject() ~= nil
    end

    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for index = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(index)
            if player and Config.GetOwnerUsername(player) == owner then
                return true
            end
        end
    end

    local player = Config.GetPlayerObject()
    if player and Config.GetOwnerUsername(player) == owner then
        return true
    end

    return false
end

return Config
