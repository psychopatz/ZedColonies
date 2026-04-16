require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Buildings/Core/DC_Buildings"

DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources_Constants"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources_Internal"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources_DataAccess"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources_GreenhouseState"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources_WaterMetrics"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources_Snapshots"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources_Inventory"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources_GreenhouseCommands"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources_Farming"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources_Simulation"

return DC_Colony.Resources