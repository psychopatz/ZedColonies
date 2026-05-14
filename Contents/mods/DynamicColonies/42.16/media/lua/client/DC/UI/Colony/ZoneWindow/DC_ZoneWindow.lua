-- ============================================================================
-- DC_ZoneWindow.lua — Entry Point for Colony Zone Management Window
--
-- Single entry file that derives the class and requires all sub-modules
-- in correct dependency order. This matches the DC_MainWindow pattern.
-- ============================================================================

require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"
require "ISUI/ISComboBox"
require "ISUI/ISModalDialog"
require "DC/Common/Zone/DC_ZoneData"
require "DC/UI/Colony/ZoneWindow/DC_ZoneSelector"
require "DC/UI/Colony/ZoneWindow/ZoneWindowState/DC_ZoneWindowState"
require "DC/UI/Colony/ZoneWindow/ZoneWindowSync/DC_ZoneWindowSync"
require "DC/UI/Colony/ZoneWindow/RealBase/DC_ZoneWindowRealBase"

local existingZoneWindow = DC_ZoneWindow
local existingInternal = existingZoneWindow and existingZoneWindow.Internal or nil

DC_ZoneWindow = ISCollapsableWindow:derive("DC_ZoneWindow")
DC_ZoneWindow.instance = nil
DC_ZoneWindow.Internal = existingInternal or DC_ZoneWindow.Internal or {}


require "DC/UI/Colony/ZoneWindow/ZoneWindowCore/DC_ZoneWindowCore"
require "DC/UI/Colony/ZoneWindow/DC_ZoneWindow_List"
require "DC/UI/Colony/ZoneWindow/DC_ZoneWindow_Detail"
require "DC/UI/Colony/ZoneWindow/ZoneWindowLayout/DC_ZoneWindowLayout"
require "DC/UI/Colony/ZoneWindow/ZoneWindowActions/DC_ZoneWindowActions"
require "DC/UI/Colony/ZoneWindow/DC_ZoneWindow_Lifecycle"
require "DC/UI/Colony/ZoneWindow/DC_ZoneWindow_Events"

return DC_ZoneWindow
