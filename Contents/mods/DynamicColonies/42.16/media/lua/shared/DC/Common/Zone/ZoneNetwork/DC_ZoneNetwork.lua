require "DC/Common/Zone/DC_ZoneDataStore"
require "DC/Common/Colony/ColonyNetwork/ColonyNetShared/DC_ColonyNetShared"
require "DC/Common/Zone/ZoneNetwork/DC_ZoneNetwork_Shared"
require "DC/Common/Zone/ZoneNetwork/DC_ZoneNetwork_Query"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

return DC_Colony.Network