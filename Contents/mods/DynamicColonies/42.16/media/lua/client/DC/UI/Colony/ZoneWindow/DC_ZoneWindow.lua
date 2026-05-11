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

DC_ZoneWindow = ISCollapsableWindow:derive("DC_ZoneWindow")
DC_ZoneWindow.instance = nil
DC_ZoneWindow.Internal = DC_ZoneWindow.Internal or {}

-- Load sub-modules in dependency order:
-- 1. Core (bootstrap + helpers) must come first
-- 2. List + Detail define panel logic used by Layout
-- 3. Layout builds widgets and calls List/Detail methods
-- 4. Actions wire button callbacks
-- 5. Lifecycle provides Open/Close
-- 6. Events provides hooks and debug commands

require "DC/UI/Colony/ZoneWindow/ZoneWindowCore/DC_ZoneWindowCore"
require "DC/UI/Colony/ZoneWindow/DC_ZoneWindow_List"
require "DC/UI/Colony/ZoneWindow/DC_ZoneWindow_Detail"
require "DC/UI/Colony/ZoneWindow/ZoneWindowLayout/DC_ZoneWindowLayout"
require "DC/UI/Colony/ZoneWindow/ZoneWindowActions/DC_ZoneWindowActions"
require "DC/UI/Colony/ZoneWindow/DC_ZoneWindow_Lifecycle"
require "DC/UI/Colony/ZoneWindow/DC_ZoneWindow_Events"

return DC_ZoneWindow
