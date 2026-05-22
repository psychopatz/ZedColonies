DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}

local Config = DC_Colony.Config
Config.EquipmentRequirementDefinitions = Config.EquipmentRequirementDefinitions or {}
Config.__equipmentRequirementCache = Config.__equipmentRequirementCache or {}

-- ------------------------------------------------
-- Load Job-Specific Definitions
-- ------------------------------------------------

-- Common (All Jobs)
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Common/DC_ColonyEquipmentRequirements_Common"

-- Builder
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Builder/DC_ColonyEquipmentRequirements_Builder"

-- Farm
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Farm/DC_ColonyEquipmentRequirements_Farm"

-- Fish
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Fish/DC_ColonyEquipmentRequirements_Fish"

-- Gatherer
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Gatherer/DC_ColonyEquipmentRequirements_Gatherer"

-- Chop Trees
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/ChopTrees/DC_ColonyEquipmentRequirements_ChopTrees"

-- Scavenge
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Scavenge/DC_ColonyEquipmentRequirements_Scavenge"

-- ------------------------------------------------
-- Load Logic
-- ------------------------------------------------

-- Common
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Common/DC_ColonyEquipmentRequirements_Common_Logic"

-- Builder
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Builder/DC_ColonyEquipmentRequirements_Builder_Logic"

-- Farm
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Farm/DC_ColonyEquipmentRequirements_Farm_Logic"

-- Fish
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Fish/DC_ColonyEquipmentRequirements_Fish_Logic"

-- Gatherer
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Gatherer/DC_ColonyEquipmentRequirements_Gatherer_Logic"

-- Scavenge
require "DC/Common/Colony/ColonyEquipment/Requirements/ColonyEquipmentRequirements/Scavenge/DC_ColonyEquipmentRequirements_Scavenge_Logic"

return Config
