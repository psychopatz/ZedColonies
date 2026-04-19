require "DC/UI/Colony/MainWindow/DC_MainWindow"
require "DC/UI/Colony/DC_ColonyMapProvider"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyNetwork/DC_Colony_Network"

-- Keep explicit load order so helpers are registered before dependent modules.
require "DC/UI/Colony/System/DC_System_Shared"
require "DC/UI/Colony/System/DC_System_Window"
require "DC/UI/Colony/System/DC_System_Factions"
require "DC/UI/Colony/System/DC_System_Conversation"
require "DC/UI/Colony/System/DC_System_Recruitment"
require "DC/UI/Colony/System/DC_System_Options"
require "DC/UI/Colony/System/DC_System_CompanionCommands"
require "DC/UI/Colony/System/DC_System_Events"

return DC_System
