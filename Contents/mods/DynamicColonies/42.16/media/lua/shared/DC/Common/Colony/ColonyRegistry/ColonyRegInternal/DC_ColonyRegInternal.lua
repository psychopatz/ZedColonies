DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal

Internal.ColonyRegInternal = Internal.ColonyRegInternal or {}

require "DC/Common/Colony/ColonyRegistry/ColonyRegInternal/DC_ColonyRegInternal_Common"
require "DC/Common/Colony/ColonyRegistry/ColonyRegInternal/DC_ColonyRegInternal_WorkerSupport"
require "DC/Common/Colony/ColonyRegistry/ColonyRegInternal/DC_ColonyRegInternal_EquipmentMetadata"
require "DC/Common/Colony/ColonyRegistry/ColonyRegInternal/DC_ColonyRegInternal_EquipmentEntries"
require "DC/Common/Colony/ColonyRegistry/ColonyRegInternal/DC_ColonyRegInternal_OutputEntries"
require "DC/Common/Colony/ColonyRegistry/ColonyRegInternal/DC_ColonyRegInternal_Loadout"

return Internal