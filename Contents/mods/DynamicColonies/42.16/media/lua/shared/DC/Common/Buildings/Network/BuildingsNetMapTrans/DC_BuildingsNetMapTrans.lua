require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Network = DC_Colony.Network
local NetworkInternal = Network.Internal

Network.Handlers = Network.Handlers or {}
NetworkInternal.BuildingMap = NetworkInternal.BuildingMap or {}

local MapTransport = NetworkInternal.BuildingMap

if MapTransport.EntryLoaded then
    return Network
end

MapTransport.EntryLoaded = true
MapTransport.Modules = MapTransport.Modules or {}
MapTransport.Constants = MapTransport.Constants or {}
MapTransport.Helpers = MapTransport.Helpers or {}

require "DC/Common/Buildings/Network/BuildingsNetMapTrans/DC_BuildingsNetMapTrans_Common"
require "DC/Common/Buildings/Network/BuildingsNetMapTrans/DC_BuildingsNetMapTrans_Revisions"
require "DC/Common/Buildings/Network/BuildingsNetMapTrans/DC_BuildingsNetMapTrans_Snapshots"
require "DC/Common/Buildings/Network/BuildingsNetMapTrans/DC_BuildingsNetMapTrans_Sync"
require "DC/Common/Buildings/Network/BuildingsNetMapTrans/DC_BuildingsNetMapTrans_Mutations"

return Network
