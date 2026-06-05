require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Buildings/Core/DC_Buildings"

DC_Colony = DC_Colony or {}
DC_Colony.CorpseFacilities = DC_Colony.CorpseFacilities or {}
DC_Colony.CorpseFacilities.Internal = DC_Colony.CorpseFacilities.Internal or {}

require "DC/Common/Colony/CorpseFacilities/DC_ColonyCorpseFacilities_Data"
require "DC/Common/Colony/CorpseFacilities/DC_ColonyCorpseFacilities_Core"
require "DC/Common/Colony/CorpseFacilities/DC_ColonyCorpseFacilities_Presentation"
require "DC/Common/Colony/CorpseFacilities/DC_ColonyCorpseFacilities_Network"

return DC_Colony.CorpseFacilities
