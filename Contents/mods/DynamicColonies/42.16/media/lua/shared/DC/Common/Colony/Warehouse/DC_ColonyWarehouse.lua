require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition"
require "DC/Common/Colony/AbstractInventory/DC_ColonyAbstractInventory"

DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Warehouse = DC_Colony.Warehouse

require "DC/Common/Colony/Warehouse/ColonyWarehouseData/ColonyWarehouseData"
require "DC/Common/Colony/Warehouse/ColonyWarehouseLedgers/ColonyWarehouseLedgers"
require "DC/Common/Colony/Warehouse/DC_ColonyWarehouse_Provisioning"

return Warehouse
