require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourRegistry/DT_LabourRegistry"
require "DT/Common/ZedColonies/DT_Labour_Sites"
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition"
require "DT/Common/ZedColonies/DT_Labour_Sim"
require "DT/Common/ZedColonies/DT_Labour_Presentation"
require "DT/Common/Buildings/DT_Buildings"

DT_Labour = DT_Labour or {}
DT_Labour.Network = DT_Labour.Network or {}
DT_Labour.Network.Internal = DT_Labour.Network.Internal or {}

require "DT/Common/ZedColonies/LabourNetwork/DT_LabourNetwork_Shared"
require "DT/Common/ZedColonies/LabourNetwork/DT_LabourNetwork_Inventory"
require "DT/Common/ZedColonies/LabourNetwork/DT_LabourNetwork_Reputation"
require "DT/Common/ZedColonies/LabourNetwork/DT_LabourNetwork_Recruitment"
require "DT/Common/ZedColonies/LabourNetwork/DT_LabourNetwork_QueryHandlers"
require "DT/Common/ZedColonies/LabourNetwork/Workers/DT_Workers"
require "DT/Common/Buildings/DT_BuildingsNetwork"
require "DT/Common/ZedColonies/LabourNetwork/DT_LabourNetwork_Debug"

return DT_Labour.Network
