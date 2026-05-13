require "DC/Common/Colony/Common/DC_WorkersEquipment_FlavorText"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}
DC_Colony.Network.Workers.Equipment = DC_Colony.Network.Workers.Equipment or {}

require "DC/Common/Colony/ColonyNetwork/Workers/WorkersEquipment/WorkersEquipment_Common"
require "DC/Common/Colony/ColonyNetwork/Workers/WorkersEquipment/WorkersEquipment_Requirements"
require "DC/Common/Colony/ColonyNetwork/Workers/WorkersEquipment/WorkersEquipment_Capacity"
require "DC/Common/Colony/ColonyNetwork/Workers/WorkersEquipment/WorkersEquipment_Messages"
require "DC/Common/Colony/ColonyNetwork/Workers/WorkersEquipment/WorkersEquipment_Assignment"
require "DC/Common/Colony/ColonyNetwork/Workers/WorkersEquipment/WorkersEquipment_AutoEquip"

return DC_Colony.Network