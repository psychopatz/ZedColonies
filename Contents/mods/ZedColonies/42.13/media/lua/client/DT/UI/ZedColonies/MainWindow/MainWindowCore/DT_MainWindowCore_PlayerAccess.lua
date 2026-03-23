DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal

local function getConfig()
    local config = Internal.Config
    if type(config) ~= "table" then
        config = (DT_Labour and DT_Labour.Config) or {}
        Internal.Config = config
    end
    return config
end

local function getPlayerObject()
    local config = getConfig()
    if type(config.GetPlayerObject) == "function" then
        return config.GetPlayerObject()
    end
    return nil
end

function Internal.getPlayerWealth(player)
    if DT_MainWindow.MoneyProvider and DT_MainWindow.MoneyProvider.getPlayerWealth then
        return DT_MainWindow.MoneyProvider:getPlayerWealth(player)
    end
    return 0
end

function Internal.getOwnerUsername()
    local config = getConfig()
    local player = getPlayerObject()
    if type(config.GetOwnerUsername) == "function" then
        return config.GetOwnerUsername(player)
    end
    return "local"
end

function Internal.appendHeldItem(targetList, seenIDs, itemObj)
    if not itemObj or not itemObj.getID then
        return
    end

    local itemID = itemObj:getID()
    if itemID == nil or seenIDs[itemID] then
        return
    end

    seenIDs[itemID] = true
    targetList[#targetList + 1] = itemObj
end

function Internal.getHeldItems()
    local player = getPlayerObject()
    if not player then
        return {}
    end

    local items = {}
    local seenIDs = {}
    Internal.appendHeldItem(items, seenIDs, player.getPrimaryHandItem and player:getPrimaryHandItem() or nil)
    Internal.appendHeldItem(items, seenIDs, player.getSecondaryHandItem and player:getSecondaryHandItem() or nil)
    return items
end
