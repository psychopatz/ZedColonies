require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/Warehouse/DC_ColonyWarehouse"

DC_Buildings = DC_Buildings or {}
DC_Buildings.Production = DC_Buildings.Production or {}
DC_Buildings.Production.Internal = DC_Buildings.Production.Internal or {}

require "DC/Common/Buildings/Production/DC_BuildingsProductionConfig"
require "DC/Common/Buildings/Production/DC_BuildingsProductionRecipes"
require "DC/Common/Buildings/Production/DC_BuildingsProductionWorkerFlow"

return DC_Buildings.Production
