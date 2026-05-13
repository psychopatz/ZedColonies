DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal

Internal.ColonyRegLedgers = Internal.ColonyRegLedgers or {}

require "DC/Common/Colony/ColonyRegistry/ColonyRegLedgers/DC_ColonyRegLedgers_Common"
require "DC/Common/Colony/ColonyRegistry/ColonyRegLedgers/DC_ColonyRegLedgers_Inventory"
require "DC/Common/Colony/ColonyRegistry/ColonyRegLedgers/DC_ColonyRegLedgers_Entries"
require "DC/Common/Colony/ColonyRegistry/ColonyRegLedgers/DC_ColonyRegLedgers_Haul"
require "DC/Common/Colony/ColonyRegistry/ColonyRegLedgers/DC_ColonyRegLedgers_Money"

return Registry