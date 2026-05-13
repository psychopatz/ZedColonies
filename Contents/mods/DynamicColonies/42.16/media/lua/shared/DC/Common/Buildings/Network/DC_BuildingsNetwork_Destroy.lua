require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local ColonyConfig = DC_Colony.Config
local Network = DC_Colony.Network
local Buildings = DC_Buildings
local Internal = Network.Internal

Network.Handlers = Network.Handlers or {}

Network.Handlers.DestroyBuilding = function(player, args)
    if not args or args.plotX == nil or args.plotY == nil then
        return
    end

    local owner = ColonyConfig.GetOwnerUsername(player)
    local ok, reason, building = Buildings.DestroyBuilding(owner, args.plotX, args.plotY, args.buildingID)

    if not ok then
        if Internal.syncNotice then
            Internal.syncNotice(player, reason or "Unable to destroy building.", "error", true)
        end
        if Internal.syncBuildingState and args.plotX ~= nil and args.plotY ~= nil then
            Internal.syncBuildingState(player, owner, args.plotX, args.plotY, {
                sourcePlayer = player,
            })
        end
        return
    end

    if Internal.syncWorkerList then
        Internal.syncWorkerList(player)
    end
    if Internal.syncNotice then
        Internal.syncNotice(
            player,
            "Destroyed " .. tostring(building and (building.buildingType or building.displayName) or "building") .. ".",
            "info",
            false
        )
    end
    if Internal.syncBuildingState then
        Internal.syncBuildingState(player, owner, args.plotX, args.plotY, {
            sourcePlayer = player,
        })
    end
end

return Network
