require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/DC_Colony_Sites"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition"
require "DC/Common/Colony/ColonySim/DC_Colony_Sim"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DC/Common/Colony/Warehouse/DC_ColonyWarehouse"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

-- Keep explicit load order so shared worker helpers exist before dependent handlers.
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers_Shared"
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers_Assignment"
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers_Deposit"
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers_Money"
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers_Withdraw"
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers_Drop"
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers_Job"
require "DC/Common/Colony/ColonyNetwork/Workers/DC_Workers_Lifecycle"

return DC_Colony.Network
