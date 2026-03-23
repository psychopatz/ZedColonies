require "DT/Common/Config"
require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading = DynamicTrading or {}
DT_Labour = DT_Labour or {}
DT_Labour.Config = DT_Labour.Config or {}
DT_Labour.Config.Internal = DT_Labour.Config.Internal or {}

local Config = DT_Labour.Config

-- Keep explicit load order so base tables and helpers exist before derived logic.
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_Core"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_Jobs"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_ScavengeData"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_Skills"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_Internal"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_JobsLogic"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_TimeSandbox"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_Meals"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_ItemTags"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_ScavengeProfiles"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_Carry"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_ScavengeLogic"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig_Player"

return Config
