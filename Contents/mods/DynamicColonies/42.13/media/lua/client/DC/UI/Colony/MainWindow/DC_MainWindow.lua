require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"
require "ISUI/ISPanel"
require "ISUI/ISModalDialog"
require "DC/UI/Colony/DC_ColonyJobModal"
require "DC/UI/Colony/DC_ColonyQuantityModal"
require "DC/UI/Colony/DC_ColonyHelpWindow"
require "DC/UI/Colony/DC_ColonyCharacterWindow"
require "DC/UI/Colony/Buildings/DC_BuildingsWindow"
require "DC/UI/Colony/Resources/DC_ResourcesWindow"
require "DC/UI/Colony/SupplyWindow/DC_SupplyWindow"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/ColonyNetwork/DC_Colony_Network"
require "DC/Common/UI/Trading/Provider/DC_TradingProvider_Core"
require "DC/UI/Faction/FactionInfoWindow/DC_FactionInfoWindow"
require "DC/UI/Faction/DC_PlayerFactionNameModal"

DC_MainWindow = ISCollapsableWindow:derive("DC_MainWindow")
DC_MainWindow.instance = nil
DC_MainWindow.cachedWorkers = DC_MainWindow.cachedWorkers or {}
DC_MainWindow.cachedDetails = DC_MainWindow.cachedDetails or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

-- Keep explicit load order so core helpers are available before dependent modules.
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore"
require "DC/UI/Colony/MainWindow/DC_MainWindow_List"
require "DC/UI/Colony/MainWindow/MainWindowLayout/DC_MainWindowLayout"
require "DC/UI/Colony/MainWindow/MainWindowDetail/DC_MainWindowDetail"
require "DC/UI/Colony/MainWindow/MainWindowActions/DC_MainWindowActions"
require "DC/UI/Colony/MainWindow/DC_MainWindow_Lifecycle"
require "DC/UI/Colony/MainWindow/DC_MainWindow_Events"

return DC_MainWindow
