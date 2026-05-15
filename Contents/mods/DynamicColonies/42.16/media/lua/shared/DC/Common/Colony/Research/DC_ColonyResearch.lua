require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/Warehouse/DC_ColonyWarehouse"

DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

require "DC/Common/Colony/Research/DC_ColonyResearch_Config"
require "DC/Common/Colony/Research/DC_ColonyResearch_Data"
require "DC/Common/Colony/Research/DC_ColonyResearch_Blueprints"
require "DC/Common/Colony/Research/DC_ColonyResearch_Queue"
require "DC/Common/Colony/Research/DC_ColonyResearch_ReverseEngineer"
require "DC/Common/Colony/Research/DC_ColonyResearch_WorkerFlow"
require "DC/Common/Colony/Research/DC_ColonyResearch_Presentation"

return DC_Colony.Research
