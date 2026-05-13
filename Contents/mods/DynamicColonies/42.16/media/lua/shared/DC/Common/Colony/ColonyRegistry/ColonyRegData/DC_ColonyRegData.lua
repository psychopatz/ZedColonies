DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal

Internal.Runtime = Internal.Runtime or {}
Internal.ColonyRegData = Internal.ColonyRegData or {}

require "DC/Common/Colony/ColonyRegistry/ColonyRegData/DC_ColonyRegData_Common"
require "DC/Common/Colony/ColonyRegistry/ColonyRegData/DC_ColonyRegData_Builders"
require "DC/Common/Colony/ColonyRegistry/ColonyRegData/DC_ColonyRegData_Normalize"
require "DC/Common/Colony/ColonyRegistry/ColonyRegData/DC_ColonyRegData_Runtime"
require "DC/Common/Colony/ColonyRegistry/ColonyRegData/DC_ColonyRegData_Access"
require "DC/Common/Colony/ColonyRegistry/ColonyRegData/DC_ColonyRegData_Versions"

return Registry