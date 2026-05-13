require "DC/Common/Buildings/Core/DC_Buildings"

DC_BuildingsWindowSync = DC_BuildingsWindowSync or {}

local Sync = DC_BuildingsWindowSync

local function getExpectedModule()
    return ((DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony")
end

local function mergePlotList(windowClass, incomingPlots)
    windowClass.cachedSnapshot = windowClass.cachedSnapshot or { map = { plots = {} } }
    local snapshot = windowClass.cachedSnapshot
    snapshot.map = type(snapshot.map) == "table" and snapshot.map or { plots = {} }
    snapshot.map.plots = type(snapshot.map.plots) == "table" and snapshot.map.plots or {}

    local indexed = {}
    for index, plot in ipairs(snapshot.map.plots) do
        indexed[tostring(plot and plot.key or "")] = index
    end

    for _, incomingPlot in ipairs(incomingPlots or {}) do
        local plotKey = tostring(incomingPlot and incomingPlot.key or "")
        if plotKey ~= "" and indexed[plotKey] then
            snapshot.map.plots[indexed[plotKey]] = incomingPlot
        elseif plotKey ~= "" then
            snapshot.map.plots[#snapshot.map.plots + 1] = incomingPlot
        end
    end
end

local function applyMapMeta(windowClass, map)
    if type(map) ~= "table" then
        return
    end

    windowClass.cachedSnapshot = windowClass.cachedSnapshot or { map = { plots = {} } }
    local snapshot = windowClass.cachedSnapshot
    snapshot.map = type(snapshot.map) == "table" and snapshot.map or { plots = {} }

    for key, value in pairs(map) do
        snapshot.map[key] = value
    end
end

function Sync.RequestSnapshot(window, windowClass)
    if isClient() and not isServer() then
        local ownerWindow = window and window.getOwnerWindow and window:getOwnerWindow() or nil
        if ownerWindow and ownerWindow.sendColonyCommand then
            ownerWindow:sendColonyCommand("RequestColonyBootstrap", {
                knownVersions = {
                    building = windowClass and windowClass.cachedVersion or nil
                }
            })
        end
        return
    end

    if DC_Buildings and DC_Buildings.EnsureInitialHeadquartersProject then
        DC_Buildings.EnsureInitialHeadquartersProject(
            (DC_Colony and DC_Colony.Config and DC_Colony.Config.GetPlayerObject and DC_Colony.Config.GetPlayerObject()) or "local"
        )
    end
    if windowClass then
        windowClass.cachedSnapshot = DC_Buildings and DC_Buildings.BuildOwnerSnapshot
            and DC_Buildings.BuildOwnerSnapshot(
                (DC_Colony and DC_Colony.Config and DC_Colony.Config.GetPlayerObject and DC_Colony.Config.GetPlayerObject()) or "local"
            )
            or nil
    end
    if window and window.refreshFromSnapshot then
        window:refreshFromSnapshot()
    end
end

function Sync.HandleSnapshotResponse(windowClass, args)
    if args and args.unchanged == true then
        return
    end

    if windowClass then
        windowClass.cachedVersion = args and args.version or nil
        windowClass.cachedSnapshot = args and args.snapshot or nil
        if windowClass.instance and windowClass.instance:getIsVisible() then
            windowClass.instance:refreshFromSnapshot()
        end
    end
end

function Sync.HandleBootstrap(windowClass, args)
    if not windowClass or not args then
        return
    end

    if args.versions and args.versions.building then
        windowClass.cachedVersion = args.versions.building
    elseif args.version then
        windowClass.cachedVersion = args.version
    end
    if args.buildingsSnapshot then
        windowClass.cachedSnapshot = args.buildingsSnapshot
    end
    if windowClass.instance and windowClass.instance:getIsVisible() then
        windowClass.instance:refreshFromSnapshot()
    end
end

function Sync.HandleBuildingStateUpdated(windowClass, args)
    if not windowClass or not args then
        return
    end

    if args.version then
        windowClass.cachedVersion = args.version
    end
    if args.plot then
        mergePlotList(windowClass, { args.plot })
    end
    applyMapMeta(windowClass, args.map)
    if windowClass.instance and windowClass.instance:getIsVisible() then
        windowClass.instance:refreshFromSnapshot()
    end
end

function Sync.HandlePlotSafetyChanged(windowClass, args)
    if not windowClass or not args then
        return
    end

    if args.version then
        windowClass.cachedVersion = args.version
    end
    mergePlotList(windowClass, args.plots or {})
    applyMapMeta(windowClass, args.map)
    if windowClass.instance and windowClass.instance:getIsVisible() then
        windowClass.instance:refreshFromSnapshot()
    end
end

function Sync.InstallEvents(windowClass)
    if not windowClass or windowClass.EventsAdded then
        return
    end

    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= getExpectedModule() then
            return
        end
        if command == "SyncBuildingsSnapshot" then
            Sync.HandleSnapshotResponse(windowClass, args)
            return
        end
        if command == "ColonyBootstrap" then
            Sync.HandleBootstrap(windowClass, args)
            return
        end
        if command == "BuildingStateUpdated" then
            Sync.HandleBuildingStateUpdated(windowClass, args)
            return
        end
        if command == "PlotSafetyChanged" then
            Sync.HandlePlotSafetyChanged(windowClass, args)
        end
    end)

    windowClass.EventsAdded = true
end

return Sync
