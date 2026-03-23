require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/ZedColonies/LabourNutrition/DT_LabourNutrition"

DT_Labour = DT_Labour or {}
DT_Labour.Warehouse = DT_Labour.Warehouse or {}
DT_Labour.Warehouse.Internal = DT_Labour.Warehouse.Internal or {}

local Warehouse = DT_Labour.Warehouse

require "DT/Common/ZedColonies/Warehouse/DT_LabourWarehouse_Data"
require "DT/Common/ZedColonies/Warehouse/DT_LabourWarehouse_Ledgers"
require "DT/Common/ZedColonies/Warehouse/DT_LabourWarehouse_Provisioning"

return Warehouse
