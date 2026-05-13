DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal

Internal.ColonyRegWorkerState = Internal.ColonyRegWorkerState or {}

require "DC/Common/Colony/ColonyRegistry/ColonyRegWorkerState/DC_ColonyRegWorkerState_Common"
require "DC/Common/Colony/ColonyRegistry/ColonyRegWorkerState/DC_ColonyRegWorkerState_Companion"
require "DC/Common/Colony/ColonyRegistry/ColonyRegWorkerState/DC_ColonyRegWorkerState_Nutrition"
require "DC/Common/Colony/Common/DC_ColonyRegWorkerState_FlavorText"
require "DC/Common/Colony/ColonyRegistry/ColonyRegWorkerState/DC_ColonyRegWorkerState_Gatherer"
require "DC/Common/Colony/ColonyRegistry/ColonyRegWorkerState/DC_ColonyRegWorkerState_Recalculate"
require "DC/Common/Colony/ColonyRegistry/ColonyRegWorkerState/DC_ColonyRegWorkerState_Requirements"

return Registry