require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/DC_Colony_Sites"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition"
require "DC/Common/Colony/ColonySim/DC_Colony_Sim"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/Resources/DC_ColonyResources"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Shared"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Inventory"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Reputation"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Recruitment"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_StarterWorkers"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_QueryHandlers"
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers"
require "DC/Common/Buildings/Network/DC_BuildingsNetwork"
require "DC/Common/Colony/ColonyNetwork/DC_ColonyNetwork_Debug"

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

return DC_Colony.Network
