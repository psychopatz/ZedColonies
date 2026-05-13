require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/DC_Colony_Sites"
require "DC/Common/Colony/ColonySim/DC_Colony_Sim"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DT/Common/Faction/TradingSys/DynamicTrading_Factions"
require "DT/Common/Faction/TradingSys/RosterLogic/DT_RosterLogic"
require "DT/Common/Faction/TradingSys/DynamicTrading_Stock"
require "DC/Common/Colony/Common/DC_ColonyNetRecruitment_FlavorText"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}
Network.Recruitment = Network.Recruitment or {}

require "DC/Common/Colony/ColonyNetwork/ColonyNetRecruitment/DC_ColonyNetRecruitment_Common"
require "DC/Common/Colony/ColonyNetwork/ColonyNetRecruitment/DC_ColonyNetRecruitment_Source"
require "DC/Common/Colony/ColonyNetwork/ColonyNetRecruitment/DC_ColonyNetRecruitment_Departure"
require "DC/Common/Colony/ColonyNetwork/ColonyNetRecruitment/DC_ColonyNetRecruitment_Finalize"
require "DC/Common/Colony/ColonyNetwork/ColonyNetRecruitment/DC_ColonyNetRecruitment_Attempt"

return Network