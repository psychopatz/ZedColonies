DC_Colony = DC_Colony or {}
DC_Colony.AbstractInventory = DC_Colony.AbstractInventory or {}
DC_Colony.AbstractInventory.Internal = DC_Colony.AbstractInventory.Internal or {}

local AbstractInventory = DC_Colony.AbstractInventory

require "DC/Common/Colony/AbstractInventory/AbstractInventoryData/DC_AbstractInventoryData_Common"
require "DC/Common/Colony/AbstractInventory/AbstractInventoryData/DC_AbstractInventoryData_Storage"
require "DC/Common/Colony/AbstractInventory/AbstractInventoryData/DC_AbstractInventoryData_Entries"
require "DC/Common/Colony/AbstractInventory/AbstractInventoryData/DC_AbstractInventoryData_Client"

return AbstractInventory
