require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Buildings/Core/DC_Buildings"
require "DC/Common/Colony/Resources/ColonyResources/DC_ColonyResources"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Internal = DC_Colony.Network.Internal or {}

local Config = DC_Colony.Config or {}
local Registry = DC_Colony.Registry or {}
local Buildings = DC_Buildings or {}
local Resources = DC_Colony.Resources or {}
local Internal = DC_Colony.Network.Internal

Internal.Transport = Internal.Transport or {}

local Transport = Internal.Transport

Transport.MAX_DEBUG_PACKET_SIZE = Transport.MAX_DEBUG_PACKET_SIZE or 24000
Transport.Domains = Transport.Domains or {
    ColonyBootstrap = "Bootstrap",
    BuildingStateUpdated = "Building",
    PlotSafetyChanged = "Building",
    WorkerUpdated = "Worker",
    WorkerListUpdated = "Worker",
    WarehouseSummaryUpdated = "Warehouse",
    ResourcesSummaryUpdated = "Resources",
    FactionStatusSummary = "FactionStatus",
    ColonyNotice = "Notice",
}

local function logTransport(level, message)
    if DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DynamicColonies", "Network", level or "Info", tostring(message or ""))
    elseif print then
        print("[DynamicColonies][Network][" .. tostring(level or "Info") .. "] " .. tostring(message or ""))
    end
end

local function isDebugTransportEnabled(player)
    if DynamicTrading and DynamicTrading.Debug then
        return true
    end
    if isDebugEnabled and isDebugEnabled() then
        return true
    end
    if player and player.getAccessLevel then
        local accessLevel = tostring(player:getAccessLevel() or "")
        if accessLevel ~= "" and accessLevel ~= "None" then
            return true
        end
    end
    return false
end

local function sanitizeKey(key)
    local keyType = type(key)
    if keyType == "string" or keyType == "number" then
        return key
    end
    if keyType == "boolean" then
        return tostring(key)
    end
    return nil
end

local function sanitizeValue(value, seen, depth, stats, path)
    local valueType = type(value)
    if valueType == "nil" then
        return nil
    end
    if valueType == "string" or valueType == "boolean" then
        return value
    end
    if valueType == "number" then
        if value ~= value then
            if stats then
                stats.dropped = stats.dropped + 1
            end
            return 0
        end
        return value
    end
    if valueType == "userdata" then
        return tostring(value)
    end
    if valueType ~= "table" then
        if stats then
            stats.dropped = stats.dropped + 1
            stats.paths[#stats.paths + 1] = tostring(path or "<root>")
        end
        return nil
    end

    local safeDepth = math.floor(tonumber(depth) or 0)
    if safeDepth > 24 then
        if stats then
            stats.dropped = stats.dropped + 1
            stats.paths[#stats.paths + 1] = tostring(path or "<root>") .. ":depth"
        end
        return nil
    end

    seen = seen or {}
    if seen[value] then
        if stats then
            stats.dropped = stats.dropped + 1
            stats.paths[#stats.paths + 1] = tostring(path or "<root>") .. ":cycle"
        end
        return nil
    end
    seen[value] = true

    local copy = {}
    for key, child in pairs(value) do
        local safeKey = sanitizeKey(key)
        if safeKey == nil then
            if stats then
                stats.dropped = stats.dropped + 1
                stats.paths[#stats.paths + 1] = tostring(path or "<root>") .. ".<key>"
            end
        else
            local childPath = tostring(path or "<root>") .. "." .. tostring(safeKey)
            local safeChild = sanitizeValue(child, seen, safeDepth + 1, stats, childPath)
            if safeChild ~= nil then
                copy[safeKey] = safeChild
            end
        end
    end

    seen[value] = nil
    return copy
end

local function estimatePayloadSize(value, seen)
    local valueType = type(value)
    if valueType == "nil" then
        return 0
    end
    if valueType == "number" or valueType == "boolean" then
        return #tostring(value)
    end
    if valueType == "string" then
        return #value
    end
    if valueType ~= "table" then
        return #tostring(value)
    end

    seen = seen or {}
    if seen[value] then
        return 0
    end
    seen[value] = true

    local total = 2
    for key, child in pairs(value) do
        total = total + #tostring(key) + estimatePayloadSize(child, seen)
    end

    seen[value] = nil
    return total
end

local function copyShallow(source)
    if type(source) ~= "table" then
        return source
    end
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

local function copyArray(source)
    local copy = {}
    for _, value in ipairs(source or {}) do
        if type(value) == "table" then
            copy[#copy + 1] = copyShallow(value)
        else
            copy[#copy + 1] = value
        end
    end
    return copy
end

local function getOwnerUsername(subject)
    if Config.GetOwnerUsername then
        return Config.GetOwnerUsername(subject)
    end
    if type(subject) == "table" and subject.getUsername then
        return tostring(subject:getUsername() or "local")
    end
    return tostring(subject or "local")
end

local function getBuildingVersion(ownerUsername)
    local ownerData = Buildings.EnsureOwner and Buildings.EnsureOwner(ownerUsername) or nil
    return math.max(1, math.floor(tonumber(ownerData and ownerData.version) or 1))
end

local function getWorkerListVersion(ownerUsername)
    local workersData = Registry.GetWorkersData and Registry.GetWorkersData(ownerUsername, false) or nil
    if workersData and workersData.version then
        return math.max(1, math.floor(tonumber(workersData.version) or 1))
    end
    local colonyData = Registry.GetColonyData and Registry.GetColonyData(ownerUsername, false) or nil
    local versions = colonyData and colonyData.versions or nil
    return math.max(1, math.floor(tonumber(versions and versions.workers) or 1))
end

local function getWorkerDetailVersion(worker)
    return math.max(1, math.floor(tonumber(worker and worker.detailVersion) or 1))
end

local function getWarehouseSummaryVersion(ownerUsername)
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    local summary = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(ownerUsername) or nil
    return math.max(1, math.floor(tonumber(summary and summary.version) or 1))
end

local function getWarehouseItemsVersion(ownerUsername)
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    local summary = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(ownerUsername) or nil
    return math.max(1, math.floor(tonumber(summary and summary.itemsVersion) or 1))
end

local function getResourcesVersion(ownerUsername)
    local ownerData = Resources.EnsureOwner and Resources.EnsureOwner(ownerUsername) or nil
    return math.max(1, math.floor(tonumber(ownerData and ownerData.version) or 1))
end

local function buildFactionStatusSummary(ownerUsername)
    if not DynamicTrading_Factions or not DynamicTrading_Factions.GetOwnedFactionStatus then
        return {
            ownerUsername = ownerUsername,
            authorityOwner = ownerUsername,
            canCreate = false,
            workerCount = 0,
            faction = nil,
            memberUsernames = {},
            createBlockedReason = "factions_unavailable",
        }
    end

    local fullStatus = DynamicTrading_Factions.GetOwnedFactionStatus(ownerUsername) or {}
    local faction = type(fullStatus.faction) == "table" and fullStatus.faction or nil
    local memberUsernames = copyArray(fullStatus.memberUsernames or (faction and faction.memberUsernames) or {})

    return {
        ownerUsername = fullStatus.ownerUsername or ownerUsername,
        memberUsername = fullStatus.memberUsername or ownerUsername,
        authorityOwner = fullStatus.authorityOwner or ownerUsername,
        canCreate = fullStatus.canCreate == true,
        workerCount = math.max(0, math.floor(tonumber(fullStatus.workerCount) or 0)),
        role = fullStatus.role,
        isLeader = fullStatus.isLeader == true,
        isMember = fullStatus.isMember == true,
        createBlockedReason = fullStatus.createBlockedReason,
        memberUsernames = memberUsernames,
        faction = faction and {
            id = faction.id,
            name = faction.name,
            leaderUsername = faction.leaderUsername,
            authorityOwner = faction.authorityOwner or fullStatus.authorityOwner or faction.leaderUsername,
            leadershipState = faction.leadershipState,
            homeCoords = type(faction.homeCoords) == "table" and {
                x = faction.homeCoords.x,
                y = faction.homeCoords.y,
                z = faction.homeCoords.z,
            } or nil,
            memberUsernames = copyArray(faction.memberUsernames),
        } or nil,
    }
end

local function getFactionStatusVersion(ownerUsername)
    local summary = buildFactionStatusSummary(ownerUsername)
    local faction = summary.faction or {}
    return table.concat({
        tostring(summary.authorityOwner or ownerUsername),
        tostring(faction.id or "none"),
        tostring(faction.leadershipState or "none"),
        tostring(#(summary.memberUsernames or {})),
        tostring(summary.workerCount or 0),
        tostring(getBuildingVersion(ownerUsername)),
        tostring(getWorkerListVersion(ownerUsername)),
    }, ":")
end

local function buildResourcesSummary(ownerUsername)
    local snapshot = Resources.GetClientSnapshot and Resources.GetClientSnapshot(ownerUsername) or nil
    if type(snapshot) ~= "table" then
        return {
            ownerUsername = ownerUsername,
            categories = {},
            water = nil,
        }
    end

    local water = snapshot.water or {}
    return {
        ownerUsername = ownerUsername,
        categories = copyArray(snapshot.categories),
        water = {
            stored = tonumber(water.stored) or 0,
            capacity = tonumber(water.capacity) or 0,
            available = tonumber(water.available) or 0,
            baseCollectionRatePerHour = tonumber(water.baseCollectionRatePerHour) or 0,
            activeCollectionRatePerHour = tonumber(water.activeCollectionRatePerHour) or 0,
            raining = water.raining == true,
            rainIntensity = tonumber(water.rainIntensity) or 0,
            outdoorTemperatureC = tonumber(water.outdoorTemperatureC) or 0,
            dailyDemand = tonumber(water.dailyDemand) or 0,
            collectorCount = #(water.collectors or {}),
            tankCount = #(water.tanks or {}),
            greenhouseCount = #(water.greenhouses or {}),
        },
    }
end

local function buildVersions(ownerUsername)
    return {
        building = getBuildingVersion(ownerUsername),
        workerList = getWorkerListVersion(ownerUsername),
        warehouseSummary = getWarehouseSummaryVersion(ownerUsername),
        warehouseItems = getWarehouseItemsVersion(ownerUsername),
        resources = getResourcesVersion(ownerUsername),
        factionStatus = getFactionStatusVersion(ownerUsername),
    }
end

local function findPlotEntryByCoords(mapSnapshot, plotX, plotY)
    for _, plot in ipairs(mapSnapshot and mapSnapshot.plots or {}) do
        if math.floor(tonumber(plot.x) or 0) == math.floor(tonumber(plotX) or 0)
            and math.floor(tonumber(plot.y) or 0) == math.floor(tonumber(plotY) or 0) then
            return plot
        end
    end
    return nil
end

local function buildMapMeta(mapSnapshot)
    local map = mapSnapshot or {}
    return {
        bounds = copyShallow(map.bounds),
        headquartersLevel = tonumber(map.headquartersLevel) or 0,
        securedPerimeterRing = tonumber(map.securedPerimeterRing) or 0,
        currentFrontierRing = tonumber(map.currentFrontierRing) or 0,
        nextFrontierRing = tonumber(map.nextFrontierRing) or 0,
        frontierExpansionAvailable = map.frontierExpansionAvailable == true,
        frontierRequiredHQLevel = tonumber(map.frontierRequiredHQLevel) or 0,
        unlockedPlotCount = tonumber(map.unlockedPlotCount) or 0,
        activeBarricadeCount = tonumber(map.activeBarricadeCount) or 0,
        maxActiveBarricades = tonumber(map.maxActiveBarricades) or 0,
    }
end

local function buildPlotPacket(ownerUsername, plotX, plotY, sourcePlayer)
    local mapSnapshot = Buildings.BuildMapSnapshot and Buildings.BuildMapSnapshot(ownerUsername, sourcePlayer) or { plots = {} }
    return findPlotEntryByCoords(mapSnapshot, plotX, plotY), buildMapMeta(mapSnapshot)
end

local function buildPlotsPacket(ownerUsername, coords, sourcePlayer)
    local mapSnapshot = Buildings.BuildMapSnapshot and Buildings.BuildMapSnapshot(ownerUsername, sourcePlayer) or { plots = {} }
    local plots = {}
    local seen = {}
    for _, coord in ipairs(coords or {}) do
        local key = tostring(math.floor(tonumber(coord and coord.x) or 0)) .. ":" .. tostring(math.floor(tonumber(coord and coord.y) or 0))
        if not seen[key] then
            seen[key] = true
            local plot = findPlotEntryByCoords(mapSnapshot, coord.x, coord.y)
            if plot then
                plots[#plots + 1] = plot
            end
        end
    end
    table.sort(plots, function(a, b)
        if tonumber(a.y) == tonumber(b.y) then
            return tonumber(a.x) < tonumber(b.x)
        end
        return tonumber(a.y) < tonumber(b.y)
    end)
    return plots, buildMapMeta(mapSnapshot)
end

local function buildWorkerSummary(worker)
    if not worker then
        return nil
    end
    return Registry.GetWorkerSummaryForOwner and Registry.GetWorkerSummaryForOwner(worker.ownerUsername, worker.workerID)
        or Registry.GetWorkerDetailsForOwner and Registry.GetWorkerDetailsForOwner(worker.ownerUsername, worker.workerID, false, false)
        or nil
end

local function findWorker(ownerUsername, workerID)
    return Registry.GetWorkerForOwner and Registry.GetWorkerForOwner(ownerUsername, workerID)
        or Registry.GetWorkerForOwnerRaw and Registry.GetWorkerForOwnerRaw(ownerUsername, workerID)
        or nil
end

local function getWorkerDetailForPacket(ownerUsername, workerID)
    return Registry.GetWorkerDetailsForOwner and Registry.GetWorkerDetailsForOwner(ownerUsername, workerID, false, false) or nil
end

function Internal.sanitizeNetworkArgs(args)
    local stats = {
        dropped = 0,
        paths = {},
    }
    local safeArgs = sanitizeValue(args or {}, nil, 0, stats, "root")
    if type(safeArgs) ~= "table" then
        safeArgs = {}
    end
    return safeArgs, stats
end

function Internal.sendResponse(player, module, command, args)
    local safeArgs = Internal.sanitizeNetworkArgs and select(1, Internal.sanitizeNetworkArgs(args)) or (args or {})
    if DynamicTrading and DynamicTrading.ServerHelpers and DynamicTrading.ServerHelpers.SendResponse then
        DynamicTrading.ServerHelpers.SendResponse(player, module, command, safeArgs)
        return
    end

    if isServer() then
        sendServerCommand(player, module, command, safeArgs)
    else
        triggerEvent("OnServerCommand", module, command, safeArgs)
    end
end

function Internal.sendTransportPacket(player, command, ownerUsername, payload)
    local domain = Transport.Domains[command]
    if not domain then
        logTransport("Warn", "Blocked non-whitelisted colony packet: " .. tostring(command))
        return false
    end

    local args = payload or {}
    args.ownerUsername = args.ownerUsername or ownerUsername
    args.domain = args.domain or domain

    local safeArgs, stats = Internal.sanitizeNetworkArgs(args)
    local estimatedSize = estimatePayloadSize(safeArgs)
    local debugEnabled = isDebugTransportEnabled(player)

    if debugEnabled and estimatedSize > Transport.MAX_DEBUG_PACKET_SIZE then
        logTransport(
            "Warn",
            "Rejected oversize colony packet command=" .. tostring(command)
                .. " owner=" .. tostring(ownerUsername or "unknown")
                .. " size=" .. tostring(estimatedSize)
        )
        return false
    end

    if debugEnabled then
        logTransport(
            "Info",
            "send command=" .. tostring(command)
                .. " domain=" .. tostring(domain)
                .. " owner=" .. tostring(ownerUsername or "unknown")
                .. " version=" .. tostring(safeArgs.version or "n/a")
                .. " size=" .. tostring(estimatedSize)
                .. " dropped=" .. tostring(stats and stats.dropped or 0)
        )
    end

    Internal.sendResponse(player, Config.COMMAND_MODULE or "DColony", command, safeArgs)
    return true
end

function Internal.forEachOnlineOwnerPlayer(ownerUsername, callback)
    local owner = getOwnerUsername(ownerUsername)
    if owner == "" then
        return 0
    end

    local handled = 0
    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for index = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(index)
            if player and getOwnerUsername(player) == owner then
                handled = handled + 1
                callback(player)
            end
        end
    end
    return handled
end

function Internal.syncNotice(player, message, severity, popup)
    Internal.sendTransportPacket(player, "ColonyNotice", getOwnerUsername(player), {
        message = tostring(message or ""),
        severity = severity or "info",
        popup = popup == true,
    })
end

function Internal.syncFactionStatusSummary(player, ownerUsername)
    local owner = getOwnerUsername(ownerUsername or player)
    local status = buildFactionStatusSummary(owner)
    Internal.sendTransportPacket(player, "FactionStatusSummary", owner, {
        version = getFactionStatusVersion(owner),
        status = status,
    })
end

function Internal.syncWarehouseSummaryUpdated(player, ownerUsername)
    local owner = getOwnerUsername(ownerUsername or player)
    local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
    Internal.sendTransportPacket(player, "WarehouseSummaryUpdated", owner, {
        version = getWarehouseSummaryVersion(owner),
        warehouse = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(owner) or nil,
    })
end

function Internal.syncResourcesSummaryUpdated(player, ownerUsername)
    local owner = getOwnerUsername(ownerUsername or player)
    Internal.sendTransportPacket(player, "ResourcesSummaryUpdated", owner, {
        version = getResourcesVersion(owner),
        snapshot = buildResourcesSummary(owner),
    })
end

function Internal.syncWorkerListFocused(player, ownerUsername)
    local owner = getOwnerUsername(ownerUsername or player)
    Internal.sendTransportPacket(player, "WorkerListUpdated", owner, {
        version = getWorkerListVersion(owner),
        workers = Registry.GetWorkerSummariesForOwner and Registry.GetWorkerSummariesForOwner(owner) or {},
    })
end

function Internal.syncWorkerUpdated(player, ownerUsername, workerID)
    local owner = getOwnerUsername(ownerUsername or player)
    local worker = findWorker(owner, workerID)
    local detail = worker and getWorkerDetailForPacket(owner, worker.workerID) or nil
    local summary = worker and buildWorkerSummary(worker) or nil
    Internal.sendTransportPacket(player, "WorkerUpdated", owner, {
        version = getWorkerDetailVersion(detail or worker),
        listVersion = getWorkerListVersion(owner),
        workerID = workerID,
        workerSummary = summary,
        worker = detail,
    })
end

function Internal.syncBuildingState(player, ownerUsername, plotX, plotY, options)
    local owner = getOwnerUsername(ownerUsername or player)
    if Internal.BuildingMap and Internal.BuildingMap.SyncPlotUpdated then
        Internal.BuildingMap.SyncPlotUpdated(player, owner, plotX, plotY, options or {})
        return
    end

    local plot, map = buildPlotPacket(owner, plotX, plotY, options and options.sourcePlayer or player)
    Internal.sendTransportPacket(player, "BuildingStateUpdated", owner, {
        version = getBuildingVersion(owner),
        plotKey = plot and plot.key or (Buildings.GetPlotKey and Buildings.GetPlotKey(plotX, plotY) or nil),
        plotX = math.floor(tonumber(plotX) or 0),
        plotY = math.floor(tonumber(plotY) or 0),
        plot = plot,
        map = map,
    })
end

function Internal.syncPlotSafety(player, ownerUsername, changeInfo)
    local owner = getOwnerUsername(ownerUsername or player)
    local coords = {}

    if type(changeInfo and changeInfo.affectedCoords) == "table" then
        coords = changeInfo.affectedCoords
    elseif changeInfo and changeInfo.plotX ~= nil and changeInfo.plotY ~= nil then
        coords[1] = {
            x = changeInfo.plotX,
            y = changeInfo.plotY,
        }
    end

    if #coords <= 0 and Buildings.GetRingCoordinates and tonumber(changeInfo and changeInfo.securedRingAfter) then
        coords = Buildings.GetRingCoordinates(changeInfo.securedRingAfter)
    end

    if Internal.BuildingMap and Internal.BuildingMap.SyncPlotsUpdated then
        Internal.BuildingMap.SyncPlotsUpdated(player, owner, coords, {
            sourcePlayer = player,
            reason = "plot-safety",
            mapChange = changeInfo and changeInfo.mapChange or nil,
        })
        return
    end

    local plots, map = buildPlotsPacket(owner, coords, player)
    Internal.sendTransportPacket(player, "PlotSafetyChanged", owner, {
        version = getBuildingVersion(owner),
        ring = tonumber(changeInfo and changeInfo.securedRingAfter) or tonumber(map and map.securedPerimeterRing) or 0,
        plots = plots,
        map = map,
    })
end

function Internal.syncColonyBootstrap(player, args)
    local owner = getOwnerUsername(player)
    local knownVersions = type(args and args.knownVersions) == "table" and args.knownVersions or {}
    local forceBuildingsSnapshot = args and args.forceBuildingsSnapshot == true
    local versions = buildVersions(owner)
    local payload = {
        version = versions.building,
        versions = versions,
    }

    if forceBuildingsSnapshot or tonumber(knownVersions.building) ~= tonumber(versions.building) then
        if Buildings.EnsureInitialHeadquartersProject then
            Buildings.EnsureInitialHeadquartersProject(owner)
        end
        payload.buildingsSnapshot = Buildings.BuildOwnerSnapshot and Buildings.BuildOwnerSnapshot(owner, player) or nil
    end
    if tonumber(knownVersions.workerList) ~= tonumber(versions.workerList) then
        payload.workers = Registry.GetWorkerSummariesForOwner and Registry.GetWorkerSummariesForOwner(owner) or {}
    end
    if tonumber(knownVersions.warehouseSummary) ~= tonumber(versions.warehouseSummary) then
        local Warehouse = DC_Colony and DC_Colony.Warehouse or nil
        payload.warehouse = Warehouse and Warehouse.GetClientSummary and Warehouse.GetClientSummary(owner) or nil
    end
    if tonumber(knownVersions.resources) ~= tonumber(versions.resources) then
        payload.resourcesSummary = buildResourcesSummary(owner)
    end
    if tostring(knownVersions.factionStatus or "") ~= tostring(versions.factionStatus) then
        payload.factionStatus = buildFactionStatusSummary(owner)
    end

    Internal.sendTransportPacket(player, "ColonyBootstrap", owner, payload)
end

function Internal.pushOwnerBuildingMutation(ownerUsername, context)
    local owner = getOwnerUsername(ownerUsername)
    if Internal.BuildingMap and Internal.BuildingMap.PushOwnerMutation then
        Internal.BuildingMap.PushOwnerMutation(owner, context or {})
        return
    end
    local sent = Internal.forEachOnlineOwnerPlayer(owner, function(player)
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

    if sent <= 0 and context and context.notice and isDebugTransportEnabled(nil) then
        logTransport("Info", "No online owner client to receive mutation for " .. tostring(owner))
    end
end

function Internal.buildVersionsForOwner(ownerUsername)
    return buildVersions(getOwnerUsername(ownerUsername))
end

return DC_Colony.Network
