DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Internal = DC_Colony.Network.Internal
local Transport = Internal.Transport or {}

function Internal.pushOwnerBuildingMutation(ownerUsername, context)
    local owner = Transport.getOwnerUsername(ownerUsername)
    if Internal.BuildingMap and Internal.BuildingMap.PushOwnerMutation then
        Internal.BuildingMap.PushOwnerMutation(owner, context or {})
        return
    end

    local sent = Internal.forEachOnlineOwnerPlayer(owner, function(player)
        if context and context.promptBuildingName and Internal.sendResponse then
            Internal.sendResponse(player, ((DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony"), "PromptBuildingName", context.promptBuildingName)
        end
        if context and context.promptOwnedFactionRename and Internal.sendResponse then
            Internal.sendResponse(player, "DynamicTrading_V2", "PromptOwnedFactionRename", context.promptOwnedFactionRename)
        end
        if context and context.notice then
            Internal.syncNotice(player, context.notice.message, context.notice.severity, context.notice.popup)
        end
        if context and context.workerID then
            Internal.syncWorkerUpdated(player, owner, context.workerID)
        end
        if context and context.sendWorkerList ~= false then
            Internal.syncWorkerListFocused(player, owner)
        end
        if context and context.plotX ~= nil and context.plotY ~= nil then
            Internal.syncBuildingState(player, owner, context.plotX, context.plotY, {
                sourcePlayer = player,
            })
        end
        if context and type(context.additionalPlots) == "table" then
            for _, coord in ipairs(context.additionalPlots) do
                if coord and coord.x ~= nil and coord.y ~= nil then
                    Internal.syncBuildingState(player, owner, coord.x, coord.y, {
                        sourcePlayer = player,
                    })
                end
            end
        end
        if context and context.transition and context.transition.safetyChanged == true then
            Internal.syncPlotSafety(player, owner, context.transition)
        end
        if context and context.sendFactionStatus == true then
            Internal.syncFactionStatusSummary(player, owner)
        end
    end)

    if sent <= 0 and context and context.notice and Transport.isDebugTransportEnabled(nil) then
        Transport.logTransport("Info", "No online owner client to receive mutation for " .. tostring(owner))
    end
end

return Transport
