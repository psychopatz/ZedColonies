DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Network = DC_Colony.Network
local NetworkInternal = Network.Internal
local ColonyConfig = DC_Colony.Config or {}

Network.Handlers = Network.Handlers or {}
NetworkInternal.BuildingMap = NetworkInternal.BuildingMap or {}

local MapTransport = NetworkInternal.BuildingMap
local modules = MapTransport.Modules or {}
local helpers = MapTransport.Helpers or {}

MapTransport.Modules = modules
MapTransport.Helpers = helpers

if modules.Mutations then
    return
end

modules.Mutations = true

function MapTransport.PushOwnerMutation(ownerUsername, context)
    local owner = helpers.GetOwnerUsername(ownerUsername)
    local mapChange = context and context.mapChange or MapTransport.Touch(owner, context or {})
    local coords = context and context.coords or helpers.CollectAffectedCoords(owner, context or {})
    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    local primaryKey = context and context.plotX ~= nil and context.plotY ~= nil and helpers.GetPlotKey(context.plotX, context.plotY) or nil
    local secondaryCoords = {}

    for _, coord in ipairs(coords or {}) do
        local key = helpers.GetPlotKey(coord and coord.x, coord and coord.y)
        if key ~= primaryKey then
            secondaryCoords[#secondaryCoords + 1] = coord
        end
    end

    if not onlinePlayers then
        return mapChange
    end

    for index = 0, onlinePlayers:size() - 1 do
        local player = onlinePlayers:get(index)
        if player and helpers.GetOwnerUsername(player) == owner then
            if context and context.promptBuildingName and NetworkInternal.sendResponse then
                NetworkInternal.sendResponse(player, ColonyConfig.COMMAND_MODULE or "DColony", "PromptBuildingName", context.promptBuildingName)
            end
            if context and context.promptOwnedFactionRename and NetworkInternal.sendResponse then
                NetworkInternal.sendResponse(player, "DynamicTrading_V2", "PromptOwnedFactionRename", context.promptOwnedFactionRename)
            end
            if context and context.notice and NetworkInternal.syncNotice then
                NetworkInternal.syncNotice(player, context.notice.message, context.notice.severity, context.notice.popup)
            end
            if context and context.workerID and NetworkInternal.syncWorkerUpdated then
                NetworkInternal.syncWorkerUpdated(player, owner, context.workerID)
            end
            if context and context.sendWorkerList ~= false and NetworkInternal.syncWorkerListFocused then
                NetworkInternal.syncWorkerListFocused(player, owner)
            end

            if context and context.plotX ~= nil and context.plotY ~= nil then
                MapTransport.SyncPlotUpdated(player, owner, context.plotX, context.plotY, {
                    sourcePlayer = player,
                    mapChange = mapChange,
                })
            end

            if context and context.transition and context.transition.safetyChanged == true then
                MapTransport.SyncPlotsUpdated(player, owner, coords, {
                    sourcePlayer = player,
                    mapChange = mapChange,
                    reason = "plot-safety",
                })
            elseif #secondaryCoords > 0 then
                MapTransport.SyncPlotsUpdated(player, owner, secondaryCoords, {
                    sourcePlayer = player,
                    mapChange = mapChange,
                    reason = "owner-mutation",
                })
            elseif not (context and context.plotX ~= nil and context.plotY ~= nil) and #coords > 0 then
                MapTransport.SyncPlotsUpdated(player, owner, coords, {
                    sourcePlayer = player,
                    mapChange = mapChange,
                    reason = "owner-mutation",
                })
            end

            if context and context.sendFactionStatus == true and NetworkInternal.syncFactionStatusSummary then
                NetworkInternal.syncFactionStatusSummary(player, owner)
            end
        end
    end

    return mapChange
end

Network.Handlers.RequestBuildingMapOpen = function(player, args)
    MapTransport.SyncOpen(player, player, args or {})
end

Network.Handlers.RequestBuildingMapRetry = function(player, args)
    local payload = args or {}
    payload.forceFull = true
    MapTransport.SyncOpen(player, player, payload)
end

Network.Handlers.RequestBuildingPlots = function(player, args)
    MapTransport.SyncPlots(player, player, args or {})
end
