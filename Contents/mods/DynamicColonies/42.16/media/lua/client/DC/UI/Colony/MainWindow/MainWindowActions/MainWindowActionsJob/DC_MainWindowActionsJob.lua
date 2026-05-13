require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Formatters"
require "ISUI/ISModalDialog"
require "ISUI/ISContextMenu"
require "DC/UI/Colony/ColonyJobModal/ColonyJobModal"
require "DC/UI/Colony/DC_CompanionLootModal"
require "DC/Common/Colony/Common/DC_MainWindowActionsJob_FlavorText"

DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}
DC_MainWindow.Internal.JobActions = DC_MainWindow.Internal.JobActions or {}

require "DC/UI/Colony/MainWindow/MainWindowActions/MainWindowActionsJob/DC_MainWindowActionsJob_Core"
require "DC/UI/Colony/MainWindow/MainWindowActions/MainWindowActionsJob/DC_MainWindowActionsJob_Status"
require "DC/UI/Colony/MainWindow/MainWindowActions/MainWindowActionsJob/DC_MainWindowActionsJob_Toggle"
require "DC/UI/Colony/MainWindow/MainWindowActions/MainWindowActionsJob/DC_MainWindowActionsJob_Companion"
require "DC/UI/Colony/MainWindow/MainWindowActions/MainWindowActionsJob/DC_MainWindowActionsJob_Cycle"

return DC_MainWindow