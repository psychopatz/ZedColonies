require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/DC_Colony_Sites"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition"
require "DC/Common/Colony/DC_Colony_Sim"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DC/Common/Buildings/Core/DC_Buildings"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Shared"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Inventory"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Reputation"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Recruitment"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_QueryHandlers"
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers"
require "DC/Common/Buildings/Network/DC_BuildingsNetwork"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Debug"

local STARTER_COLONIST_CHECK_RATE = 120

if isServer() and not DC_Colony.Network.ServerHookAdded then
    Events.OnClientCommand.Add(function(module, command, player, args)
        if module ~= ((DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony") then
            return
        end

        if DC_Colony.Network and DC_Colony.Network.HandleCommand then
            DC_Colony.Network.HandleCommand(player, command, args or {})
        end
    end)
    DC_Colony.Network.ServerHookAdded = true
end

if isServer() and not DC_Colony.Network.StarterColonistPlayerHookAdded then
    Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
        local player = playerObj
        if not player and type(playerIndex) == "userdata" then
            player = playerIndex
        end
        if not player then
            return
        end

        local network = DC_Colony and DC_Colony.Network or nil
        local internal = network and network.Internal or nil
        if internal and internal.EnsureStarterColonists then
            internal.EnsureStarterColonists(player, {})
        end
    end)
    DC_Colony.Network.StarterColonistPlayerHookAdded = true
end

if isServer() and not DC_Colony.Network.StarterColonistTickHookAdded then
    DC_Colony.Network.Internal.starterColonistTickCounter = 0
    Events.OnTick.Add(function()
        local network = DC_Colony and DC_Colony.Network or nil
        local internal = network and network.Internal or nil
        if not internal or not internal.EnsureStarterColonists then
            return
        end

        internal.starterColonistTickCounter = (tonumber(internal.starterColonistTickCounter) or 0) + 1
        if internal.starterColonistTickCounter < STARTER_COLONIST_CHECK_RATE then
            return
        end
        internal.starterColonistTickCounter = 0

        local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
        if not onlinePlayers then
            return
        end

        for index = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(index)
            if player then
                internal.EnsureStarterColonists(player, {})
            end
        end
    end)
    DC_Colony.Network.StarterColonistTickHookAdded = true
end

return DC_Colony.Network
