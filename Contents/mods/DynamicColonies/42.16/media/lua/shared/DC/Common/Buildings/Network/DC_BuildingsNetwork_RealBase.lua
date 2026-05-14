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

Network.Handlers.SetBuildingCustomName = function(player, args)
    if not args or not args.buildingID then
        return
    end

    local owner = ColonyConfig.GetOwnerUsername and ColonyConfig.GetOwnerUsername(player) or tostring(player or "local")
    local api = Buildings and Buildings.RealBase or nil
    local ok, reason, instance = false, "Unable to rename that building.", nil
    if api and api.SetInstanceCustomName then
        ok, reason, instance = api.SetInstanceCustomName(owner, args.buildingID, args.customName)
    end
    if not ok then
        if Internal.syncNotice then
            Internal.syncNotice(player, reason or "Unable to rename that building.", "error", true)
        end
        return
    end

    if Internal.syncNotice then
        Internal.syncNotice(player, "Named building as " .. tostring(instance and instance.customName or "Building") .. ".", "info", false)
    end
    if Internal.sendResponse then
        Internal.sendResponse(player, ColonyConfig.COMMAND_MODULE or "DColony", "SyncBuildingCustomName", {
            buildingID = tostring(instance and instance.buildingID or args.buildingID or ""),
            customName = tostring(instance and instance.customName or ""),
        })
    end
    if Internal.pushOwnerBuildingMutation and instance then
        Internal.pushOwnerBuildingMutation(owner, {
            plotX = instance.plotX,
            plotY = instance.plotY,
            sendWorkerList = false,
            sendFactionStatus = false,
        })
    end
end

return Network
