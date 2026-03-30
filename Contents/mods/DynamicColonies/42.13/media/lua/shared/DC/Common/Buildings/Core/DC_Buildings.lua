require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_Buildings = DC_Buildings or {}
DC_Buildings.Config = DC_Buildings.Config or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

require "DC/Common/Buildings/Config/DC_BuildingsBuilderToolConfig"

require "DC/Common/Buildings/Config/BuildingType/Armory/DC_BuildingsArmoryConfig"
require "DC/Common/Buildings/Config/BuildingType/Barracks/DC_BuildingsBarracksConfig"
require "DC/Common/Buildings/Config/BuildingType/Barricade/DC_BuildingsBarricadeConfig"
require "DC/Common/Buildings/Config/BuildingType/ElectricityGenerator/DC_BuildingsElectricityGeneratorConfig"
require "DC/Common/Buildings/Config/BuildingType/Greenhouse/DC_BuildingsGreenhouseConfig"
require "DC/Common/Buildings/Config/BuildingType/Headquarters/DC_BuildingsHeadquartersConfig"
require "DC/Common/Buildings/Config/BuildingType/Infirmary/DC_BuildingsInfirmaryConfig"
require "DC/Common/Buildings/Config/BuildingType/Kitchen/DC_BuildingsKitchenConfig"
require "DC/Common/Buildings/Config/BuildingType/Laboratory/DC_BuildingsLaboratoryConfig"
require "DC/Common/Buildings/Config/BuildingType/ResearchStation/DC_BuildingsResearchStationConfig"
require "DC/Common/Buildings/Config/BuildingType/TradeStand/DC_BuildingsTradeStandConfig"
require "DC/Common/Buildings/Config/BuildingType/WaterCollector/DC_BuildingsWaterCollectorConfig"
require "DC/Common/Buildings/Config/BuildingType/WaterTank/DC_BuildingsWaterTankConfig"
require "DC/Common/Buildings/Config/BuildingType/Warehouse/DC_BuildingsWarehouseConfig"

require "DC/Common/Buildings/Config/DC_BuildingsConfig"
require "DC/Common/Buildings/Data/DC_BuildingsMapData"
require "DC/Common/Buildings/Map/DC_BuildingsMapExpansion"
require "DC/Common/Buildings/Map/Frontier/DC_BuildingsMapFrontier"
require "DC/Common/Buildings/Data/DC_BuildingsData"
require "DC/Common/Buildings/Presentation/DC_BuildingsHousing"
require "DC/Common/Buildings/Map/DC_BuildingsMap"
require "DC/Common/Buildings/Projects/DC_BuildingsProjectTargeting"
require "DC/Common/Buildings/Projects/DC_BuildingsProjects"
require "DC/Common/Buildings/Map/DC_BuildingsMapPresentation"
require "DC/Common/Buildings/Presentation/DC_BuildingsPresentation"

return DC_Buildings
