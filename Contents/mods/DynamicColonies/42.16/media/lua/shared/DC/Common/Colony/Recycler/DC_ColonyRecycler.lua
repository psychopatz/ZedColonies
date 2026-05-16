require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/Warehouse/DC_ColonyWarehouse"
require "DC/Common/Colony/Research/DC_ColonyResearch"

DC_Colony = DC_Colony or {}
DC_Colony.Recycler = DC_Colony.Recycler or {}
DC_Colony.Recycler.Internal = DC_Colony.Recycler.Internal or {}

require "DC/Common/Colony/Recycler/DC_ColonyRecycler_Config"
require "DC/Common/Colony/Recycler/DC_ColonyRecycler_Core"

return DC_Colony.Recycler
