DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local Internal = DC_MainWindow.Internal

local function getConfig()
    local config = Internal.Config
    if type(config) ~= "table" then
        config = (DC_Colony and DC_Colony.Config) or {}
        Internal.Config = config
    end
    return config
end

function DC_MainWindow:sendColonyCommand(command, args)
    local config = getConfig()
    local player = type(config.GetPlayerObject) == "function" and config.GetPlayerObject() or nil
    if not player then
        return false
    end

    if isClient() and not isServer() then
        sendClientCommand(player, config.COMMAND_MODULE or "DColony", command, args or {})
        return true
    end

    if triggerEvent and isServer() and not isClient() then
        triggerEvent("OnClientCommand", config.COMMAND_MODULE or "DColony", command, player, args or {})
        return true
    end

    if DC_Colony and DC_Colony.Network and DC_Colony.Network.HandleCommand then
        DC_Colony.Network.HandleCommand(player, command, args or {})
        return true
    end

    return false
end
