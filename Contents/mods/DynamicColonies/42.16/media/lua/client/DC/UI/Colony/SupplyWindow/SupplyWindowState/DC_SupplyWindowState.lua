DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

-- Keep explicit load order so state helpers exist before dependent modules.
require "DC/UI/Colony/SupplyWindow/SupplyWindowState/DC_SupplyWindowState_Selection"
require "DC/UI/Colony/SupplyWindow/SupplyWindowState/DC_SupplyWindowState_Player"
require "DC/UI/Colony/SupplyWindow/SupplyWindowState/WorkerModes/DC_SupplyWindowState_WorkerCompanion"
require "DC/UI/Colony/SupplyWindow/SupplyWindowState/WorkerModes/DC_SupplyWindowState_WorkerWarehouse"
require "DC/UI/Colony/SupplyWindow/SupplyWindowState/DC_SupplyWindowState_WarehouseInventory"
require "DC/UI/Colony/SupplyWindow/SupplyWindowState/DC_SupplyWindowState_Worker"
require "DC/UI/Colony/SupplyWindow/SupplyWindowState/DC_SupplyWindowState_Optimistic"
require "DC/UI/Colony/SupplyWindow/SupplyWindowState/DC_SupplyWindowState_Scan"
require "DC/UI/Colony/SupplyWindow/SupplyWindowState/DC_SupplyWindowState_Update"
