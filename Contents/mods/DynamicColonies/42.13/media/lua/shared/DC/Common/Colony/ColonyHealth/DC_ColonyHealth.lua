DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}

local Config = DC_Colony.Config

require "DC/Common/Colony/ColonyHealth/DC_ColonyHealth_Config"
require "DC/Common/Colony/ColonyHealth/DC_ColonyHealth_WorkerState"
require "DC/Common/Colony/ColonyHealth/DC_ColonyHealth_Process"
require "DC/Common/Colony/ColonyHealth/DC_ColonyHealth_Presentation"

return DC_Colony.Health
