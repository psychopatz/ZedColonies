require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}
Internal.ColonyNetShared = Internal.ColonyNetShared or {}

require "DC/Common/Colony/ColonyNetwork/ColonyNetShared/DC_ColonyNetShared_Common"
require "DC/Common/Colony/ColonyNetwork/ColonyNetShared/DC_ColonyNetShared_Sanitize"
require "DC/Common/Colony/ColonyNetwork/ColonyNetShared/DC_ColonyNetShared_Versions"
require "DC/Common/Colony/ColonyNetwork/ColonyNetShared/DC_ColonyNetShared_Sync"
require "DC/Common/Colony/ColonyNetwork/ColonyNetShared/DC_ColonyNetShared_Dispatch"

return Network