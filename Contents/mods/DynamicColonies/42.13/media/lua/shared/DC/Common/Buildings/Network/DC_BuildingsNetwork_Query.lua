require "DC/Common/Buildings/Core/DC_Buildings"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Network = DC_Colony.Network
local Internal = Network.Internal

Network.Handlers = Network.Handlers or {}

Network.Handlers.RequestBuildingsSnapshot = function(player, args)
    if Internal.syncBuildingsSnapshot then
        Internal.syncBuildingsSnapshot(player, player, args and args.knownVersion)
    end
end

Network.Handlers.RequestOwnerBuildings = Network.Handlers.RequestBuildingsSnapshot

Network.Handlers.RequestBuildingProjectPreview = function(player, args)
    if not args or not args.buildingType then
        return
    end
    if Internal.syncProjectPreview then
        Internal.syncProjectPreview(player, player, args.buildingType, args.mode, args.plotX, args.plotY, args.buildingID, args.installKey)
    end
end

return Network
