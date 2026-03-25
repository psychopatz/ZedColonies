local System = DC_System
local Internal = System.Internal

function System.CanUseDebug(player)
    local playerObj = player or Internal.GetLocalPlayer()

    if DynamicTrading and DynamicTrading.Debug then
        return true
    end

    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    if playerObj and playerObj.getAccessLevel then
        local accessLevel = playerObj:getAccessLevel()
        if accessLevel and accessLevel ~= "" and accessLevel ~= "None" then
            return true
        end
    end

    return false
end

function System.ToggleWindow()
    if DC_MainWindow and DC_MainWindow.ToggleWindow then
        DC_MainWindow.ToggleWindow()
    end
end

function System.OpenWindow()
    if DC_MainWindow and DC_MainWindow.Open then
        DC_MainWindow.Open()
    elseif DC_MainWindow and DC_MainWindow.ToggleWindow then
        DC_MainWindow.ToggleWindow()
    end
end

function System.SendCommand(command, args)
    local player = Internal.GetLocalPlayer()
    if not player then
        return false
    end

    if isClient() and not isServer() then
        sendClientCommand(player, Internal.GetCommandModule(), command, args or {})
        return true
    end

    if triggerEvent and isServer and isServer() and not (isClient and isClient()) then
        triggerEvent("OnClientCommand", Internal.GetCommandModule(), command, player, args or {})
        return true
    end

    if DC_Colony and DC_Colony.Network and DC_Colony.Network.HandleCommand then
        DC_Colony.Network.HandleCommand(player, command, args or {})
        return true
    end

    return false
end
