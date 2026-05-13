require "DC/Common/Buildings/Core/DC_Buildings"

DC_BuildingsWindowSync = DC_BuildingsWindowSync or {}

local Sync = DC_BuildingsWindowSync

local function getExpectedModule()
    return ((DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony")
end

function Sync.RequestSnapshot(window, windowClass)
    if isClient() and not isServer() then
        local ownerWindow = window and window.getOwnerWindow and window:getOwnerWindow() or nil
        if ownerWindow and ownerWindow.sendColonyCommand then
            ownerWindow:sendColonyCommand("RequestBuildingsSnapshot", {
                knownVersion = windowClass and windowClass.cachedVersion or nil
            })
        end
        if DC_System and DC_System.RequestOwnedFactionStatus then
            DC_System.RequestOwnedFactionStatus()
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

function Sync.InstallEvents(windowClass)
    if not windowClass or windowClass.EventsAdded then
        return
    end

    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= getExpectedModule() then
            return
        end
        if command ~= "SyncBuildingsSnapshot" then
            return
        end
        Sync.HandleSnapshotResponse(windowClass, args)
    end)

    windowClass.EventsAdded = true
end

return Sync