DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

-- Keep explicit load order so core helpers are available before dependent modules.
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_Bootstrap"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_Formatters"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_ReserveData"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_WorkerPresentation"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_PlayerAccess"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_WorkerResolvers"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_LabourCommands"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_ReservePanel"

