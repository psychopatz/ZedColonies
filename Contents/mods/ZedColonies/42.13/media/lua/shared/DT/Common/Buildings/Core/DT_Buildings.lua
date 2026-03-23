require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"

DT_Buildings = DT_Buildings or {}
DT_Buildings.Config = DT_Buildings.Config or {}
DT_Buildings.Internal = DT_Buildings.Internal or {}

require "DT/Common/Buildings/Config/DT_BuildingsHQConfig"
require "DT/Common/Buildings/Config/DT_BuildingsConfig"
require "DT/Common/Buildings/Data/DT_BuildingsMapData"
require "DT/Common/Buildings/Map/DT_BuildingsMapExpansion"
require "DT/Common/Buildings/Data/DT_BuildingsData"
require "DT/Common/Buildings/Presentation/DT_BuildingsHousing"
require "DT/Common/Buildings/Map/DT_BuildingsMap"
require "DT/Common/Buildings/Projects/DT_BuildingsProjectTargeting"
require "DT/Common/Buildings/Projects/DT_BuildingsProjects"
require "DT/Common/Buildings/Map/DT_BuildingsMapPresentation"
require "DT/Common/Buildings/Presentation/DT_BuildingsPresentation"

return DT_Buildings
