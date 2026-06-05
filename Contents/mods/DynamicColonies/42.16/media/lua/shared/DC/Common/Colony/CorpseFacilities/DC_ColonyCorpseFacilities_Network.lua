DC_Colony = DC_Colony or {}
DC_Colony.CorpseFacilities = DC_Colony.CorpseFacilities or {}
DC_Colony.Network = DC_Colony.Network or {}

local Config = DC_Colony.Config
local Facilities = DC_Colony.CorpseFacilities
local Network = DC_Colony.Network
local Internal = Network.Internal or {}

Network.Handlers = Network.Handlers or {}

Network.Handlers.SetCorpseFacilityRoutePreference = function(player, args)
    local owner = Config.GetOwnerUsername(player)
    Facilities.SetGeneralRoutePreference(owner, args and args.route)
    if Internal.syncBuildingsSnapshot then
        Internal.syncBuildingsSnapshot(player, owner)
    end
end

Network.Handlers.SetCorpseFacilityOverflowPolicy = function(player, args)
    local owner = Config.GetOwnerUsername(player)
    Facilities.SetTeammateOverflowPolicy(owner, args and args.policy)
    if Internal.syncBuildingsSnapshot then
        Internal.syncBuildingsSnapshot(player, owner)
    end
end

Network.Handlers.ExhumeCorpseFacilityEntry = function(player, args)
    local owner = Config.GetOwnerUsername(player)
    Facilities.ExhumeEntry(owner, args and args.buildingID, args and args.entryID)
    if Internal.syncBuildingsSnapshot then
        Internal.syncBuildingsSnapshot(player, owner)
    end
end

return Facilities
