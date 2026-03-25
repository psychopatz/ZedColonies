DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

-- Keep explicit load order so bootstrap helpers exist before dependent modules.
require "DC/UI/Colony/SupplyWindow/SupplyWindowCore/DC_SupplyWindowCore_Bootstrap"
require "DC/UI/Colony/SupplyWindow/SupplyWindowCore/DC_SupplyWindowCore_PlayerAccess"
require "DC/UI/Colony/SupplyWindow/SupplyWindowCore/DC_SupplyWindowCore_Search"
require "DC/UI/Colony/SupplyWindow/SupplyWindowCore/DC_SupplyWindowCore_Grouping"
require "DC/UI/Colony/SupplyWindow/SupplyWindowCore/DC_SupplyWindowCore_Textures"
require "DC/UI/Colony/SupplyWindow/SupplyWindowCore/DC_SupplyWindowCore_EntryBuilders"
require "DC/UI/Colony/SupplyWindow/SupplyWindowCore/Presentation/DC_Presentation"
require "DC/UI/Colony/SupplyWindow/SupplyWindowCore/DC_SupplyWindowCore_ColonyCommands"
