require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry"
require "DT/Common/ZedColonies/DT_Labour_Sites"
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition"
require "DT/Common/ZedColonies/DT_Labour_Sim"
require "DT/Common/ZedColonies/DT_Labour_Presentation"
require "DT/Common/ZedColonies/Warehouse/DT_LabourWarehouse"

DT_Labour = DT_Labour or {}
DT_Labour.Network = DT_Labour.Network or {}
DT_Labour.Network.Internal = DT_Labour.Network.Internal or {}
DT_Labour.Network.Workers = DT_Labour.Network.Workers or {}

-- Keep explicit load order so shared worker helpers exist before dependent handlers.
require "DT/Common/ZedColonies/LabourNetwork/Workers/DT_Workers_Shared"
require "DT/Common/ZedColonies/LabourNetwork/Workers/DT_Workers_Assignment"
require "DT/Common/ZedColonies/LabourNetwork/Workers/DT_Workers_Deposit"
require "DT/Common/ZedColonies/LabourNetwork/Workers/DT_Workers_Money"
require "DT/Common/ZedColonies/LabourNetwork/Workers/DT_Workers_Withdraw"
require "DT/Common/ZedColonies/LabourNetwork/Workers/DT_Workers_Drop"
require "DT/Common/ZedColonies/LabourNetwork/Workers/DT_Workers_Job"
require "DT/Common/ZedColonies/LabourNetwork/Workers/DT_Workers_Lifecycle"

return DT_Labour.Network
