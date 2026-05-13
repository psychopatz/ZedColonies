DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Internal = Buildings.Internal
local Materials = Internal.ProjectMaterials or {}

Materials.Config = Buildings.Config
Internal.ProjectMaterials = Materials

require "DC/Common/Buildings/Projects/BuildingsProjectMaterials/BuildingsProjectMaterials_Common"
require "DC/Common/Buildings/Projects/BuildingsProjectMaterials/BuildingsProjectMaterials_Recipe"
require "DC/Common/Buildings/Projects/BuildingsProjectMaterials/BuildingsProjectMaterials_Sources"
require "DC/Common/Buildings/Projects/BuildingsProjectMaterials/BuildingsProjectMaterials_Availability"
require "DC/Common/Buildings/Projects/BuildingsProjectMaterials/BuildingsProjectMaterials_Tracking"
require "DC/Common/Buildings/Projects/BuildingsProjectMaterials/BuildingsProjectMaterials_Public"

return Buildings