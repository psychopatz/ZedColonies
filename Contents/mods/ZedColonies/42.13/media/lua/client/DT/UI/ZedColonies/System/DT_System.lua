require "DT/UI/ZedColonies/MainWindow/DT_MainWindow"
require "DT/UI/ZedColonies/DT_LabourMapProvider"
require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourNetwork/DT_Labour_Network"

-- Keep explicit load order so helpers are registered before dependent modules.
require "DT/UI/ZedColonies/System/DT_System_Shared"
require "DT/UI/ZedColonies/System/DT_System_Window"
require "DT/UI/ZedColonies/System/DT_System_Factions"
require "DT/UI/ZedColonies/System/DT_System_Conversation"
require "DT/UI/ZedColonies/System/DT_System_Recruitment"
require "DT/UI/ZedColonies/System/DT_System_Options"
require "DT/UI/ZedColonies/System/DT_System_Events"

return DT_System
