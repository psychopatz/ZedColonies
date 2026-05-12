require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Zone/DC_ZoneData"

DC_Base = DC_Base or {}
DC_Base.Internal = DC_Base.Internal or {}

require "DC/Common/Base/DC_Base_Data"
require "DC/Common/Base/DC_Base_Zones"
require "DC/Common/Base/DC_Base_HQ"
require "DC/Common/Base/DC_Base_Presence"

return DC_Base
