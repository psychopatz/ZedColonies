DC_Colony = DC_Colony or {}
DC_Colony.Job = DC_Colony.Job or {}

-- Common Core Dependencies
require "DC/Common/Colony/Job/Common/DC_Job_Config"
require "DC/Common/Colony/Job/Common/DC_Job_ConfigLogic"
require "DC/Common/Colony/ColonyEquipment/Requirements/DC_ColonyEquipment_Requirements"

-- Scavenging Subsystem
require "DC/Common/Colony/Job/Scavenging/DC_Job_Scavenging_ConfigTools"
require "DC/Common/Colony/Job/Scavenging/DC_Job_Scavenging_ConfigData"
require "DC/Common/Colony/Job/Scavenging/DC_Job_Scavenging_ConfigProfiles"
require "DC/Common/Colony/Job/Scavenging/DC_Job_Scavenging_ConfigLogic"
require "DC/Common/Colony/Job/Scavenging/DC_Job_Scavenging_Output"
require "DC/Common/Colony/Job/Scavenging/DC_Job_Scavenging_Sim"
require "DC/Common/Colony/Job/Scavenging/DC_Job_Scavenging_Process"

-- Builder Subsystem
require "DC/Common/Colony/Job/Builder/DC_Job_Builder_ConfigTools"
require "DC/Common/Colony/Job/Builder/DC_Job_Builder_Process"

-- Doctor Subsystem
require "DC/Common/Colony/Job/Doctor/DC_Job_Doctor_ConfigTools"
require "DC/Common/Colony/Job/Doctor/DC_Job_Doctor_Process"

-- Farming Subsystem
require "DC/Common/Colony/Job/Farming/DC_Job_Farming_ConfigTools"
require "DC/Common/Colony/Job/Farming/DC_Job_Farming_Process"

-- Fishing Subsystem
require "DC/Common/Colony/Job/Fishing/DC_Job_Fishing_ConfigTools"
require "DC/Common/Colony/Job/Fishing/DC_Job_Fishing_Process"

-- Travel Companion
require "DC/Common/Colony/Companion/ColonyCompanion/DC_ColonyCompanion"

return DC_Colony.Job
