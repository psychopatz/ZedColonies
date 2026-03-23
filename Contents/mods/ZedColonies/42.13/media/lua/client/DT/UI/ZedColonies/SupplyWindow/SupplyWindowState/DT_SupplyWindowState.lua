DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

-- Keep explicit load order so state helpers exist before dependent modules.
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowState/DT_SupplyWindowState_Selection"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowState/DT_SupplyWindowState_Player"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowState/DT_SupplyWindowState_Worker"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowState/DT_SupplyWindowState_Optimistic"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowState/DT_SupplyWindowState_Scan"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowState/DT_SupplyWindowState_Update"

