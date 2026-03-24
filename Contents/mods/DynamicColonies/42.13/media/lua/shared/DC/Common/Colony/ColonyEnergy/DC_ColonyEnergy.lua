require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_Colony = DC_Colony or {}
DC_Colony.Energy = DC_Colony.Energy or {}

require "DC/Common/Colony/ColonyEnergy/DC_ColonyEnergy_Config"
require "DC/Common/Colony/ColonyEnergy/DC_ColonyEnergy_WorkerState"
require "DC/Common/Colony/ColonyEnergy/DC_ColonyEnergy_Rates"
require "DC/Common/Colony/ColonyEnergy/DC_ColonyEnergy_Process"
require "DC/Common/Colony/ColonyEnergy/DC_ColonyEnergy_Presentation"

-- Backwards compatibility
DC_Colony.Tiredness = DC_Colony.Energy

return DC_Colony.Energy

