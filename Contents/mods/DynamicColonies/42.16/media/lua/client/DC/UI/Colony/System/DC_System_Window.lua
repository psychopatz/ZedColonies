local System = DC_System
local Internal = System.Internal

local function dispatchLocalCommand(player, module, command, args)
    if module == Internal.GetCommandModule()
        and DC_Colony
        and DC_Colony.Network
        and DC_Colony.Network.HandleCommand then
        DC_Colony.Network.HandleCommand(player, command, args or {})
        return true
    end

    if triggerEvent then
        triggerEvent("OnClientCommand", module, command, player, args or {})
        return true
    end

    return false
end

function System.CanUseDebug(player)
    local playerObj = player or Internal.GetLocalPlayer()
    local accessLevel = nil
    if playerObj and playerObj.getAccessLevel then
        accessLevel = playerObj:getAccessLevel()
    end
    local hasElevatedAccess = accessLevel and accessLevel ~= "" and accessLevel ~= "None"
    local isSinglePlayer = (not isClient or not isClient()) and not hasElevatedAccess

    if isSinglePlayer then
        return isDebugEnabled and isDebugEnabled() == true
    end

    if DynamicTrading and DynamicTrading.Debug then
        return true
    end

    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    if hasElevatedAccess then
        return true
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
    return System.SendCommandToModule(Internal.GetCommandModule(), command, args)
end

function System.SendFactionCommand(command, args)
    return System.SendCommandToModule(Internal.GetFactionCommandModule(), command, args)
end

function System.SendCommandToModule(module, command, args)
    local player = Internal.GetLocalPlayer()
    if not player then
        return false
    end

    module = module or Internal.GetCommandModule()

    if isClient() and not isServer() then
        sendClientCommand(player, module, command, args or {})
        return true
    end

    return dispatchLocalCommand(player, module, command, args)
end
