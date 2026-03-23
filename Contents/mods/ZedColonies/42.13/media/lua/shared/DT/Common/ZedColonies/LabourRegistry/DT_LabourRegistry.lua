require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourSkills/DT_LabourSkills"
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition"
require "DT/Common/ZedColonies/LabourTiredness/DT_LabourTiredness"

DT_Labour = DT_Labour or {}
DT_Labour.Registry = DT_Labour.Registry or {}
DT_Labour.Registry.Internal = DT_Labour.Registry.Internal or {}

-- Keep explicit load order so registry foundations are available before higher-level APIs.
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry_Internal"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry_Data"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry_WorkerState"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry_Workers"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry_Recruitment"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry_Presentation"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry_Ledgers"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry_WorkerCommands"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry_Sites"
require "DT/Common/ZedColonies/Warehouse/DT_LabourWarehouse"

return DT_Labour.Registry
