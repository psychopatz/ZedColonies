require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "ISUI/ISPanel"
require "ISUI/ISTextEntryBox"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition"
require "DT/Common/ZedColonies/LabourNetwork/DT_Labour_Network"

DT_SupplyWindow = ISCollapsableWindow:derive("DT_SupplyWindow")
DT_SupplyWindow.instance = nil
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

-- Keep explicit load order so shared helpers are available before dependent modules.
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowCore/DT_SupplyWindowCore"
require "DT/UI/ZedColonies/SupplyWindow/DT_SupplyWindow_List"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowLayout/DT_SupplyWindowLayout"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowState/DT_SupplyWindowState"
require "DT/UI/ZedColonies/SupplyWindow/SupplyWindowActions/DT_SupplyWindowActions"
require "DT/UI/ZedColonies/SupplyWindow/DT_SupplyWindow_Lifecycle"
require "DT/UI/ZedColonies/SupplyWindow/DT_SupplyWindow_Events"

return DT_SupplyWindow
