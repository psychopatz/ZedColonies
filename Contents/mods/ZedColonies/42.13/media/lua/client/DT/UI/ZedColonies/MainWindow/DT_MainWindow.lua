require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "ISUI/ISPanel"
require "ISUI/ISModalDialog"
require "DT/UI/ZedColonies/DT_LabourJobModal"
require "DT/UI/ZedColonies/DT_LabourQuantityModal"
require "DT/UI/ZedColonies/DT_LabourHelpWindow"
require "DT/UI/ZedColonies/DT_LabourCharacterWindow"
require "DT/UI/ZedColonies/Buildings/DT_BuildingsWindow"
require "DT/UI/ZedColonies/SupplyWindow/DT_SupplyWindow"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry"
require "DT/Common/ZedColonies/LabourNetwork/DT_Labour_Network"
require "DT/Common/UI/Trading/Provider/DT_TradingProvider_Core"
require "DT/UI/Faction/FactionInfoWindow/DT_FactionInfoWindow"
require "DT/UI/Faction/DT_PlayerFactionNameModal"

DT_MainWindow = ISCollapsableWindow:derive("DT_MainWindow")
DT_MainWindow.instance = nil
DT_MainWindow.cachedWorkers = DT_MainWindow.cachedWorkers or {}
DT_MainWindow.cachedDetails = DT_MainWindow.cachedDetails or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

-- Keep explicit load order so core helpers are available before dependent modules.
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore"
require "DT/UI/ZedColonies/MainWindow/DT_MainWindow_List"
require "DT/UI/ZedColonies/MainWindow/MainWindowLayout/DT_MainWindowLayout"
require "DT/UI/ZedColonies/MainWindow/MainWindowDetail/DT_MainWindowDetail"
require "DT/UI/ZedColonies/MainWindow/MainWindowActions/DT_MainWindowActions"
require "DT/UI/ZedColonies/MainWindow/DT_MainWindow_Lifecycle"
require "DT/UI/ZedColonies/MainWindow/DT_MainWindow_Events"

return DT_MainWindow
