require "DC/UI/Colony/Utils/DC_UIStringUtils"
require "DC/Common/Colony/Common/DC_MainWindowEvents_FlavorText"

DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}
DC_Colony = DC_Colony or {}
DC_Colony.UI = DC_Colony.UI or {}

local Internal = DC_MainWindow.Internal
Internal.Events = Internal.Events or {}

require "DC/UI/Colony/MainWindow/MainWindowEvents/DC_MainWindowEvents_Merge"
require "DC/UI/Colony/MainWindow/MainWindowEvents/DC_MainWindowEvents_Cache"
require "DC/UI/Colony/MainWindow/MainWindowEvents/DC_MainWindowEvents_ServerCommands"
require "DC/UI/Colony/MainWindow/MainWindowEvents/DC_MainWindowEvents_Registration"

return DC_MainWindow