DC_Colony = DC_Colony or {}
DC_Colony.ResidentBridge = DC_Colony.ResidentBridge or {}

local Bridge = DC_Colony.ResidentBridge
Bridge.Internal = Bridge.Internal or {}

require "DT/Common/NPC/ColonyResidents/DT_ColonyResidents"
require "DC/Common/Colony/ResidentBridge/DC_ColonyResidentBridge_Internal"
require "DC/Common/Colony/ResidentBridge/DC_ColonyResidentBridge_Anchors"
require "DC/Common/Colony/ResidentBridge/DC_ColonyResidentBridge_SoulSync"
require "DC/Common/Colony/ResidentBridge/DC_ColonyResidentBridge_Hooks"

return Bridge
