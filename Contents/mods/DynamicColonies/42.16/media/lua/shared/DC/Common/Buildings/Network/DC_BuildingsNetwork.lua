require "DC/Common/Buildings/Core/DC_Buildings"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

require "DC/Common/Buildings/Network/DC_BuildingsNetwork_Shared"
require "DC/Common/Buildings/Network/DC_BuildingsNetwork_Query"
require "DC/Common/Buildings/Network/DC_BuildingsNetwork_MapTransport"
require "DC/Common/Buildings/Network/DC_BuildingsNetwork_Projects"
require "DC/Common/Buildings/Network/DC_BuildingsNetwork_Supply"
require "DC/Common/Buildings/Network/DC_BuildingsNetwork_Destroy"
require "DC/Common/Buildings/Network/DC_BuildingsNetwork_Debug"

return DC_Colony.Network
