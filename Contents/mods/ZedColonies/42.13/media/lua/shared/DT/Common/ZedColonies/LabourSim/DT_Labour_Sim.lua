require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry"
require "DT/Common/ZedColonies/DT_Labour_Sites"
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition"
require "DT/Common/ZedColonies/DT_Labour_Output"
require "DT/Common/ZedColonies/DT_Labour_Presentation"
require "DT/Common/ZedColonies/LabourInteraction/DT_Labour_Interaction"
require "DT/Common/ZedColonies/Warehouse/DT_LabourWarehouse"

DT_Labour = DT_Labour or {}
DT_Labour.Sim = DT_Labour.Sim or {}
DT_Labour.Sim.Internal = DT_Labour.Sim.Internal or {}

local Sim = DT_Labour.Sim

if isClient() and not isServer() then
    return Sim
end

Sim.tickCounter = Sim.tickCounter or 0
Sim.lastProcessedHour = Sim.lastProcessedHour or -1

require "DT/Common/ZedColonies/LabourSim/DT_LabourSim_Helpers"
require "DT/Common/ZedColonies/LabourSim/DT_LabourSim_Outcome"
require "DT/Common/ZedColonies/LabourSim/DT_LabourSim_Nutrition"
require "DT/Common/ZedColonies/LabourSim/DT_LabourSim_Scavenge"
require "DT/Common/ZedColonies/LabourSim/DT_LabourSim_Process"

Events.OnTick.Add(Sim.OnTick)

return Sim
