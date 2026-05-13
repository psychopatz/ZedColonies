require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Internal = DC_Colony.Network.Internal

Internal.Transport = Internal.Transport or {}

require "DC/Common/Colony/ColonyNetwork/ColonyNetTransport/DC_ColonyNetTransport_Common"
require "DC/Common/Colony/ColonyNetwork/ColonyNetTransport/DC_ColonyNetTransport_Sanitize"
require "DC/Common/Colony/ColonyNetwork/ColonyNetTransport/DC_ColonyNetTransport_Versions"
require "DC/Common/Colony/ColonyNetwork/ColonyNetTransport/DC_ColonyNetTransport_Snapshots"
require "DC/Common/Colony/ColonyNetwork/ColonyNetTransport/DC_ColonyNetTransport_Sync"
require "DC/Common/Colony/ColonyNetwork/ColonyNetTransport/DC_ColonyNetTransport_Mutations"

return DC_Colony.Network