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

Network.Handlers.CraftBuildingBlueprint = function(player, args)
    if not args or not args.buildingType then
        return
    end

    local owner = ColonyConfig.GetOwnerUsername(player)
    local ok = false
    local reason = "Blueprint crafting is unavailable."
    local definition = nil
    if Buildings.CraftBlueprintFromPlayer then
        ok, reason, definition = Buildings.CraftBlueprintFromPlayer(
            owner,
            player,
            args.buildingType,
            args.mode,
            args.plotX,
            args.plotY,
            args.buildingID,
            args.installKey
        )
    end

    if Internal.syncNotice then
        if ok ~= true then
            Internal.syncNotice(player, reason or "Unable to craft that blueprint.", "error", true)
        else
            Internal.syncNotice(
                player,
                tostring(definition and definition.displayName or "Blueprint") .. " crafted and added to your inventory.",
                "info",
                true
            )
        end
    end

    if Internal.syncBuildingsSnapshot then
        Internal.syncBuildingsSnapshot(player, owner)
    end
end

return Network
