require "DC/Common/Config"
require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading = DynamicTrading or {}
DC_Colony = DC_Colony or {}
DC_Colony.Config = DC_Colony.Config or {}
DC_Colony.Config.Internal = DC_Colony.Config.Internal or {}

local Config = DC_Colony.Config

-- Keep explicit load order so base tables and helpers exist before derived logic.
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig_Core"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig_Skills"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig_Internal"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig_TimeSandbox"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig_Meals"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig_ItemTags"
require "DC/Common/Colony/ColonyEquipment/Backpacks/DC_ColonyEquipment_Backpacks"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig_Carry"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig_Player"
require "DC/Common/Colony/Companion/DC_ColonyCompanion"

return Config
