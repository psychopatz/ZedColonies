require "DC/Common/Colony/Common/DC_WorkersDeposit_FlavorText"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}
DC_Colony.Network.Workers.Deposit = DC_Colony.Network.Workers.Deposit or {}

require "DC/Common/Colony/ColonyNetwork/Workers/WorkersDeposit/WorkersDeposit_Common"
require "DC/Common/Colony/ColonyNetwork/Workers/WorkersDeposit/WorkersDeposit_Notices"
require "DC/Common/Colony/ColonyNetwork/Workers/WorkersDeposit/WorkersDeposit_WorkerSupplies"
require "DC/Common/Colony/ColonyNetwork/Workers/WorkersDeposit/WorkersDeposit_WarehouseSupplies"
require "DC/Common/Colony/ColonyNetwork/Workers/WorkersDeposit/WorkersDeposit_WarehouseOutput"

return DC_Colony.Network