require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"

DT_Labour = DT_Labour or {}
DT_Labour.Tiredness = DT_Labour.Tiredness or {}

require "DT/Common/ZedColonies/LabourTiredness/DT_LabourTiredness_Config"
require "DT/Common/ZedColonies/LabourTiredness/DT_LabourTiredness_WorkerState"
require "DT/Common/ZedColonies/LabourTiredness/DT_LabourTiredness_Rates"
require "DT/Common/ZedColonies/LabourTiredness/DT_LabourTiredness_Process"
require "DT/Common/ZedColonies/LabourTiredness/DT_LabourTiredness_Presentation"

return DT_Labour.Tiredness
