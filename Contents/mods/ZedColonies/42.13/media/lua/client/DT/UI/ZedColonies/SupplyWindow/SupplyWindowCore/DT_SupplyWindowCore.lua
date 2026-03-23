DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

-- Keep explicit load order so bootstrap helpers exist before dependent modules.
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowCore/DT_SupplyWindowCore_Bootstrap"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowCore/DT_SupplyWindowCore_PlayerAccess"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowCore/DT_SupplyWindowCore_Search"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowCore/DT_SupplyWindowCore_Textures"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowCore/DT_SupplyWindowCore_EntryBuilders"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowCore/Presentation/DT_Presentation"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowCore/DT_SupplyWindowCore_LabourCommands"

