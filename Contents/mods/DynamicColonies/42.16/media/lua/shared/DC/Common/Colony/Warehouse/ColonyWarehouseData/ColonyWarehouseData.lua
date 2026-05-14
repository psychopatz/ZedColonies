DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal

Internal.Data = Internal.Data or {}

require "DC/Common/Colony/Warehouse/ColonyWarehouseData/ColonyWarehouseData_Common"
require "DC/Common/Colony/Warehouse/ColonyWarehouseData/ColonyWarehouseData_Entries"
require "DC/Common/Colony/Warehouse/ColonyWarehouseData/ColonyWarehouseData_Categories"
require "DC/Common/Colony/Warehouse/ColonyWarehouseData/ColonyWarehouseData_Storage"
require "DC/Common/Colony/Warehouse/ColonyWarehouseData/ColonyWarehouseData_Recalc"
require "DC/Common/Colony/Warehouse/ColonyWarehouseData/ColonyWarehouseData_Client"

return Warehouse
