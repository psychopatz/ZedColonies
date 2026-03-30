require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/DC_Colony_Sites"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition"
require "DC/Common/Colony/DC_Colony_Output"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DC/Common/Colony/ColonyInteraction/DC_Colony_Interaction"
require "DC/Common/Colony/Warehouse/DC_ColonyWarehouse"
require "DC/Common/Colony/Resources/DC_ColonyResources"

DC_Colony = DC_Colony or {}
DC_Colony.Sim = DC_Colony.Sim or {}
DC_Colony.Sim.Internal = DC_Colony.Sim.Internal or {}

local Sim = DC_Colony.Sim

if isClient() and not isServer() then
    return Sim
end

Sim.tickCounter = Sim.tickCounter or 0
Sim.lastProcessedHour = Sim.lastProcessedHour or -1

require "DC/Common/Colony/ColonySim/DC_ColonySim_Helpers"
require "DC/Common/Colony/ColonySim/DC_ColonySim_Outcome"
require "DC/Common/Colony/ColonyHealth/DC_ColonyHealth"
require "DC/Common/Colony/ColonyMedical/DC_ColonyMedical"
require "DC/Common/Colony/Job/Common/DC_Job"
require "DC/Common/Colony/ColonySim/DC_ColonySim_Tools"
require "DC/Common/Colony/ColonySim/DC_ColonySim_Process"

Events.OnTick.Add(Sim.OnTick)

return Sim
