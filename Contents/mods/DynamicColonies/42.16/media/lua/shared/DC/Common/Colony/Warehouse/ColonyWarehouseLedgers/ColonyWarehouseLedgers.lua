DC_Colony = DC_Colony or {}
DC_Colony.Warehouse = DC_Colony.Warehouse or {}
DC_Colony.Warehouse.Internal = DC_Colony.Warehouse.Internal or {}

local Warehouse = DC_Colony.Warehouse
local Internal = Warehouse.Internal

Internal.Ledgers = Internal.Ledgers or {}

require "DC/Common/Colony/Warehouse/ColonyWarehouseLedgers/ColonyWarehouseLedgers_Append"
require "DC/Common/Colony/Warehouse/ColonyWarehouseLedgers/ColonyWarehouseLedgers_Builders"
require "DC/Common/Colony/Warehouse/ColonyWarehouseLedgers/ColonyWarehouseLedgers_Deposit"
require "DC/Common/Colony/Warehouse/ColonyWarehouseLedgers/ColonyWarehouseLedgers_Take"
require "DC/Common/Colony/Warehouse/ColonyWarehouseLedgers/ColonyWarehouseLedgers_Medical"

return Warehouse