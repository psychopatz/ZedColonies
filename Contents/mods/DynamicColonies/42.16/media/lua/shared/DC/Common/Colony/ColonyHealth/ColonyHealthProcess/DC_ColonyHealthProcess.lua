DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}
DC_Colony.Medical = DC_Colony.Medical or {}

local Health = DC_Colony.Health

Health.Internal = Health.Internal or {}
Health.Internal.Process = Health.Internal.Process or {}

require "DC/Common/Colony/ColonyHealth/ColonyHealthProcess/DC_ColonyHealthProcess_State"
require "DC/Common/Colony/ColonyHealth/ColonyHealthProcess/DC_ColonyHealthProcess_Rates"
require "DC/Common/Colony/ColonyHealth/Common/DC_ColonyHealthProcess_FlavorText"
require "DC/Common/Colony/ColonyHealth/ColonyHealthProcess/DC_ColonyHealthProcess_SelfTreatment"
require "DC/Common/Colony/ColonyHealth/ColonyHealthProcess/DC_ColonyHealthProcess_Deprivation"
require "DC/Common/Colony/ColonyHealth/ColonyHealthProcess/DC_ColonyHealthProcess_Sleep"

return Health